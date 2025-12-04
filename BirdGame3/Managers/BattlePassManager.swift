//
//  BattlePassManager.swift
//  BirdGame3
//
//  Season/Battle Pass system with free and premium tiers
//

import Foundation
import SwiftUI

// MARK: - Battle Pass Season

struct BattlePassSeason: Codable {
    let id: String
    let name: String
    let seasonNumber: Int
    let startDate: Date
    let endDate: Date
    let tiers: [BattlePassTier]
    
    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }
    
    var daysRemaining: Int {
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, remaining)
    }
    
    var progressPercent: Double {
        let total = endDate.timeIntervalSince(startDate)
        let elapsed = Date().timeIntervalSince(startDate)
        return min(max(elapsed / total, 0), 1.0)
    }
}

// MARK: - Battle Pass Tier

struct BattlePassTier: Identifiable, Codable {
    let id: Int
    let requiredXP: Int
    let freeReward: BattlePassReward?
    let premiumReward: BattlePassReward?
}

// MARK: - Battle Pass Reward

struct BattlePassReward: Identifiable, Codable {
    let id: String
    let type: BattlePassRewardType
    let name: String
    let icon: String
    let amount: Int
    let skinId: String?
    let emoteId: String?
    let rarity: RewardRarity
}

// MARK: - Reward Type

enum BattlePassRewardType: String, Codable {
    case coins
    case feathers
    case skin
    case emote
    case badge
    case xpBoost
    case title
}

// MARK: - Reward Rarity

enum RewardRarity: String, Codable, CaseIterable {
    case common
    case uncommon
    case rare
    case epic
    case legendary
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

// MARK: - Battle Pass Manager

class BattlePassManager: ObservableObject {
    static let shared = BattlePassManager()
    
    // MARK: - Published Properties
    
    @Published var currentSeason: BattlePassSeason?
    @Published var isPremium: Bool = false
    @Published var currentTier: Int = 0
    @Published var currentXP: Int = 0
    @Published var claimedFreeTiers: Set<Int> = []
    @Published var claimedPremiumTiers: Set<Int> = []
    
    // MARK: - Constants
    
    /// Premium Battle Pass price - $3.99 USD via In-App Purchase
    /// Product ID: com.birdgame3.battlepass.premium
    let premiumPriceUSD: Double = 3.99
    let premiumProductId = "com.birdgame3.battlepass.premium"
    let xpPerTier: Int = 1000
    let maxTier: Int = 100
    
    // MARK: - Private Properties
    
    private let saveKey = "birdgame3_battlepass"
    
    // MARK: - Initialization
    
    private init() {
        loadProgress()
        initializeCurrentSeason()
    }
    
    // MARK: - Season Management
    
    private func initializeCurrentSeason() {
        // Check if we need a new season
        if currentSeason == nil || !currentSeason!.isActive {
            currentSeason = createNewSeason()
            resetProgress()
        }
    }
    
    private func createNewSeason() -> BattlePassSeason {
        let calendar = Calendar.current
        let now = Date()
        
        // Season lasts ~2 months
        let startOfSeason = calendar.startOfDay(for: now)
        let endOfSeason = calendar.date(byAdding: .day, value: 60, to: startOfSeason)!
        
        let seasonNumber = (calendar.component(.month, from: now) / 2) + 1
        
        return BattlePassSeason(
            id: UUID().uuidString,
            name: "Season \(seasonNumber): \(seasonTheme(for: seasonNumber))",
            seasonNumber: seasonNumber,
            startDate: startOfSeason,
            endDate: endOfSeason,
            tiers: generateTiers()
        )
    }
    
    private func seasonTheme(for number: Int) -> String {
        let themes = ["Rise of the Pigeons", "Eagle's Dominion", "Crow's Revenge", "Feathered Fury", "Sky Wars", "Nest Invasion"]
        return themes[(number - 1) % themes.count]
    }
    
    private func generateTiers() -> [BattlePassTier] {
        var tiers: [BattlePassTier] = []
        
        for i in 1...maxTier {
            let tier = BattlePassTier(
                id: i,
                requiredXP: i * xpPerTier,
                freeReward: generateFreeReward(for: i),
                premiumReward: generatePremiumReward(for: i)
            )
            tiers.append(tier)
        }
        
        return tiers
    }
    
    private func generateFreeReward(for tier: Int) -> BattlePassReward? {
        // Free rewards every 5 tiers, always coins or small amounts
        guard tier % 5 == 0 || tier == 1 else { return nil }
        
        let coinAmount = tier * 50
        return BattlePassReward(
            id: "free_\(tier)",
            type: .coins,
            name: "\(coinAmount) Coins",
            icon: "🪙",
            amount: coinAmount,
            skinId: nil,
            emoteId: nil,
            rarity: .common
        )
    }
    
    private func generatePremiumReward(for tier: Int) -> BattlePassReward {
        // Premium rewards at every tier
        switch tier {
        case 1, 11, 21, 31, 41, 51, 61, 71, 81, 91:
            // Emotes at these tiers
            let emotes = ["wave", "laugh", "dance", "flex", "cry", "taunt", "bow", "spin", "fly", "victory"]
            let index = tier / 10
            return BattlePassReward(
                id: "premium_emote_\(tier)",
                type: .emote,
                name: "Emote: \(emotes[index].capitalized)",
                icon: "🎭",
                amount: 1,
                skinId: nil,
                emoteId: "emote_\(emotes[index])",
                rarity: tier > 50 ? .epic : .rare
            )
            
        case 10, 30, 50, 70, 90:
            // Skins at milestone tiers
            let birds = BirdType.allCases
            let bird = birds[(tier / 20) % birds.count]
            let skinNames = ["Shadow", "Golden", "Crystal", "Inferno", "Frost"]
            let skinName = skinNames[(tier / 20) % skinNames.count]
            return BattlePassReward(
                id: "premium_skin_\(tier)",
                type: .skin,
                name: "\(skinName) \(bird.displayName)",
                icon: bird.emoji,
                amount: 1,
                skinId: "\(bird.rawValue)_\(skinName.lowercased())",
                emoteId: nil,
                rarity: tier >= 70 ? .legendary : .epic
            )
            
        case 100:
            // Final tier - exclusive legendary skin
            return BattlePassReward(
                id: "premium_final",
                type: .skin,
                name: "Phoenix Rising",
                icon: "🔥",
                amount: 1,
                skinId: "eagle_phoenix",
                emoteId: nil,
                rarity: .legendary
            )
            
        case 25, 75:
            // XP Boosts
            return BattlePassReward(
                id: "premium_xp_\(tier)",
                type: .xpBoost,
                name: "XP Boost (24h)",
                icon: "⚡",
                amount: 1,
                skinId: nil,
                emoteId: nil,
                rarity: .rare
            )
            
        default:
            // Coins and feathers for other tiers
            if tier % 2 == 0 {
                let amount = tier * 20
                return BattlePassReward(
                    id: "premium_coins_\(tier)",
                    type: .coins,
                    name: "\(amount) Coins",
                    icon: "🪙",
                    amount: amount,
                    skinId: nil,
                    emoteId: nil,
                    rarity: .uncommon
                )
            } else {
                let amount = tier * 2
                return BattlePassReward(
                    id: "premium_feathers_\(tier)",
                    type: .feathers,
                    name: "\(amount) Feathers",
                    icon: "🪶",
                    amount: amount,
                    skinId: nil,
                    emoteId: nil,
                    rarity: .uncommon
                )
            }
        }
    }
    
    // MARK: - XP & Progression
    
    func addXP(_ amount: Int) {
        currentXP += amount
        
        // Check for tier ups
        while currentXP >= xpPerTier && currentTier < maxTier {
            currentXP -= xpPerTier
            currentTier += 1
            
            // Notify tier up
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            VoiceChatManager.shared.speak("Battle Pass tier \(currentTier) reached!", priority: .normal)
        }
        
        saveProgress()
    }
    
    var xpProgress: Double {
        Double(currentXP) / Double(xpPerTier)
    }
    
    var xpToNextTier: Int {
        xpPerTier - currentXP
    }
    
    // MARK: - Premium Purchase
    
    func purchasePremium() -> Bool {
        guard !isPremium else { return false }
        
        if CurrencyManager.shared.spendFeathers(premiumPrice, reason: "Battle Pass Premium") {
            isPremium = true
            saveProgress()
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            return true
        }
        
        return false
    }
    
    // MARK: - Claim Rewards
    
    func claimFreeReward(tier: Int) -> BattlePassReward? {
        guard tier <= currentTier,
              !claimedFreeTiers.contains(tier),
              let tierData = currentSeason?.tiers.first(where: { $0.id == tier }),
              let reward = tierData.freeReward else {
            return nil
        }
        
        awardReward(reward)
        claimedFreeTiers.insert(tier)
        saveProgress()
        
        return reward
    }
    
    func claimPremiumReward(tier: Int) -> BattlePassReward? {
        guard isPremium,
              tier <= currentTier,
              !claimedPremiumTiers.contains(tier),
              let tierData = currentSeason?.tiers.first(where: { $0.id == tier }) else {
            return nil
        }
        
        let reward = tierData.premiumReward
        awardReward(reward)
        claimedPremiumTiers.insert(tier)
        saveProgress()
        
        return reward
    }
    
    private func awardReward(_ reward: BattlePassReward) {
        switch reward.type {
        case .coins:
            CurrencyManager.shared.addCoins(reward.amount, reason: "Battle Pass")
        case .feathers:
            CurrencyManager.shared.addFeathers(reward.amount, reason: "Battle Pass")
        case .skin:
            if let skinId = reward.skinId {
                SkinManager.shared.unlockSkin(skinId)
            }
        case .emote:
            if let emoteId = reward.emoteId {
                EmoteManager.shared.unlockEmote(emoteId)
            }
        case .badge:
            AchievementManager.shared.unlockBadge(reward.id)
        case .xpBoost:
            PrestigeManager.shared.activateXPBoost(hours: 24)
        case .title:
            // Title rewards would be handled by a TitleManager
            break
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Stats
    
    var unclaimedFreeCount: Int {
        guard let season = currentSeason else { return 0 }
        return season.tiers
            .filter { $0.id <= currentTier && $0.freeReward != nil && !claimedFreeTiers.contains($0.id) }
            .count
    }
    
    var unclaimedPremiumCount: Int {
        guard isPremium, let season = currentSeason else { return 0 }
        return season.tiers
            .filter { $0.id <= currentTier && !claimedPremiumTiers.contains($0.id) }
            .count
    }
    
    // MARK: - Persistence
    
    private func saveProgress() {
        let data: [String: Any] = [
            "isPremium": isPremium,
            "currentTier": currentTier,
            "currentXP": currentXP,
            "claimedFree": Array(claimedFreeTiers),
            "claimedPremium": Array(claimedPremiumTiers),
            "seasonId": currentSeason?.id ?? ""
        ]
        UserDefaults.standard.set(data, forKey: saveKey)
    }
    
    private func loadProgress() {
        guard let data = UserDefaults.standard.dictionary(forKey: saveKey) else { return }
        
        isPremium = data["isPremium"] as? Bool ?? false
        currentTier = data["currentTier"] as? Int ?? 0
        currentXP = data["currentXP"] as? Int ?? 0
        
        if let freeArray = data["claimedFree"] as? [Int] {
            claimedFreeTiers = Set(freeArray)
        }
        if let premiumArray = data["claimedPremium"] as? [Int] {
            claimedPremiumTiers = Set(premiumArray)
        }
    }
    
    private func resetProgress() {
        currentTier = 0
        currentXP = 0
        claimedFreeTiers = []
        claimedPremiumTiers = []
        // Note: isPremium persists across seasons if purchased
        saveProgress()
    }
}
