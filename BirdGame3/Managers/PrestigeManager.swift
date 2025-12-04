//
//  PrestigeManager.swift
//  BirdGame3
//
//  Manages prestige levels, XP, and progression rewards
//

import Foundation
import SwiftUI

// MARK: - Prestige Manager

class PrestigeManager: ObservableObject {
    static let shared = PrestigeManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var currentLevel: Int {
        didSet { save() }
    }
    @Published private(set) var currentXP: Int {
        didSet { save() }
    }
    @Published private(set) var prestigeLevel: Int {
        didSet { save() }
    }
    @Published private(set) var totalXPEarned: Int {
        didSet { save() }
    }
    
    // MARK: - Constants
    
    static let maxLevel = 50
    static let maxPrestige = 10
    
    // XP requirements per level (increases exponentially)
    private func xpRequired(forLevel level: Int) -> Int {
        let baseXP = 100
        let multiplier = 1.15
        return Int(Double(baseXP) * pow(multiplier, Double(level - 1)))
    }
    
    // Total XP to reach a level from level 1
    func totalXPForLevel(_ level: Int) -> Int {
        (1..<level).reduce(0) { $0 + xpRequired(forLevel: $1) }
    }
    
    /// XP needed to reach next level from current XP
    var xpToNextLevel: Int {
        xpRequired(forLevel: currentLevel + 1)
    }
    
    /// Progress to next level (0.0 to 1.0)
    var levelProgress: Double {
        Double(currentXP) / Double(xpToNextLevel)
    }
    
    // MARK: - Persistence Keys
    
    private let levelKey = "birdgame3_level"
    private let xpKey = "birdgame3_xp"
    private let prestigeKey = "birdgame3_prestige"
    private let totalXPKey = "birdgame3_totalXP"
    
    // MARK: - Initialization
    
    private init() {
        self.currentLevel = UserDefaults.standard.integer(forKey: levelKey)
        self.currentXP = UserDefaults.standard.integer(forKey: xpKey)
        self.prestigeLevel = UserDefaults.standard.integer(forKey: prestigeKey)
        self.totalXPEarned = UserDefaults.standard.integer(forKey: totalXPKey)
        
        // First launch defaults
        if currentLevel == 0 {
            currentLevel = 1
            save()
        }
    }
    
    // MARK: - XP Methods
    
    /// Add XP and handle level ups
    @discardableResult
    func addXP(_ amount: Int) -> [LevelUpReward] {
        var rewards: [LevelUpReward] = []
        
        currentXP += amount
        totalXPEarned += amount
        
        // Check for level ups
        while currentXP >= xpToNextLevel && currentLevel < Self.maxLevel {
            currentXP -= xpToNextLevel
            currentLevel += 1
            
            // Grant level up rewards
            let reward = getLevelUpReward(for: currentLevel)
            rewards.append(reward)
            applyReward(reward)
        }
        
        // Cap XP at max level
        if currentLevel >= Self.maxLevel {
            currentXP = 0
        }
        
        return rewards
    }
    
    /// Calculate XP earned from a battle
    func calculateBattleXP(won: Bool, isPerfect: Bool, matchDuration: TimeInterval, arcadeStage: Int?) -> Int {
        var xp = won ? 50 : 20
        
        // Bonus for perfect win
        if isPerfect && won {
            xp += 25
        }
        
        // Bonus for longer matches (more engaging)
        if matchDuration > 30 {
            xp += 10
        }
        if matchDuration > 60 {
            xp += 15
        }
        
        // Arcade stage bonus
        if let stage = arcadeStage, won {
            xp += stage * 5
        }
        
        // Prestige multiplier
        let prestigeBonus = Double(prestigeLevel) * 0.1
        xp = Int(Double(xp) * (1.0 + prestigeBonus))
        
        return xp
    }
    
    // MARK: - Level Rewards
    
    private func getLevelUpReward(for level: Int) -> LevelUpReward {
        var coins = 100 + (level * 10)
        var feathers = 0
        var skinUnlock: String? = nil
        
        // Milestone rewards
        switch level {
        case 5:
            coins = 500
            feathers = 5
        case 10:
            coins = 1000
            feathers = 10
            skinUnlock = "pigeon_golden"
        case 15:
            coins = 750
            feathers = 5
        case 20:
            coins = 1500
            feathers = 15
            skinUnlock = "hummingbird_crystal"
        case 25:
            coins = 1000
            feathers = 10
        case 30:
            coins = 2000
            feathers = 20
            skinUnlock = "eagle_steel"
        case 35:
            coins = 1500
            feathers = 15
        case 40:
            coins = 2500
            feathers = 25
            skinUnlock = "crow_phantom"
        case 45:
            coins = 2000
            feathers = 20
        case 50:
            coins = 5000
            feathers = 50
            skinUnlock = "pelican_pirate"
        default:
            // Every 5 levels give bonus feathers
            if level % 5 == 0 {
                feathers = level / 5
            }
        }
        
        return LevelUpReward(
            level: level,
            coins: coins,
            feathers: feathers,
            skinUnlock: skinUnlock
        )
    }
    
    private func applyReward(_ reward: LevelUpReward) {
        CurrencyManager.shared.addCoins(reward.coins)
        if reward.feathers > 0 {
            CurrencyManager.shared.addFeathers(reward.feathers)
        }
        if let skinId = reward.skinUnlock {
            SkinManager.shared.unlock(skinId: skinId)
        }
    }
    
    // MARK: - Prestige
    
    /// Check if player can prestige
    var canPrestige: Bool {
        currentLevel >= Self.maxLevel && prestigeLevel < Self.maxPrestige
    }
    
    /// Prestige to reset level but gain permanent bonuses
    func prestige() -> PrestigeReward? {
        guard canPrestige else { return nil }
        
        prestigeLevel += 1
        currentLevel = 1
        currentXP = 0
        
        let reward = getPrestigeReward(for: prestigeLevel)
        applyPrestigeReward(reward)
        
        return reward
    }
    
    private func getPrestigeReward(for prestige: Int) -> PrestigeReward {
        var feathers = prestige * 25
        var exclusiveSkin: String? = nil
        
        switch prestige {
        case 1:
            exclusiveSkin = "pigeon_neon"
        case 2:
            exclusiveSkin = "hummingbird_phoenix"
        case 3:
            exclusiveSkin = "pigeon_void"
            feathers = 100
        case 5:
            exclusiveSkin = "eagle_thunder"
            feathers = 150
        case 7:
            exclusiveSkin = "crow_odin"
            feathers = 200
        case 10:
            exclusiveSkin = "pelican_kraken"
            feathers = 500
        default:
            break
        }
        
        return PrestigeReward(
            prestigeLevel: prestige,
            feathers: feathers,
            xpMultiplier: 1.0 + (Double(prestige) * 0.1),
            exclusiveSkin: exclusiveSkin
        )
    }
    
    private func applyPrestigeReward(_ reward: PrestigeReward) {
        CurrencyManager.shared.addFeathers(reward.feathers)
        if let skinId = reward.exclusiveSkin {
            SkinManager.shared.unlock(skinId: skinId)
        }
    }
    
    // MARK: - Prestige Benefits
    
    /// Current XP multiplier from prestige
    var xpMultiplier: Double {
        1.0 + (Double(prestigeLevel) * 0.1)
    }
    
    /// Current coin multiplier from prestige
    var coinMultiplier: Double {
        1.0 + (Double(prestigeLevel) * 0.05)
    }
    
    // MARK: - Display Helpers
    
    var prestigeTitle: String {
        switch prestigeLevel {
        case 0: return ""
        case 1: return "⭐"
        case 2: return "⭐⭐"
        case 3: return "🌟"
        case 4: return "🌟⭐"
        case 5: return "🌟🌟"
        case 6: return "💫"
        case 7: return "💫⭐"
        case 8: return "💫🌟"
        case 9: return "✨"
        case 10: return "👑"
        default: return "👑"
        }
    }
    
    var displayLevel: String {
        if prestigeLevel > 0 {
            return "\(prestigeTitle) Lv.\(currentLevel)"
        }
        return "Lv.\(currentLevel)"
    }
    
    // MARK: - Persistence
    
    private func save() {
        UserDefaults.standard.set(currentLevel, forKey: levelKey)
        UserDefaults.standard.set(currentXP, forKey: xpKey)
        UserDefaults.standard.set(prestigeLevel, forKey: prestigeKey)
        UserDefaults.standard.set(totalXPEarned, forKey: totalXPKey)
    }
    
    /// Reset progression (for testing)
    func reset() {
        currentLevel = 1
        currentXP = 0
        prestigeLevel = 0
        totalXPEarned = 0
        save()
    }
}

// MARK: - Level Up Reward

struct LevelUpReward {
    let level: Int
    let coins: Int
    let feathers: Int
    let skinUnlock: String?
    
    var hasSkin: Bool {
        skinUnlock != nil
    }
}

// MARK: - Prestige Reward

struct PrestigeReward {
    let prestigeLevel: Int
    let feathers: Int
    let xpMultiplier: Double
    let exclusiveSkin: String?
    
    var hasSkin: Bool {
        exclusiveSkin != nil
    }
}
