//
//  ChatManager.swift
//  BirdGame3
//
//  Text chat and messaging system
//

import Foundation
import SwiftUI

// MARK: - Chat Message

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: String
    let senderId: String
    let senderName: String
    let content: String
    let timestamp: Date
    let type: ChatMessageType
    var isRead: Bool
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Chat Message Type

enum ChatMessageType: String, Codable {
    case text
    case emote
    case system
    case quickChat
}

// MARK: - Chat Channel

struct ChatChannel: Identifiable, Codable {
    let id: String
    let type: ChatChannelType
    var name: String
    var participants: [String]
    var messages: [ChatMessage]
    var lastActivity: Date
    var unreadCount: Int
    var isMuted: Bool
}

// MARK: - Chat Channel Type

enum ChatChannelType: String, Codable {
    case global
    case party
    case flock
    case direct
    case match
}

// MARK: - Quick Chat Options

enum QuickChatOption: String, CaseIterable {
    case hello = "Hello!"
    case goodGame = "Good game!"
    case thanks = "Thanks!"
    case sorry = "Sorry!"
    case nice = "Nice!"
    case help = "Help me!"
    case attack = "Attack!"
    case defend = "Defend!"
    case retreat = "Retreat!"
    case onMyWay = "On my way!"
    case wait = "Wait!"
    case gogogo = "Go go go!"
    
    var icon: String {
        switch self {
        case .hello: return "👋"
        case .goodGame: return "🤝"
        case .thanks: return "🙏"
        case .sorry: return "😅"
        case .nice: return "👍"
        case .help: return "🆘"
        case .attack: return "⚔️"
        case .defend: return "🛡️"
        case .retreat: return "🏃"
        case .onMyWay: return "🏃‍♂️"
        case .wait: return "✋"
        case .gogogo: return "🚀"
        }
    }
    
    var category: QuickChatCategory {
        switch self {
        case .hello, .goodGame, .thanks, .sorry, .nice:
            return .social
        case .help, .attack, .defend, .retreat, .onMyWay, .wait, .gogogo:
            return .tactical
        }
    }
}

enum QuickChatCategory: String, CaseIterable {
    case social
    case tactical
    
    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Chat Manager

class ChatManager: ObservableObject {
    static let shared = ChatManager()
    
    // MARK: - Published Properties
    
    @Published var channels: [ChatChannel] = []
    @Published var activeChannel: ChatChannel?
    @Published var blockedUsers: Set<String> = []
    @Published var isChatEnabled: Bool = true
    @Published var profanityFilterEnabled: Bool = true
    
    // MARK: - Private Properties
    
    private let saveKey = "birdgame3_chat"
    private let blockedSaveKey = "birdgame3_blockedUsers"
    private let maxMessagesPerChannel = 100
    
    // Bad words filter (simplified)
    private let profanityList = ["badword1", "badword2"] // Would be more comprehensive in production
    
    // MARK: - Initialization
    
    private init() {
        loadChannels()
        loadBlockedUsers()
        initializeDefaultChannels()
    }
    
    private func initializeDefaultChannels() {
        // Global channel always exists
        if !channels.contains(where: { $0.type == .global }) {
            let global = ChatChannel(
                id: "global",
                type: .global,
                name: "Global Chat",
                participants: [],
                messages: [],
                lastActivity: Date(),
                unreadCount: 0,
                isMuted: false
            )
            channels.append(global)
            saveChannels()
        }
    }
    
    // MARK: - Channel Management
    
    func createDirectChannel(with userId: String, userName: String) -> ChatChannel {
        // Check if channel already exists
        if let existing = channels.first(where: {
            $0.type == .direct && $0.participants.contains(userId)
        }) {
            return existing
        }
        
        let channel = ChatChannel(
            id: UUID().uuidString,
            type: .direct,
            name: userName,
            participants: [MultiplayerManager.shared.localPlayerId, userId],
            messages: [],
            lastActivity: Date(),
            unreadCount: 0,
            isMuted: false
        )
        
        channels.append(channel)
        saveChannels()
        
        return channel
    }
    
    func getOrCreatePartyChannel() -> ChatChannel {
        if let existing = channels.first(where: { $0.type == .party }) {
            return existing
        }
        
        let channel = ChatChannel(
            id: "party_\(UUID().uuidString)",
            type: .party,
            name: "Party Chat",
            participants: [],
            messages: [],
            lastActivity: Date(),
            unreadCount: 0,
            isMuted: false
        )
        
        channels.append(channel)
        saveChannels()
        
        return channel
    }
    
    func getOrCreateFlockChannel() -> ChatChannel? {
        guard FlockManager.shared.currentFlock != nil else { return nil }
        
        if let existing = channels.first(where: { $0.type == .flock }) {
            return existing
        }
        
        let channel = ChatChannel(
            id: "flock_\(UUID().uuidString)",
            type: .flock,
            name: "Flock Chat",
            participants: [],
            messages: [],
            lastActivity: Date(),
            unreadCount: 0,
            isMuted: false
        )
        
        channels.append(channel)
        saveChannels()
        
        return channel
    }
    
    func setActiveChannel(_ channel: ChatChannel) {
        activeChannel = channel
        markChannelAsRead(channel.id)
    }
    
    func closeChannel(_ channelId: String) {
        // Only close direct message channels
        guard let channel = channels.first(where: { $0.id == channelId }),
              channel.type == .direct else { return }
        
        channels.removeAll { $0.id == channelId }
        
        if activeChannel?.id == channelId {
            activeChannel = nil
        }
        
        saveChannels()
    }
    
    func muteChannel(_ channelId: String, muted: Bool) {
        guard let index = channels.firstIndex(where: { $0.id == channelId }) else { return }
        channels[index].isMuted = muted
        saveChannels()
    }
    
    // MARK: - Messaging
    
    func sendMessage(_ content: String, to channelId: String, type: ChatMessageType = .text) {
        guard isChatEnabled else { return }
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let index = channels.firstIndex(where: { $0.id == channelId }) else { return }
        
        let filteredContent = profanityFilterEnabled ? filterProfanity(content) : content
        
        let message = ChatMessage(
            id: UUID().uuidString,
            senderId: MultiplayerManager.shared.localPlayerId,
            senderName: MultiplayerManager.shared.localPlayerName,
            content: filteredContent,
            timestamp: Date(),
            type: type,
            isRead: true
        )
        
        channels[index].messages.append(message)
        channels[index].lastActivity = Date()
        
        // Trim old messages if needed
        if channels[index].messages.count > maxMessagesPerChannel {
            channels[index].messages.removeFirst(channels[index].messages.count - maxMessagesPerChannel)
        }
        
        saveChannels()
        
        // Broadcast to other players (would be network call in real app)
        NotificationCenter.default.post(
            name: .chatMessageSent,
            object: nil,
            userInfo: ["message": message, "channelId": channelId]
        )
    }
    
    func sendQuickChat(_ option: QuickChatOption, to channelId: String) {
        sendMessage("\(option.icon) \(option.rawValue)", to: channelId, type: .quickChat)
    }
    
    func receiveMessage(_ message: ChatMessage, in channelId: String) {
        guard !blockedUsers.contains(message.senderId) else { return }
        guard let index = channels.firstIndex(where: { $0.id == channelId }) else { return }
        
        var newMessage = message
        newMessage.isRead = activeChannel?.id == channelId
        
        channels[index].messages.append(newMessage)
        channels[index].lastActivity = Date()
        
        if !newMessage.isRead && !channels[index].isMuted {
            channels[index].unreadCount += 1
        }
        
        // Trim old messages
        if channels[index].messages.count > maxMessagesPerChannel {
            channels[index].messages.removeFirst(channels[index].messages.count - maxMessagesPerChannel)
        }
        
        saveChannels()
        
        // Notification
        if !channels[index].isMuted {
            NotificationCenter.default.post(
                name: .chatMessageReceived,
                object: nil,
                userInfo: ["message": newMessage, "channelId": channelId]
            )
        }
    }
    
    private func filterProfanity(_ text: String) -> String {
        var filtered = text
        for word in profanityList {
            let replacement = String(repeating: "*", count: word.count)
            filtered = filtered.replacingOccurrences(
                of: word,
                with: replacement,
                options: .caseInsensitive
            )
        }
        return filtered
    }
    
    func markChannelAsRead(_ channelId: String) {
        guard let index = channels.firstIndex(where: { $0.id == channelId }) else { return }
        
        for i in channels[index].messages.indices {
            channels[index].messages[i].isRead = true
        }
        channels[index].unreadCount = 0
        
        saveChannels()
    }
    
    // MARK: - User Blocking
    
    func blockUser(_ userId: String) {
        blockedUsers.insert(userId)
        saveBlockedUsers()
    }
    
    func unblockUser(_ userId: String) {
        blockedUsers.remove(userId)
        saveBlockedUsers()
    }
    
    func isBlocked(_ userId: String) -> Bool {
        blockedUsers.contains(userId)
    }
    
    // MARK: - Stats
    
    var totalUnreadCount: Int {
        channels.filter { !$0.isMuted }.reduce(0) { $0 + $1.unreadCount }
    }
    
    func messages(for channelId: String) -> [ChatMessage] {
        channels.first { $0.id == channelId }?.messages ?? []
    }
    
    // MARK: - Persistence
    
    private func saveChannels() {
        if let data = try? JSONEncoder().encode(channels) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
    
    private func loadChannels() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let saved = try? JSONDecoder().decode([ChatChannel].self, from: data) {
            channels = saved
        }
    }
    
    private func saveBlockedUsers() {
        UserDefaults.standard.set(Array(blockedUsers), forKey: blockedSaveKey)
    }
    
    private func loadBlockedUsers() {
        if let array = UserDefaults.standard.array(forKey: blockedSaveKey) as? [String] {
            blockedUsers = Set(array)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let chatMessageSent = Notification.Name("birdgame3_chatMessageSent")
    static let chatMessageReceived = Notification.Name("birdgame3_chatMessageReceived")
}
