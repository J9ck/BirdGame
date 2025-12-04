//
//  CombatSystem.swift
//  BirdGame3
//
//  The combat logic that governs all bird battles
//

import Foundation

class CombatSystem {
    
    // MARK: - Damage Calculation
    
    static func calculateDamage(attacker: Bird, defender: Bird, isAbility: Bool = false) -> Double {
        let baseDamage = isAbility ? attacker.stats.abilityDamage : attacker.stats.attack
        let defenseReduction = defender.stats.defense * 0.2
        let blockMultiplier = defender.isBlocking ? 0.3 : 1.0
        
        let finalDamage = max(1, (baseDamage - defenseReduction) * blockMultiplier)
        
        // Add some randomness (±10%)
        let variance = finalDamage * Double.random(in: -0.1...0.1)
        
        return finalDamage + variance
    }
    
    // MARK: - Special Ability Effects
    
    static func applyAbilityEffect(user: Bird, target: Bird, completion: @escaping (AbilityResult) -> Void) {
        var result = AbilityResult()
        
        switch user.type {
        case .pigeon:
            // Breadcrumb Frenzy - temporary attack boost
            result.buffApplied = true
            result.buffType = .attackBoost
            result.buffDuration = 3.0
            result.damage = user.stats.abilityDamage
            
        case .hummingbird:
            // Hover Strike - 5 rapid hits
            result.multiHit = true
            result.hitCount = 5
            result.damage = user.stats.abilityDamage // Per hit
            
        case .eagle:
            // Talon Dive - massive single hit
            result.damage = user.stats.abilityDamage
            result.knockback = true
            
        case .crow:
            // Shiny Distraction - stun
            result.damage = user.stats.abilityDamage
            result.stunApplied = true
            result.stunDuration = 1.5
            
        case .pelican:
            // Fish Slap - damage + knockback
            result.damage = user.stats.abilityDamage
            result.knockback = true
        }
        
        completion(result)
    }
    
    // MARK: - Combo System (Future Feature)
    
    static func checkCombo(attackSequence: [AttackType]) -> ComboResult? {
        // Future implementation for combo attacks
        return nil
    }
}

// MARK: - Supporting Types

struct AbilityResult {
    var damage: Double = 0
    var multiHit: Bool = false
    var hitCount: Int = 1
    var stunApplied: Bool = false
    var stunDuration: Double = 0
    var knockback: Bool = false
    var buffApplied: Bool = false
    var buffType: BuffType = .none
    var buffDuration: Double = 0
}

enum BuffType {
    case none
    case attackBoost
    case speedBoost
    case defenseBoost
}

enum AttackType {
    case light
    case heavy
    case special
}

struct ComboResult {
    var name: String
    var damageMultiplier: Double
    var specialEffect: String?
}

// MARK: - AI Difficulty Levels

enum AIDifficulty: Int, CaseIterable {
    case easy = 1
    case medium = 2
    case hard = 3
    case impossible = 4
    
    var reactionTime: Double {
        switch self {
        case .easy: return 1.0
        case .medium: return 0.6
        case .hard: return 0.3
        case .impossible: return 0.1
        }
    }
    
    var blockChance: Double {
        switch self {
        case .easy: return 0.1
        case .medium: return 0.25
        case .hard: return 0.4
        case .impossible: return 0.6
        }
    }
    
    var displayName: String {
        switch self {
        case .easy: return "Baby Bird 🐣"
        case .medium: return "Fledgling 🐦"
        case .hard: return "Apex Predator 🦅"
        case .impossible: return "BIRD GOD 👑"
        }
    }
}
