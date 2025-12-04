//
//  FlockManager.swift
//  BirdGame3
//
//  Clan/Guild system - "Flocks" for player communities
//

import Foundation
import SwiftUI

// MARK: - Flock (Clan/Guild)

struct Flock: Identifiable, Codable {
    let id: String
    var name: String
    var tag: String // 3-4 letter tag shown in-game
    var description: String
    var icon: String
    var bannerColor: String
    let createdAt: Date
    let ownerId: String
    var members: [FlockMember]
    var settings: FlockSettings
    var stats: FlockStats
    
    var memberCount: Int { members.count }
    var isFull: Bool { members.count >= settings.maxMembers }
    
    var level: Int {
        // Level based on total XP
        let xpPerLevel = 10000
        return max(1, (stats.totalXP / xpPerLevel) + 1)
    }
}

// MARK: - Flock Member

struct FlockMember: Identifiable, Codable {
    let id: String
    var displayName: String
    var role: FlockRole
    let joinedAt: Date
    var contributedXP: Int
    var weeklyContribution: Int
    var lastActive: Date
    
    var isOnline: Bool {
        Date().timeIntervalSince(lastActive) < 300 // Online if active in last 5 min
    }
}

// MARK: - Flock Role

enum FlockRole: String, Codable, CaseIterable {
    case owner
    case elder
    case member
    case recruit
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var permissions: Set<FlockPermission> {
        switch self {
        case .owner:
            return Set(FlockPermission.allCases)
        case .elder:
            return [.invite, .kick, .startWar, .editDescription, .manageChat]
        case .member:
            return [.invite, .chat, .participate]
        case .recruit:
            return [.chat, .participate]
        }
    }
    
    var icon: String {
        switch self {
        case .owner: return "👑"
        case .elder: return "⭐"
        case .member: return "🐦"
        case .recruit: return "🥚"
        }
    }
}

// MARK: - Flock Permission

enum FlockPermission: String, Codable, CaseIterable {
    case invite
    case kick
    case promote
    case demote
    case startWar
    case editDescription
    case editSettings
    case manageChat
    case chat
    case participate
    case disband
}

// MARK: - Flock Settings

struct FlockSettings: Codable {
    var maxMembers: Int
    var joinType: FlockJoinType
    var minLevelToJoin: Int
    var isWarEnabled: Bool
    var chatEnabled: Bool
}

// MARK: - Flock Join Type

enum FlockJoinType: String, Codable, CaseIterable {
    case open // Anyone can join
    case invite // Invite only
    case request // Request to join, needs approval
    
    var displayName: String {
        switch self {
        case .open: return "Open"
        case .invite: return "Invite Only"
        case .request: return "Request to Join"
        }
    }
    
    var icon: String {
        switch self {
        case .open: return "🔓"
        case .invite: return "🔐"
        case .request: return "📝"
        }
    }
}

// MARK: - Flock Stats

struct FlockStats: Codable {
    var totalXP: Int
    var totalWins: Int
    var totalBattles: Int
    var warsWon: Int
    var warsLost: Int
    var weeklyXP: Int
    var lastWarResult: String?
}

// MARK: - Flock Invite

struct FlockInvite: Identifiable, Codable {
    let id: String
    let flockId: String
    let flockName: String
    let inviterId: String
    let inviterName: String
    let timestamp: Date
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 24 * 60 * 60 // 24 hour expiry
    }
}

// MARK: - Join Request

struct FlockJoinRequest: Identifiable, Codable {
    let id: String
    let playerId: String
    let playerName: String
    let playerLevel: Int
    let message: String?
    let timestamp: Date
}

// MARK: - Flock Manager

class FlockManager: ObservableObject {
    static let shared = FlockManager()
    
    // MARK: - Published Properties
    
    @Published var currentFlock: Flock?
    @Published var pendingInvites: [FlockInvite] = []
    @Published var joinRequests: [FlockJoinRequest] = []
    @Published var searchResults: [Flock] = []
    @Published var flockChat: [FlockChatMessage] = []
    
    // MARK: - Private Properties
    
    private let saveKey = "birdgame3_flock"
    private let invitesSaveKey = "birdgame3_flockInvites"
    
    // MARK: - Initialization
    
    private init() {
        loadFlock()
        loadInvites()
    }
    
    // MARK: - Flock Creation
    
    func createFlock(name: String, tag: String, description: String, icon: String) -> Flock? {
        guard currentFlock == nil else { return nil }
        guard name.count >= 3 && name.count <= 20 else { return nil }
        guard tag.count >= 2 && tag.count <= 4 else { return nil }
        
        let playerId = MultiplayerManager.shared.localPlayerId
        let playerName = MultiplayerManager.shared.localPlayerName
        
        let owner = FlockMember(
            id: playerId,
            displayName: playerName,
            role: .owner,
            joinedAt: Date(),
            contributedXP: 0,
            weeklyContribution: 0,
            lastActive: Date()
        )
        
        let flock = Flock(
            id: UUID().uuidString,
            name: name,
            tag: tag.uppercased(),
            description: description,
            icon: icon,
            bannerColor: "blue",
            createdAt: Date(),
            ownerId: playerId,
            members: [owner],
            settings: FlockSettings(
                maxMembers: 50,
                joinType: .request,
                minLevelToJoin: 5,
                isWarEnabled: true,
                chatEnabled: true
            ),
            stats: FlockStats(
                totalXP: 0,
                totalWins: 0,
                totalBattles: 0,
                warsWon: 0,
                warsLost: 0,
                weeklyXP: 0,
                lastWarResult: nil
            )
        )
        
        currentFlock = flock
        saveFlock()
        
        return flock
    }
    
    // MARK: - Joining/Leaving
    
    func joinFlock(_ flock: Flock) -> Bool {
        guard currentFlock == nil else { return false }
        guard !flock.isFull else { return false }
        
        let playerId = MultiplayerManager.shared.localPlayerId
        let playerName = MultiplayerManager.shared.localPlayerName
        
        var joinedFlock = flock
        let newMember = FlockMember(
            id: playerId,
            displayName: playerName,
            role: .recruit,
            joinedAt: Date(),
            contributedXP: 0,
            weeklyContribution: 0,
            lastActive: Date()
        )
        
        joinedFlock.members.append(newMember)
        currentFlock = joinedFlock
        saveFlock()
        
        return true
    }
    
    func leaveFlock() {
        guard currentFlock != nil else { return }
        
        let playerId = MultiplayerManager.shared.localPlayerId
        
        // Check if owner - must transfer or disband
        if currentFlock?.ownerId == playerId {
            // Auto-transfer to first elder, or disband
            if let elder = currentFlock?.members.first(where: { $0.role == .elder && $0.id != playerId }) {
                promoteMember(elder.id, to: .owner)
            }
            // If no elders, flock is disbanded
        }
        
        currentFlock = nil
        saveFlock()
    }
    
    // MARK: - Member Management
    
    func invitePlayer(playerId: String, playerName: String) {
        guard let flock = currentFlock else { return }
        guard hasPermission(.invite) else { return }
        
        // Create invite (would normally be sent via network)
        let invite = FlockInvite(
            id: UUID().uuidString,
            flockId: flock.id,
            flockName: flock.name,
            inviterId: MultiplayerManager.shared.localPlayerId,
            inviterName: MultiplayerManager.shared.localPlayerName,
            timestamp: Date()
        )
        
        // In a real app, this would be sent to the target player
        print("Invite sent to \(playerName): \(invite)")
    }
    
    func acceptInvite(_ invite: FlockInvite) -> Bool {
        guard currentFlock == nil else { return false }
        guard !invite.isExpired else { return false }
        
        // In a real app, would fetch flock from server
        // For now, create a simulated join
        pendingInvites.removeAll { $0.id == invite.id }
        saveInvites()
        
        return true
    }
    
    func declineInvite(_ invite: FlockInvite) {
        pendingInvites.removeAll { $0.id == invite.id }
        saveInvites()
    }
    
    func kickMember(_ memberId: String) {
        guard var flock = currentFlock else { return }
        guard hasPermission(.kick) else { return }
        guard memberId != flock.ownerId else { return } // Can't kick owner
        
        flock.members.removeAll { $0.id == memberId }
        currentFlock = flock
        saveFlock()
    }
    
    func promoteMember(_ memberId: String, to role: FlockRole) {
        guard var flock = currentFlock else { return }
        guard hasPermission(.promote) else { return }
        guard let index = flock.members.firstIndex(where: { $0.id == memberId }) else { return }
        
        flock.members[index].role = role
        
        // If promoting to owner, demote current owner
        if role == .owner {
            if let ownerIndex = flock.members.firstIndex(where: { $0.id == flock.ownerId }) {
                flock.members[ownerIndex].role = .elder
            }
            // Update owner ID would happen server-side
        }
        
        currentFlock = flock
        saveFlock()
    }
    
    // MARK: - Permissions
    
    func hasPermission(_ permission: FlockPermission) -> Bool {
        guard let flock = currentFlock else { return false }
        let playerId = MultiplayerManager.shared.localPlayerId
        guard let member = flock.members.first(where: { $0.id == playerId }) else { return false }
        return member.role.permissions.contains(permission)
    }
    
    var myRole: FlockRole? {
        guard let flock = currentFlock else { return nil }
        let playerId = MultiplayerManager.shared.localPlayerId
        return flock.members.first { $0.id == playerId }?.role
    }
    
    // MARK: - XP Contribution
    
    func contributeXP(_ amount: Int) {
        guard var flock = currentFlock else { return }
        let playerId = MultiplayerManager.shared.localPlayerId
        
        flock.stats.totalXP += amount
        flock.stats.weeklyXP += amount
        
        if let index = flock.members.firstIndex(where: { $0.id == playerId }) {
            flock.members[index].contributedXP += amount
            flock.members[index].weeklyContribution += amount
            flock.members[index].lastActive = Date()
        }
        
        currentFlock = flock
        saveFlock()
    }
    
    func recordBattle(won: Bool) {
        guard var flock = currentFlock else { return }
        
        flock.stats.totalBattles += 1
        if won {
            flock.stats.totalWins += 1
        }
        
        currentFlock = flock
        saveFlock()
    }
    
    // MARK: - Search
    
    func searchFlocks(query: String) {
        // In a real app, this would query a server
        // For demo, generate some fake results
        searchResults = generateFakeFlocks(matching: query)
    }
    
    private func generateFakeFlocks(matching query: String) -> [Flock] {
        let names = ["Sky Warriors", "Feathered Fury", "Nest Destroyers", "Wing Legends", "Beak Squad"]
        
        return names.filter { $0.lowercased().contains(query.lowercased()) || query.isEmpty }
            .prefix(10)
            .map { name in
                Flock(
                    id: UUID().uuidString,
                    name: name,
                    tag: String(name.prefix(3)).uppercased(),
                    description: "A flock of fierce birds",
                    icon: "🦅",
                    bannerColor: "blue",
                    createdAt: Date().addingTimeInterval(-Double.random(in: 0...30*24*60*60)),
                    ownerId: UUID().uuidString,
                    members: [],
                    settings: FlockSettings(maxMembers: 50, joinType: .request, minLevelToJoin: 5, isWarEnabled: true, chatEnabled: true),
                    stats: FlockStats(totalXP: Int.random(in: 1000...100000), totalWins: Int.random(in: 10...500), totalBattles: Int.random(in: 20...1000), warsWon: Int.random(in: 0...10), warsLost: Int.random(in: 0...5), weeklyXP: Int.random(in: 100...5000), lastWarResult: nil)
                )
            }
    }
    
    // MARK: - Persistence
    
    private func saveFlock() {
        if let flock = currentFlock,
           let data = try? JSONEncoder().encode(flock) {
            UserDefaults.standard.set(data, forKey: saveKey)
        } else {
            UserDefaults.standard.removeObject(forKey: saveKey)
        }
    }
    
    private func loadFlock() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let flock = try? JSONDecoder().decode(Flock.self, from: data) {
            currentFlock = flock
        }
    }
    
    private func saveInvites() {
        if let data = try? JSONEncoder().encode(pendingInvites) {
            UserDefaults.standard.set(data, forKey: invitesSaveKey)
        }
    }
    
    private func loadInvites() {
        if let data = UserDefaults.standard.data(forKey: invitesSaveKey),
           let invites = try? JSONDecoder().decode([FlockInvite].self, from: data) {
            pendingInvites = invites.filter { !$0.isExpired }
        }
    }
}

// MARK: - Flock Chat Message

struct FlockChatMessage: Identifiable, Codable {
    let id: String
    let senderId: String
    let senderName: String
    let senderRole: FlockRole
    let message: String
    let timestamp: Date
    let type: FlockChatMessageType
}

enum FlockChatMessageType: String, Codable {
    case text
    case system
    case join
    case leave
    case promotion
}
