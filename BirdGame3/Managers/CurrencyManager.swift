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
    
    /// Add coins
    func addCoins(_ amount: Int) {
        coins += amount
    }
    
    /// Spend coins if player has enough
    func spendCoins(_ amount: Int) -> Bool {
        guard coins >= amount else { return false }
        coins -= amount
        return true
    }
    
    /// Add feathers (premium currency)
    func addFeathers(_ amount: Int) {
        feathers += amount
    }
    
    /// Spend feathers if player has enough
    func spendFeathers(_ amount: Int) -> Bool {
        guard feathers >= amount else { return false }
        feathers -= amount
        return true
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
    
    // MARK: - Persistence
    
    private func save() {
        UserDefaults.standard.set(coins, forKey: coinsKey)
        UserDefaults.standard.set(feathers, forKey: feathersKey)
    }
    
    /// Reset all currency (for testing)
    func reset() {
        coins = 500
        feathers = 10
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
