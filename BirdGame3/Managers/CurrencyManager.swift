//
//  CurrencyManager.swift
//  BirdGame3
//
//  Manages in-game currency (coins) and premium currency (feathers)
//

import Foundation
import SwiftUI

/// Manages all in-game currencies
class CurrencyManager: ObservableObject {
    static let shared = CurrencyManager()
    
    // MARK: - Published Properties
    
    /// Standard currency earned from battles
    @Published private(set) var coins: Int {
        didSet { save() }
    }
    
    /// Premium currency (could be purchased or earned from achievements)
    @Published private(set) var feathers: Int {
        didSet { save() }
    }
    
    // MARK: - Constants
    
    private let coinsKey = "birdgame3_coins"
    private let feathersKey = "birdgame3_feathers"
    
    // Coin rewards
    static let winReward = 100
    static let lossReward = 25
    static let perfectWinBonus = 50
    static let arcadeStageBonus = 25
    static let firstWinOfDayBonus = 200
    
    // MARK: - Initialization
    
    private init() {
        self.coins = UserDefaults.standard.integer(forKey: coinsKey)
        self.feathers = UserDefaults.standard.integer(forKey: feathersKey)
        
        // Give starting currency if first launch
        if !UserDefaults.standard.bool(forKey: "birdgame3_hasLaunched") {
            self.coins = 500
            self.feathers = 10
            UserDefaults.standard.set(true, forKey: "birdgame3_hasLaunched")
            save()
        }
    }
    
    // MARK: - Currency Operations
    
    /// Add coins with optional reason tracking
    func addCoins(_ amount: Int, reason: String? = nil) {
        coins += amount
        if let reason = reason {
            logTransaction(type: .coinEarned, amount: amount, reason: reason)
        }
    }
    
    /// Spend coins if player has enough with optional reason tracking
    func spendCoins(_ amount: Int, reason: String? = nil) -> Bool {
        guard coins >= amount else { return false }
        coins -= amount
        if let reason = reason {
            logTransaction(type: .coinSpent, amount: amount, reason: reason)
        }
        return true
    }
    
    /// Add feathers (premium currency) with optional reason tracking
    func addFeathers(_ amount: Int, reason: String? = nil) {
        feathers += amount
        if let reason = reason {
            logTransaction(type: .featherEarned, amount: amount, reason: reason)
        }
    }
    
    /// Spend feathers if player has enough with optional reason tracking
    func spendFeathers(_ amount: Int, reason: String? = nil) -> Bool {
        guard feathers >= amount else { return false }
        feathers -= amount
        if let reason = reason {
            logTransaction(type: .featherSpent, amount: amount, reason: reason)
        }
        return true
    }
    
    // MARK: - Transaction Logging
    
    private enum TransactionType: String {
        case coinEarned = "coin_earned"
        case coinSpent = "coin_spent"
        case featherEarned = "feather_earned"
        case featherSpent = "feather_spent"
    }
    
    private func logTransaction(type: TransactionType, amount: Int, reason: String) {
        // Log transaction for analytics/debugging (could be expanded for detailed history)
        #if DEBUG
        print("💰 [\(type.rawValue)] \(amount) - \(reason)")
        #endif
    }
    
    /// Check if player can afford something
    func canAfford(coins: Int = 0, feathers: Int = 0) -> Bool {
        return self.coins >= coins && self.feathers >= feathers
    }
    
    // MARK: - Battle Rewards
    
    /// Calculate and grant rewards for a battle
    func grantBattleRewards(
        won: Bool,
        isPerfect: Bool = false,
        arcadeStage: Int? = nil,
        isFirstWinOfDay: Bool = false
    ) -> BattleReward {
        var coinReward = won ? Self.winReward : Self.lossReward
        var featherReward = 0
        var bonuses: [String] = []
        
        if won {
            if isPerfect {
                coinReward += Self.perfectWinBonus
                bonuses.append("Perfect Win! +\(Self.perfectWinBonus)")
            }
            
            if let stage = arcadeStage {
                let stageBonus = Self.arcadeStageBonus * stage
                coinReward += stageBonus
                bonuses.append("Arcade Stage \(stage)! +\(stageBonus)")
            }
            
            if isFirstWinOfDay {
                coinReward += Self.firstWinOfDayBonus
                featherReward += 1
                bonuses.append("First Win of Day! +\(Self.firstWinOfDayBonus) 🪶+1")
            }
        }
        
        addCoins(coinReward)
        if featherReward > 0 {
            addFeathers(featherReward)
        }
        
        return BattleReward(
            coins: coinReward,
            feathers: featherReward,
            bonuses: bonuses
        )
    }
    
    // MARK: - Credit Multiplier System
    
    /// Active credit multipliers from cosmetics/accessories
    @Published private(set) var creditMultiplier: Double = 1.0
    
    /// Set the credit multiplier based on equipped cosmetics
    func updateCreditMultiplier(from equippedSkins: [BirdSkin]) {
        var multiplier = 1.0
        
        for skin in equippedSkins {
            // Rare skins give 5% bonus, Epic 10%, Legendary 15%, Mythic 25%
            switch skin.rarity {
            case .common:
                break
            case .rare:
                multiplier += 0.05
            case .epic:
                multiplier += 0.10
            case .legendary:
                multiplier += 0.15
            case .mythic:
                multiplier += 0.25
            }
        }
        
        // Cap at 2x multiplier
        creditMultiplier = min(2.0, multiplier)
    }
    
    /// Apply credit multiplier to coin earnings
    func addCoinsWithMultiplier(_ baseAmount: Int, reason: String? = nil) {
        let multipliedAmount = Int(Double(baseAmount) * creditMultiplier)
        addCoins(multipliedAmount, reason: reason)
    }
    
    // MARK: - Persistence
    
    private func save() {
        UserDefaults.standard.set(coins, forKey: coinsKey)
        UserDefaults.standard.set(feathers, forKey: feathersKey)
    }
    
    /// Reset all currency (for testing)
    func reset() {
        coins = 500
        feathers = 10
        creditMultiplier = 1.0
        save()
    }
}

// MARK: - Battle Reward

struct BattleReward {
    let coins: Int
    let feathers: Int
    let bonuses: [String]
    
    var hasBonus: Bool {
        !bonuses.isEmpty
    }
}
