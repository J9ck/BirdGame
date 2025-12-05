//
//  QuestManager.swift
//  BirdGame3
//
//  Quest and mission system with daily/weekly hooks
//

import Foundation
import SwiftUI

// MARK: - Quest Type

enum QuestType: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case story = "Story"
    case achievement = "Achievement"
    case event = "Event"
    
    var emoji: String {
        switch self {
        case .daily: return "📅"
        case .weekly: return "📆"
        case .story: return "📖"
        case .achievement: return "🏆"
        case .event: return "🎉"
        }
    }
    
    var refreshInterval: TimeInterval? {
        switch self {
        case .daily: return 86400 // 24 hours
        case .weekly: return 604800 // 7 days
        case .story, .achievement, .event: return nil
        }
    }
}

// MARK: - Quest Objective Type

enum QuestObjectiveType: String, Codable {
    case hunt = "Hunt"
    case gather = "Gather"
    case travel = "Travel"
    case combat = "Combat"
    case build = "Build"
    case social = "Social"
    case explore = "Explore"
    case survive = "Survive"
    
    var emoji: String {
        switch self {
        case .hunt: return "🎯"
        case .gather: return "🧺"
        case .travel: return "🧭"
        case .combat: return "⚔️"
        case .build: return "🏗️"
        case .social: return "🤝"
        case .explore: return "🗺️"
        case .survive: return "❤️"
        }
    }
}

// MARK: - Quest Objective

struct QuestObjective: Identifiable, Codable {
    let id: String
    let type: QuestObjectiveType
    let description: String
    let targetValue: Int
    var currentValue: Int
    let targetId: String? // Optional specific target (e.g., biome name, prey type)
    
    var isComplete: Bool { currentValue >= targetValue }
    var progress: Double { Double(currentValue) / Double(targetValue) }
    var progressText: String { "\(currentValue)/\(targetValue)" }
}

// MARK: - Quest Reward

struct QuestReward: Codable {
    let coins: Int
    let feathers: Int
    let xp: Int
    let items: [String: Int]? // Item ID to amount
    
    static let none = QuestReward(coins: 0, feathers: 0, xp: 0, items: nil)
}

// MARK: - Quest

struct Quest: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let type: QuestType
    var objectives: [QuestObjective]
    let reward: QuestReward
    let expiresAt: Date?
    var isActive: Bool
    var isCompleted: Bool
    var isClaimed: Bool
    var startedAt: Date?
    var completedAt: Date?
    
    var allObjectivesComplete: Bool {
        objectives.allSatisfy { $0.isComplete }
    }
    
    var overallProgress: Double {
        guard !objectives.isEmpty else { return 0 }
        return objectives.reduce(0) { $0 + $1.progress } / Double(objectives.count)
    }
    
    var isExpired: Bool {
        guard let expires = expiresAt else { return false }
        return Date() >= expires
    }
    
    var timeRemaining: TimeInterval? {
        guard let expires = expiresAt else { return nil }
        return max(0, expires.timeIntervalSince(Date()))
    }
    
    var timeRemainingText: String? {
        guard let remaining = timeRemaining else { return nil }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        
        if hours > 24 {
            return "\(hours / 24)d \(hours % 24)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Quest Manager

class QuestManager: ObservableObject {
    static let shared = QuestManager()
    
    // MARK: - Published Properties
    
    @Published var activeQuests: [Quest] = []
    @Published var completedQuests: [String] = []
    @Published var dailyQuestsRefreshTime: Date?
    @Published var weeklyQuestsRefreshTime: Date?
    
    // MARK: - Constants
    
    private let maxDailyQuests = 3
    private let maxWeeklyQuests = 3
    private let saveKey = "birdgame3_quests"
    
    // MARK: - Initialization
    
    private init() {
        loadProgress()
        checkAndRefreshQuests()
        startRefreshTimer()
    }
    
    // MARK: - Quest Generation
    
    func checkAndRefreshQuests() {
        let now = Date()
        
        // Check daily quests
        if let refreshTime = dailyQuestsRefreshTime, now >= refreshTime {
            refreshDailyQuests()
        } else if dailyQuestsRefreshTime == nil {
            refreshDailyQuests()
        }
        
        // Check weekly quests
        if let refreshTime = weeklyQuestsRefreshTime, now >= refreshTime {
            refreshWeeklyQuests()
        } else if weeklyQuestsRefreshTime == nil {
            refreshWeeklyQuests()
        }
    }
    
    private func refreshDailyQuests() {
        // Remove old daily quests
        activeQuests.removeAll { $0.type == .daily }
        
        // Generate new daily quests
        let dailyQuests = generateDailyQuests()
        activeQuests.append(contentsOf: dailyQuests)
        
        // Set next refresh time (midnight tomorrow)
        let calendar = Calendar.current
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()),
           let midnight = calendar.startOfDay(for: tomorrow) as Date? {
            dailyQuestsRefreshTime = midnight
        }
        
        save()
    }
    
    private func refreshWeeklyQuests() {
        // Remove old weekly quests
        activeQuests.removeAll { $0.type == .weekly }
        
        // Generate new weekly quests
        let weeklyQuests = generateWeeklyQuests()
        activeQuests.append(contentsOf: weeklyQuests)
        
        // Set next refresh time (next Monday at start of day)
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekOfYear! += 1
        components.weekday = 2 // Monday
        if let nextMonday = calendar.date(from: components) {
            weeklyQuestsRefreshTime = calendar.startOfDay(for: nextMonday)
        }
        
        save()
    }
    
    private func generateDailyQuests() -> [Quest] {
        let expiresAt = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        let possibleQuests: [Quest] = [
            Quest(
                id: "daily_hunt_5",
                name: "Hunter's Morning",
                description: "Hunt 5 prey animals",
                type: .daily,
                objectives: [
                    QuestObjective(id: "hunt_prey", type: .hunt, description: "Hunt any prey", targetValue: 5, currentValue: 0, targetId: nil)
                ],
                reward: QuestReward(coins: 100, feathers: 0, xp: 50, items: nil),
                expiresAt: expiresAt,
                isActive: true,
                isCompleted: false,
                isClaimed: false,
                startedAt: Date(),
                completedAt: nil
            ),
            Quest(
                id: "daily_gather_20",
                name: "Resource Collector",
                description: "Gather 20 resources",
                type: .daily,
                objectives: [
                    QuestObjective(id: "gather_any", type: .gather, description: "Gather any resource", targetValue: 20, currentValue: 0, targetId: nil)
                ],
                reward: QuestReward(coins: 80, feathers: 0, xp: 40, items: nil),
                expiresAt: expiresAt,
                isActive: true,
                isCompleted: false,
                isClaimed: false,
                startedAt: Date(),
                completedAt: nil
            ),
            Quest(
                id: "daily_fly_1000",
                name: "Frequent Flyer",
                description: "Fly 1000 meters",
                type: .daily,
                objectives: [
                    QuestObjective(id: "fly_distance", type: .travel, description: "Distance flown", targetValue: 1000, currentValue: 0, targetId: nil)
                ],
                reward: QuestReward(coins: 75, feathers: 0, xp: 35, items: nil),
                expiresAt: expiresAt,
                isActive: true,
                isCompleted: false,
                isClaimed: false,
                startedAt: Date(),
                completedAt: nil
            ),
            Quest(
                id: "daily_survive_10",
                name: "Survivor",
                description: "Survive for 10 minutes in the wild",
                type: .daily,
                objectives: [
                    QuestObjective(id: "survive_time", type: .survive, description: "Survival time (minutes)", targetValue: 10, currentValue: 0, targetId: nil)
                ],
                reward: QuestReward(coins: 120, feathers: 1, xp: 60, items: nil),
                expiresAt: expiresAt,
                isActive: true,
                isCompleted: false,
                isClaimed: false,
                startedAt: Date(),
                completedAt: nil
            ),
            Quest(
                id: "daily_hunt_hard",
                name: "Big Game Hunter",
                description: "Hunt a difficult prey (rabbit or snake)",
                type: .daily,
                objectives: [
                    QuestObjective(id: "hunt_hard", type: .hunt, description: "Hunt difficult prey", targetValue: 1, currentValue: 0, targetId: "hard_prey")
                ],
                reward: QuestReward(coins: 150, feathers: 2, xp: 75, items: nil),
                expiresAt: expiresAt,
                isActive: true,
                isCompleted: false,
                isClaimed: false,
                startedAt: Date(),
                completedAt: nil
            )
        ]
        
        // Randomly select quests
        return Array(possibleQuests.shuffled().prefix(maxDailyQuests))
    }
    
    private func generateWeeklyQuests() -> [Quest] {
        let expiresAt = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())!
        
        let possibleQuests: [Quest] = [
            Quest(
                id: "weekly_hunt_50",
                name: "Master Hunter",
                description: "Hunt 50 prey animals this week",
                type: .weekly,
                objectives: [
                    QuestObjective(id: "hunt_50", type: .hunt, description: "Hunt any prey", targetValue: 50, currentValue: 0, targetId: nil)
                ],
                reward: QuestReward(coins: 500, feathers: 10, xp: 250, items: nil),
                expiresAt: expiresAt,
                isActive: true,
                isCompleted: false,
                isClaimed: false,
                startedAt: Date(),
                completedAt: nil
            ),
            Quest(
                id: "weekly_explore_biomes",
                name: "World Explorer",
                description: "Visit 5 different biomes",
                type: .weekly,
                objectives: [
                    QuestObjective(id: "visit_biomes", type: .explore, description: "Biomes visited", targetValue: 5, currentValue: 0, targetId: nil)
                ],
                reward: QuestReward(coins: 400, feathers: 8, xp: 200, items: nil),
                expiresAt: expiresAt,
                isActive: true,
                isCompleted: false,
                isClaimed: false,
                startedAt: Date(),
                completedAt: nil
            ),
            Quest(
                id: "weekly_nest_upgrade",
                name: "Home Improvement",
                description: "Add 3 components to your nest",
                type: .weekly,
                objectives: [
                    QuestObjective(id: "nest_components", type: .build, description: "Nest components added", targetValue: 3, currentValue: 0, targetId: nil)
                ],
                reward: QuestReward(coins: 350, feathers: 5, xp: 175, items: nil),
                expiresAt: expiresAt,
                isActive: true,
                isCompleted: false,
                isClaimed: false,
                startedAt: Date(),
                completedAt: nil
            ),
            Quest(
                id: "weekly_gather_100",
                name: "Stockpiler",
                description: "Gather 100 resources",
                type: .weekly,
                objectives: [
                    QuestObjective(id: "gather_100", type: .gather, description: "Resources gathered", targetValue: 100, currentValue: 0, targetId: nil)
                ],
                reward: QuestReward(coins: 300, feathers: 5, xp: 150, items: nil),
                expiresAt: expiresAt,
                isActive: true,
                isCompleted: false,
                isClaimed: false,
                startedAt: Date(),
                completedAt: nil
            ),
            Quest(
                id: "weekly_territory",
                name: "Territory Champion",
                description: "Contribute 50 points to territory control",
                type: .weekly,
                objectives: [
                    QuestObjective(id: "territory_points", type: .combat, description: "Territory points contributed", targetValue: 50, currentValue: 0, targetId: nil)
                ],
                reward: QuestReward(coins: 600, feathers: 15, xp: 300, items: nil),
                expiresAt: expiresAt,
                isActive: true,
                isCompleted: false,
                isClaimed: false,
                startedAt: Date(),
                completedAt: nil
            )
        ]
        
        return Array(possibleQuests.shuffled().prefix(maxWeeklyQuests))
    }
    
    // MARK: - Quest Progress
    
    /// Update quest progress for a specific objective type
    func updateProgress(type: QuestObjectiveType, value: Int, targetId: String? = nil) {
        for questIndex in activeQuests.indices {
            guard activeQuests[questIndex].isActive && !activeQuests[questIndex].isCompleted else { continue }
            
            for objectiveIndex in activeQuests[questIndex].objectives.indices {
                let objective = activeQuests[questIndex].objectives[objectiveIndex]
                
                // Match objective type
                guard objective.type == type else { continue }
                
                // Match target ID if specified
                if let objTarget = objective.targetId, objTarget != targetId && targetId != nil {
                    continue
                }
                
                // Update progress
                activeQuests[questIndex].objectives[objectiveIndex].currentValue += value
                
                // Check completion
                if activeQuests[questIndex].allObjectivesComplete {
                    activeQuests[questIndex].isCompleted = true
                    activeQuests[questIndex].completedAt = Date()
                    
                    // Notify
                    NotificationCenter.default.post(
                        name: Notification.Name("BirdGame3.QuestCompleted"),
                        object: nil,
                        userInfo: ["questId": activeQuests[questIndex].id, "questName": activeQuests[questIndex].name]
                    )
                }
            }
        }
        
        save()
    }
    
    // MARK: - Quest Actions
    
    func claimReward(questId: String) -> Bool {
        guard let index = activeQuests.firstIndex(where: { $0.id == questId }),
              activeQuests[index].isCompleted && !activeQuests[index].isClaimed else { return false }
        
        let quest = activeQuests[index]
        
        // Grant rewards
        CurrencyManager.shared.addCoins(quest.reward.coins, reason: "Quest: \(quest.name)")
        if quest.reward.feathers > 0 {
            CurrencyManager.shared.addFeathers(quest.reward.feathers)
        }
        _ = PrestigeManager.shared.addXP(quest.reward.xp)
        
        // Grant items
        if let items = quest.reward.items {
            for (itemId, amount) in items {
                CraftingManager.shared.craftedItems[itemId, default: 0] += amount
            }
        }
        
        // Mark as claimed
        activeQuests[index].isClaimed = true
        completedQuests.append(questId)
        
        save()
        return true
    }
    
    func abandonQuest(questId: String) {
        guard let index = activeQuests.firstIndex(where: { $0.id == questId }),
              activeQuests[index].type == .story else { return } // Only story quests can be abandoned
        
        activeQuests[index].isActive = false
        save()
    }
    
    // MARK: - Quest Queries
    
    func quests(ofType type: QuestType) -> [Quest] {
        activeQuests.filter { $0.type == type && $0.isActive }
    }
    
    var availableRewards: Int {
        activeQuests.filter { $0.isCompleted && !$0.isClaimed }.count
    }
    
    var dailyQuests: [Quest] {
        quests(ofType: .daily)
    }
    
    var weeklyQuests: [Quest] {
        quests(ofType: .weekly)
    }
    
    // MARK: - Timer
    
    private func startRefreshTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkAndRefreshQuests()
        }
    }
    
    // MARK: - Persistence
    
    private func save() {
        let data = QuestSaveData(
            activeQuests: activeQuests,
            completedQuests: completedQuests,
            dailyRefresh: dailyQuestsRefreshTime,
            weeklyRefresh: weeklyQuestsRefreshTime
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(QuestSaveData.self, from: data) {
            activeQuests = decoded.activeQuests.filter { !$0.isExpired }
            completedQuests = decoded.completedQuests
            dailyQuestsRefreshTime = decoded.dailyRefresh
            weeklyQuestsRefreshTime = decoded.weeklyRefresh
        }
    }
}

// MARK: - Save Data

private struct QuestSaveData: Codable {
    let activeQuests: [Quest]
    let completedQuests: [String]
    let dailyRefresh: Date?
    let weeklyRefresh: Date?
}

// MARK: - Convenience Methods for Tracking

extension QuestManager {
    
    /// Track a prey hunt
    func trackPreyHunted(_ preyType: PreyType) {
        let targetId = preyType.difficultyTier >= 5 ? "hard_prey" : nil
        updateProgress(type: .hunt, value: 1, targetId: targetId)
    }
    
    /// Track resource gathering
    func trackResourceGathered(_ amount: Int) {
        updateProgress(type: .gather, value: amount)
    }
    
    /// Track distance traveled
    func trackDistanceTraveled(_ meters: Int) {
        updateProgress(type: .travel, value: meters)
    }
    
    /// Track survival time
    func trackSurvivalTime(_ minutes: Int) {
        updateProgress(type: .survive, value: minutes)
    }
    
    /// Track biome visited
    func trackBiomeVisited(_ biome: Biome) {
        updateProgress(type: .explore, value: 1, targetId: biome.rawValue)
    }
    
    /// Track nest component built
    func trackNestComponentBuilt() {
        updateProgress(type: .build, value: 1)
    }
    
    /// Track territory contribution
    func trackTerritoryContribution(_ points: Int) {
        updateProgress(type: .combat, value: points)
    }
}
