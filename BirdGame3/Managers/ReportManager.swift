//
//  ReportManager.swift
//  BirdGame3
//
//  Player report and block system
//

import Foundation
import SwiftUI

// MARK: - Report Reason

enum ReportReason: String, CaseIterable, Codable {
    case harassment = "Harassment"
    case cheating = "Cheating/Hacking"
    case inappropriateName = "Inappropriate Name"
    case inappropriateChat = "Inappropriate Chat"
    case afk = "AFK/Idle"
    case griefing = "Griefing/Throwing"
    case spam = "Spam"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .harassment: return "🚫"
        case .cheating: return "🎮"
        case .inappropriateName: return "📝"
        case .inappropriateChat: return "💬"
        case .afk: return "😴"
        case .griefing: return "💀"
        case .spam: return "📨"
        case .other: return "❓"
        }
    }
    
    var description: String {
        switch self {
        case .harassment: return "Player is harassing, bullying, or threatening others"
        case .cheating: return "Player is using hacks, exploits, or unfair advantages"
        case .inappropriateName: return "Player has an offensive username or display name"
        case .inappropriateChat: return "Player is using offensive language or content in chat"
        case .afk: return "Player is intentionally idle or not participating"
        case .griefing: return "Player is intentionally losing or ruining the game"
        case .spam: return "Player is spamming messages or emotes"
        case .other: return "Other reason not listed above"
        }
    }
}

// MARK: - Player Report

struct PlayerReport: Identifiable, Codable {
    let id: String
    let reporterId: String
    let reporterName: String
    let targetId: String
    let targetName: String
    let reason: ReportReason
    let details: String?
    let matchId: String?
    let timestamp: Date
    var status: ReportStatus
}

// MARK: - Report Status

enum ReportStatus: String, Codable {
    case pending
    case reviewed
    case actionTaken
    case dismissed
}

// MARK: - Block Entry

struct BlockEntry: Identifiable, Codable {
    let id: String
    let blockedUserId: String
    let blockedUserName: String
    let blockedAt: Date
    let reason: String?
}

// MARK: - Report Manager

class ReportManager: ObservableObject {
    static let shared = ReportManager()
    
    // MARK: - Published Properties
    
    @Published var blockedPlayers: [BlockEntry] = []
    @Published var recentReports: [PlayerReport] = []
    @Published var reportCooldown: Date?
    
    // MARK: - Private Properties
    
    private let blockedSaveKey = "birdgame3_blockedPlayers"
    private let reportsSaveKey = "birdgame3_reports"
    private let cooldownSaveKey = "birdgame3_reportCooldown"
    private let reportCooldownDuration: TimeInterval = 60 // 1 minute between reports
    private let maxReportsPerDay = 10
    
    // MARK: - Initialization
    
    private init() {
        loadBlockedPlayers()
        loadReports()
        loadCooldown()
    }
    
    // MARK: - Reporting
    
    func reportPlayer(
        targetId: String,
        targetName: String,
        reason: ReportReason,
        details: String? = nil,
        matchId: String? = nil
    ) -> (success: Bool, message: String) {
        // Check cooldown
        if let cooldown = reportCooldown, Date() < cooldown {
            let remaining = Int(cooldown.timeIntervalSince(Date()))
            return (false, "Please wait \(remaining) seconds before submitting another report")
        }
        
        // Check daily limit
        let todaysReports = recentReports.filter {
            Calendar.current.isDateInToday($0.timestamp)
        }
        if todaysReports.count >= maxReportsPerDay {
            return (false, "You've reached the daily report limit. Try again tomorrow.")
        }
        
        // Check if already reported this player today
        if todaysReports.contains(where: { $0.targetId == targetId }) {
            return (false, "You've already reported this player today")
        }
        
        // Can't report yourself
        let myId = MultiplayerManager.shared.localPlayerId
        if targetId == myId {
            return (false, "You can't report yourself")
        }
        
        // Create report
        let report = PlayerReport(
            id: UUID().uuidString,
            reporterId: myId,
            reporterName: MultiplayerManager.shared.localPlayerName,
            targetId: targetId,
            targetName: targetName,
            reason: reason,
            details: details,
            matchId: matchId,
            timestamp: Date(),
            status: .pending
        )
        
        recentReports.append(report)
        
        // Set cooldown
        reportCooldown = Date().addingTimeInterval(reportCooldownDuration)
        
        saveReports()
        saveCooldown()
        
        // In a real app, this would be sent to a server
        print("Report submitted: \(report)")
        
        return (true, "Report submitted successfully. Thank you for helping keep Bird Game 3 safe!")
    }
    
    var canReport: Bool {
        if let cooldown = reportCooldown, Date() < cooldown {
            return false
        }
        
        let todaysReports = recentReports.filter {
            Calendar.current.isDateInToday($0.timestamp)
        }
        
        return todaysReports.count < maxReportsPerDay
    }
    
    var cooldownRemaining: Int {
        guard let cooldown = reportCooldown else { return 0 }
        return max(0, Int(cooldown.timeIntervalSince(Date())))
    }
    
    // MARK: - Blocking
    
    func blockPlayer(userId: String, userName: String, reason: String? = nil) -> Bool {
        // Can't block yourself
        if userId == MultiplayerManager.shared.localPlayerId {
            return false
        }
        
        // Check if already blocked
        if isBlocked(userId) {
            return false
        }
        
        let entry = BlockEntry(
            id: UUID().uuidString,
            blockedUserId: userId,
            blockedUserName: userName,
            blockedAt: Date(),
            reason: reason
        )
        
        blockedPlayers.append(entry)
        
        // Also block in chat
        ChatManager.shared.blockUser(userId)
        
        saveBlockedPlayers()
        
        return true
    }
    
    func unblockPlayer(userId: String) {
        blockedPlayers.removeAll { $0.blockedUserId == userId }
        ChatManager.shared.unblockUser(userId)
        saveBlockedPlayers()
    }
    
    func isBlocked(_ userId: String) -> Bool {
        blockedPlayers.contains { $0.blockedUserId == userId }
    }
    
    // MARK: - Persistence
    
    private func saveBlockedPlayers() {
        if let data = try? JSONEncoder().encode(blockedPlayers) {
            UserDefaults.standard.set(data, forKey: blockedSaveKey)
        }
    }
    
    private func loadBlockedPlayers() {
        if let data = UserDefaults.standard.data(forKey: blockedSaveKey),
           let saved = try? JSONDecoder().decode([BlockEntry].self, from: data) {
            blockedPlayers = saved
        }
    }
    
    private func saveReports() {
        // Only keep last 7 days of reports
        let weekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let recentOnly = recentReports.filter { $0.timestamp > weekAgo }
        
        if let data = try? JSONEncoder().encode(recentOnly) {
            UserDefaults.standard.set(data, forKey: reportsSaveKey)
        }
    }
    
    private func loadReports() {
        if let data = UserDefaults.standard.data(forKey: reportsSaveKey),
           let saved = try? JSONDecoder().decode([PlayerReport].self, from: data) {
            recentReports = saved
        }
    }
    
    private func saveCooldown() {
        UserDefaults.standard.set(reportCooldown, forKey: cooldownSaveKey)
    }
    
    private func loadCooldown() {
        reportCooldown = UserDefaults.standard.object(forKey: cooldownSaveKey) as? Date
        
        // Clear if expired
        if let cooldown = reportCooldown, Date() > cooldown {
            reportCooldown = nil
        }
    }
}
