//
//  Bird.swift
//  BirdGame3
//
//  The foundation of all bird warriors
//

import Foundation
import SpriteKit

/// Base stats for a bird character
struct BirdStats {
    var health: Double
    var maxHealth: Double
    var attack: Double
    var defense: Double
    var speed: Double
    var abilityCooldown: Double
    var abilityDamage: Double
    
    // Meme stats (for display only)
    var featherDensity: Int
    var cooPower: String
    var wingspan: String
    var intimidationLevel: String
}

/// A bird character in the game
class Bird: ObservableObject, Identifiable {
    let id = UUID()
    let type: BirdType
    let name: String
    let emoji: String
    let description: String
    let abilityName: String
    let abilityDescription: String
    
    @Published var stats: BirdStats
    @Published var currentHealth: Double
    @Published var isAbilityReady: Bool = true
    @Published var abilityCooldownRemaining: Double = 0
    @Published var position: CGPoint = .zero
    @Published var isBlocking: Bool = false
    @Published var isAttacking: Bool = false
    @Published var isUsingAbility: Bool = false
    @Published var facingRight: Bool = true
    
    init(type: BirdType) {
        self.type = type
        self.name = type.displayName
        self.emoji = type.emoji
        self.description = type.flavorText
        self.abilityName = type.abilityName
        self.abilityDescription = type.abilityDescription
        self.stats = type.baseStats
        self.currentHealth = stats.maxHealth
    }
    
    func takeDamage(_ amount: Double) {
        let actualDamage = isBlocking ? amount * 0.3 : amount
        currentHealth = max(0, currentHealth - actualDamage)
    }
    
    func heal(_ amount: Double) {
        currentHealth = min(stats.maxHealth, currentHealth + amount)
    }
    
    func resetForBattle() {
        currentHealth = stats.maxHealth
        isAbilityReady = true
        abilityCooldownRemaining = 0
        isBlocking = false
        isAttacking = false
        isUsingAbility = false
    }
    
    var healthPercentage: Double {
        return currentHealth / stats.maxHealth
    }
    
    var isAlive: Bool {
        return currentHealth > 0
    }
}
