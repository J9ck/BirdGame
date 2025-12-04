//
//  ChallengeManager.swift
//  BirdGame3
//
//  Daily and weekly challenges system
//

import Foundation
import SwiftUI

// MARK: - Challenge

struct Challenge: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let type: ChallengeType
    let requirement: Int
    var progress: Int
    let rewardCoins: Int
    let rewardXP: Int
    let rewardFeathers: Int
    var isCompleted: Bool
    var isClaimed: Bool
    let expiresAt: Date
    
    var progressPercent: Double {
        guard requirement > 0 else { return isCompleted ? 1.0 : 0.0 }
        return min(Double(progress) / Double(requirement), 1.0)
    }
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    var timeRemaining: String {
        let interval = expiresAt.timeIntervalSince(Date())
        guard interval > 0 else { return "Expired" }
        
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours >= 24 {
            let days = hours / 24
            return "\(days)d \(hours % 24)h"
        }
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Challenge Type

enum ChallengeType: String, Codable, CaseIterable {
    case daily
    case weekly
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        }
    }
    
    var duration: TimeInterval {
        switch self {
        case .daily: return 24 * 60 * 60 // 24 hours
        case .weekly: return 7 * 24 * 60 * 60 // 7 days
        }
    }
}

// MARK: - Challenge Template

enum ChallengeTemplate: CaseIterable {
    case winBattles
    case dealDamage
    case playMatches
    case useAbilities
    case gatherResources
    case buildNestComponents
    case playWithFriends
    case winWithBird
    case loginDaily
    case joinParty
    
    func generate(type: ChallengeType) -> Challenge {
        let multiplier = type == .weekly ? 5 : 1
        let rewardMultiplier = type == .weekly ? 3 : 1
        
        let expiry = Date().addingTimeInterval(type.duration)
        
        switch self {
        case .winBattles:
            let count = (type == .weekly ? 15 : 3) * multiplier / multiplier
            return Challenge(
                id: UUID().uuidString,
                title: "Win \(count) Battles",
                description: "Emerge victorious in \(count) battles",
                icon: "🏆",
                type: type,
                requirement: count,
                progress: 0,
                rewardCoins: 100 * rewardMultiplier,
                rewardXP: 50 * rewardMultiplier,
                rewardFeathers: type == .weekly ? 10 : 0,
                isCompleted: false,
                isClaimed: false,
                expiresAt: expiry
            )
            
        case .dealDamage:
            let damage = (type == .weekly ? 5000 : 1000)
            return Challenge(
                id: UUID().uuidString,
                title: "Deal \(damage) Damage",
                description: "Inflict \(damage) total damage to opponents",
                icon: "💥",
                type: type,
                requirement: damage,
                progress: 0,
                rewardCoins: 150 * rewardMultiplier,
                rewardXP: 75 * rewardMultiplier,
                rewardFeathers: type == .weekly ? 15 : 0,
                isCompleted: false,
                isClaimed: false,
                expiresAt: expiry
            )
            
        case .playMatches:
            let count = type == .weekly ? 20 : 5
            return Challenge(
                id: UUID().uuidString,
                title: "Play \(count) Matches",
                description: "Participate in \(count) battles",
                icon: "⚔️",
                type: type,
                requirement: count,
                progress: 0,
                rewardCoins: 80 * rewardMultiplier,
                rewardXP: 40 * rewardMultiplier,
                rewardFeathers: type == .weekly ? 5 : 0,
                isCompleted: false,
                isClaimed: false,
                expiresAt: expiry
            )
            
        case .useAbilities:
            let count = type == .weekly ? 50 : 10
            return Challenge(
                id: UUID().uuidString,
                title: "Use \(count) Abilities",
                description: "Activate special abilities \(count) times",
                icon: "✨",
                type: type,
                requirement: count,
                progress: 0,
                rewardCoins: 120 * rewardMultiplier,
                rewardXP: 60 * rewardMultiplier,
                rewardFeathers: type == .weekly ? 8 : 0,
                isCompleted: false,
                isClaimed: false,
                expiresAt: expiry
            )
            
        case .gatherResources:
            let count = type == .weekly ? 200 : 50
            return Challenge(
                id: UUID().uuidString,
                title: "Gather \(count) Resources",
                description: "Collect resources in the open world",
                icon: "🌿",
                type: type,
                requirement: count,
                progress: 0,
                rewardCoins: 100 * rewardMultiplier,
                rewardXP: 50 * rewardMultiplier,
                rewardFeathers: type == .weekly ? 10 : 0,
                isCompleted: false,
                isClaimed: false,
                expiresAt: expiry
            )
            
        case .buildNestComponents:
            let count = type == .weekly ? 10 : 2
            return Challenge(
                id: UUID().uuidString,
                title: "Build \(count) Nest Parts",
                description: "Construct \(count) components for your nest",
                icon: "🪺",
                type: type,
                requirement: count,
                progress: 0,
                rewardCoins: 200 * rewardMultiplier,
                rewardXP: 100 * rewardMultiplier,
                rewardFeathers: type == .weekly ? 20 : 0,
                isCompleted: false,
                isClaimed: false,
                expiresAt: expiry
            )
            
        case .playWithFriends:
            let count = type == .weekly ? 5 : 1
            return Challenge(
                id: UUID().uuidString,
                title: "Play \(count) Match\(count > 1 ? "es" : "") with Friends",
                description: "Battle alongside your squad",
                icon: "👥",
                type: type,
                requirement: count,
                progress: 0,
                rewardCoins: 150 * rewardMultiplier,
                rewardXP: 75 * rewardMultiplier,
                rewardFeathers: type == .weekly ? 15 : 0,
                isCompleted: false,
                isClaimed: false,
                expiresAt: expiry
            )
            
        case .winWithBird:
            let birds = BirdType.allCases
            let bird = birds.randomElement() ?? .pigeon
            let count = type == .weekly ? 5 : 1
            return Challenge(
                id: UUID().uuidString,
                title: "Win \(count) as \(bird.displayName)",
                description: "Achieve victory using \(bird.displayName)",
                icon: bird.emoji,
                type: type,
                requirement: count,
                progress: 0,
                rewardCoins: 120 * rewardMultiplier,
                rewardXP: 60 * rewardMultiplier,
                rewardFeathers: type == .weekly ? 12 : 0,
                isCompleted: false,
                isClaimed: false,
                expiresAt: expiry
            )
            
        case .loginDaily:
            return Challenge(
                id: UUID().uuidString,
                title: "Daily Login",
                description: "Log in to claim your reward",
                icon: "📅",
                type: .daily,
                requirement: 1,
                progress: 1, // Auto-complete on login
                rewardCoins: 50,
                rewardXP: 25,
                rewardFeathers: 0,
                isCompleted: true,
                isClaimed: false,
                expiresAt: expiry
            )
            
        case .joinParty:
            return Challenge(
                id: UUID().uuidString,
                title: "Join a Party",
                description: "Play in a party with other players",
                icon: "🎉",
                type: type,
                requirement: 1,
                progress: 0,
                rewardCoins: 75 * rewardMultiplier,
                rewardXP: 35 * rewardMultiplier,
                rewardFeathers: type == .weekly ? 5 : 0,
                isCompleted: false,
                isClaimed: false,
                expiresAt: expiry
            )
        }
    }
}

// MARK: - Challenge Manager

class ChallengeManager: ObservableObject {
    static let shared = ChallengeManager()
    
    // MARK: - Published Properties
    
    @Published var dailyChallenges: [Challenge] = []
    @Published var weeklyChallenges: [Challenge] = []
    @Published var lastDailyRefresh: Date?
    @Published var lastWeeklyRefresh: Date?
    
    // MARK: - Private Properties
    
    private let dailySaveKey = "birdgame3_dailyChallenges"
    private let weeklySaveKey = "birdgame3_weeklyChallenges"
    private let dailyRefreshKey = "birdgame3_lastDailyRefresh"
    private let weeklyRefreshKey = "birdgame3_lastWeeklyRefresh"
    
    // MARK: - Initialization
    
    private init() {
        loadChallenges()
        checkAndRefreshChallenges()
    }
    
    // MARK: - Challenge Refresh
    
    func checkAndRefreshChallenges() {
        let now = Date()
        let calendar = Calendar.current
        
        // Check daily refresh (resets at midnight)
        if let lastDaily = lastDailyRefresh {
            if !calendar.isDate(lastDaily, inSameDayAs: now) {
                generateDailyChallenges()
            }
        } else {
            generateDailyChallenges()
        }
        
        // Check weekly refresh (resets on Monday)
        if let lastWeekly = lastWeeklyRefresh {
            let weekOfLastRefresh = calendar.component(.weekOfYear, from: lastWeekly)
            let currentWeek = calendar.component(.weekOfYear, from: now)
            if weekOfLastRefresh != currentWeek {
                generateWeeklyChallenges()
            }
        } else {
            generateWeeklyChallenges()
        }
        
        // Remove expired challenges
        dailyChallenges.removeAll { $0.isExpired }
        weeklyChallenges.removeAll { $0.isExpired }
    }
    
    private func generateDailyChallenges() {
        let templates: [ChallengeTemplate] = [.loginDaily, .winBattles, .playMatches, .useAbilities]
        dailyChallenges = templates.prefix(3).map { $0.generate(type: .daily) }
        lastDailyRefresh = Date()
        saveChallenges()
    }
    
    private func generateWeeklyChallenges() {
        let templates: [ChallengeTemplate] = [.winBattles, .dealDamage, .gatherResources, .buildNestComponents, .playWithFriends]
        weeklyChallenges = templates.shuffled().prefix(3).map { $0.generate(type: .weekly) }
        lastWeeklyRefresh = Date()
        saveChallenges()
    }
    
    // MARK: - Progress Tracking
    
    func updateProgress(for event: ChallengeEvent, amount: Int = 1) {
        var updated = false
        
        // Update daily challenges
        for i in dailyChallenges.indices {
            if shouldUpdate(challenge: dailyChallenges[i], for: event) {
                dailyChallenges[i].progress += amount
                if dailyChallenges[i].progress >= dailyChallenges[i].requirement {
                    dailyChallenges[i].isCompleted = true
                }
                updated = true
            }
        }
        
        // Update weekly challenges
        for i in weeklyChallenges.indices {
            if shouldUpdate(challenge: weeklyChallenges[i], for: event) {
                weeklyChallenges[i].progress += amount
                if weeklyChallenges[i].progress >= weeklyChallenges[i].requirement {
                    weeklyChallenges[i].isCompleted = true
                }
                updated = true
            }
        }
        
        if updated {
            saveChallenges()
        }
    }
    
    private func shouldUpdate(challenge: Challenge, for event: ChallengeEvent) -> Bool {
        guard !challenge.isCompleted && !challenge.isExpired else { return false }
        
        switch event {
        case .win:
            return challenge.title.contains("Win") && !challenge.title.contains("as ")
        case .winWithBird(let bird):
            return challenge.title.contains("Win") && challenge.title.contains(bird.displayName)
        case .playMatch:
            return challenge.title.contains("Play") && challenge.title.contains("Match")
        case .dealDamage:
            return challenge.title.contains("Damage")
        case .useAbility:
            return challenge.title.contains("Abilities")
        case .gatherResource:
            return challenge.title.contains("Resources")
        case .buildNest:
            return challenge.title.contains("Nest")
        case .playWithFriend:
            return challenge.title.contains("Friends")
        case .joinParty:
            return challenge.title.contains("Party")
        }
    }
    
    // MARK: - Claim Rewards
    
    func claimReward(for challenge: Challenge) -> Bool {
        guard challenge.isCompleted && !challenge.isClaimed else { return false }
        
        // Find and update the challenge
        if let index = dailyChallenges.firstIndex(where: { $0.id == challenge.id }) {
            dailyChallenges[index].isClaimed = true
            awardRewards(challenge)
            saveChallenges()
            return true
        }
        
        if let index = weeklyChallenges.firstIndex(where: { $0.id == challenge.id }) {
            weeklyChallenges[index].isClaimed = true
            awardRewards(challenge)
            saveChallenges()
            return true
        }
        
        return false
    }
    
    private func awardRewards(_ challenge: Challenge) {
        CurrencyManager.shared.addCoins(challenge.rewardCoins, reason: "Challenge: \(challenge.title)")
        PrestigeManager.shared.addXP(challenge.rewardXP)
        if challenge.rewardFeathers > 0 {
            CurrencyManager.shared.addFeathers(challenge.rewardFeathers, reason: "Challenge: \(challenge.title)")
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Stats
    
    var unclaimedCount: Int {
        let dailyUnclaimed = dailyChallenges.filter { $0.isCompleted && !$0.isClaimed }.count
        let weeklyUnclaimed = weeklyChallenges.filter { $0.isCompleted && !$0.isClaimed }.count
        return dailyUnclaimed + weeklyUnclaimed
    }
    
    // MARK: - Persistence
    
    private func saveChallenges() {
        if let dailyData = try? JSONEncoder().encode(dailyChallenges) {
            UserDefaults.standard.set(dailyData, forKey: dailySaveKey)
        }
        if let weeklyData = try? JSONEncoder().encode(weeklyChallenges) {
            UserDefaults.standard.set(weeklyData, forKey: weeklySaveKey)
        }
        if let lastDaily = lastDailyRefresh {
            UserDefaults.standard.set(lastDaily, forKey: dailyRefreshKey)
        }
        if let lastWeekly = lastWeeklyRefresh {
            UserDefaults.standard.set(lastWeekly, forKey: weeklyRefreshKey)
        }
    }
    
    private func loadChallenges() {
        if let dailyData = UserDefaults.standard.data(forKey: dailySaveKey),
           let daily = try? JSONDecoder().decode([Challenge].self, from: dailyData) {
            dailyChallenges = daily
        }
        if let weeklyData = UserDefaults.standard.data(forKey: weeklySaveKey),
           let weekly = try? JSONDecoder().decode([Challenge].self, from: weeklyData) {
            weeklyChallenges = weekly
        }
        lastDailyRefresh = UserDefaults.standard.object(forKey: dailyRefreshKey) as? Date
        lastWeeklyRefresh = UserDefaults.standard.object(forKey: weeklyRefreshKey) as? Date
    }
}

// MARK: - Challenge Event

enum ChallengeEvent {
    case win
    case winWithBird(BirdType)
    case playMatch
    case dealDamage
    case useAbility
    case gatherResource
    case buildNest
    case playWithFriend
    case joinParty
}
