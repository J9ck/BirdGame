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
            
        case .owl:
            // Silent Strike - backstab with bleed
            result.damage = user.stats.abilityDamage
            result.bleedApplied = true
            result.bleedDamage = 5.0
            result.bleedDuration = 4.0
        }
        
        completion(result)
    }
    
    // MARK: - Skill Execution
    
    /// Execute a specific skill by ID
    static func executeSkill(skillId: String, user: Bird, target: Bird?, completion: @escaping (SkillResult) -> Void) {
        guard let skill = user.type.skills.first(where: { $0.id == skillId }) else {
            completion(SkillResult(success: false, message: "Skill not found"))
            return
        }
        
        var result = SkillResult(success: true, message: "\(user.name) used \(skill.name)!")
        result.damage = skill.damage
        result.energyCost = skill.energyCost
        
        // Apply effect based on skill type
        switch skill.effectType {
        case .damage:
            result.damage = skill.damage
        case .buff:
            result.buffApplied = true
            result.buffDuration = 5.0
        case .debuff:
            result.debuffApplied = true
            result.debuffDuration = 3.0
        case .heal:
            result.healAmount = skill.damage
        case .movement:
            result.movementEffect = true
        case .control:
            result.controlEffect = true
            result.controlDuration = 2.0
        }
        
        completion(result)
    }
    
    // MARK: - Server-Authoritative Hit Validation (Anti-Cheat)
    
    /// Validates a hit request on the server-side
    /// Returns true if the hit is valid and should be processed
    static func validateHitRequest(
        attackerId: String,
        defenderId: String,
        attackerPosition: WorldPosition,
        defenderPosition: WorldPosition,
        timestamp: TimeInterval,
        lastKnownPositions: [String: (position: WorldPosition, timestamp: TimeInterval)]
    ) -> HitValidationResult {
        
        // Check 1: Distance validation (prevent long-range cheats)
        let distance = attackerPosition.distance(to: defenderPosition)
        let maxAttackRange: Double = 50.0 // Maximum attack range in world units
        
        if distance > maxAttackRange {
            return HitValidationResult(valid: false, reason: .distanceTooFar, confidence: 0.0)
        }
        
        // Check 2: Rate limiting (prevent attack spam)
        let minTimeBetweenAttacks: TimeInterval = 0.3 // 300ms minimum
        // In a real implementation, we'd check against stored attack timestamps
        
        // Check 3: Position reconciliation
        // Compare reported positions with server-known positions
        var positionConfidence: Double = 1.0
        
        if let lastKnown = lastKnownPositions[attackerId] {
            let timeDelta = timestamp - lastKnown.timestamp
            let maxSpeed: Double = 100.0 // Maximum movement speed
            let maxPossibleDistance = maxSpeed * timeDelta
            let actualDistance = attackerPosition.distance(to: lastKnown.position)
            
            if actualDistance > maxPossibleDistance * 1.5 { // 50% tolerance
                positionConfidence = 0.5 // Suspicious but not definitive
            }
            if actualDistance > maxPossibleDistance * 3.0 {
                return HitValidationResult(valid: false, reason: .positionMismatch, confidence: 0.0)
            }
        }
        
        // Check 4: Cooldown validation
        // Verify ability cooldowns haven't been bypassed (would need skill state)
        
        return HitValidationResult(valid: true, reason: nil, confidence: positionConfidence)
    }
    
    // MARK: - Damage Formula
    
    /// Calculate final damage with all modifiers
    static func calculateFinalDamage(
        baseDamage: Double,
        attackerStats: BirdStats,
        defenderStats: BirdStats,
        attackerBuffs: [ActiveBuff],
        defenderBuffs: [ActiveBuff],
        isBackstab: Bool = false,
        isCritical: Bool = false,
        timeOfDay: TimeOfDay = .day,
        attackerType: BirdType? = nil
    ) -> DamageCalculation {
        
        var damage = baseDamage
        var breakdown: [String] = ["Base: \(Int(baseDamage))"]
        
        // Attack stat bonus
        let attackBonus = attackerStats.attack * 0.5
        damage += attackBonus
        breakdown.append("ATK Bonus: +\(Int(attackBonus))")
        
        // Defense reduction
        let defenseReduction = defenderStats.defense * 0.3
        damage -= defenseReduction
        breakdown.append("DEF Reduction: -\(Int(defenseReduction))")
        
        // Apply attack buffs
        for buff in attackerBuffs where buff.type == .attackBoost {
            let buffBonus = damage * buff.multiplier
            damage += buffBonus
            breakdown.append("ATK Buff: +\(Int(buffBonus))")
        }
        
        // Apply defense buffs
        for buff in defenderBuffs where buff.type == .defenseBoost {
            let buffReduction = damage * buff.multiplier
            damage -= buffReduction
            breakdown.append("DEF Buff: -\(Int(buffReduction))")
        }
        
        // Backstab bonus (for Owl and Crow)
        if isBackstab {
            let backstabBonus = damage * 0.5
            damage += backstabBonus
            breakdown.append("Backstab: +\(Int(backstabBonus))")
        }
        
        // Critical hit
        if isCritical {
            let critBonus = damage * 0.75
            damage += critBonus
            breakdown.append("CRITICAL: +\(Int(critBonus))")
        }
        
        // Owl night bonus
        if attackerType == .owl && timeOfDay == .night {
            let nightBonus = damage * 0.25
            damage += nightBonus
            breakdown.append("Night Hunter: +\(Int(nightBonus))")
        }
        
        // Minimum damage
        damage = max(1, damage)
        
        return DamageCalculation(
            finalDamage: damage,
            isCritical: isCritical,
            breakdown: breakdown
        )
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
    var bleedApplied: Bool = false
    var bleedDamage: Double = 0
    var bleedDuration: Double = 0
}

struct SkillResult {
    var success: Bool
    var message: String
    var damage: Double = 0
    var energyCost: Double = 0
    var buffApplied: Bool = false
    var buffDuration: Double = 0
    var debuffApplied: Bool = false
    var debuffDuration: Double = 0
    var healAmount: Double = 0
    var movementEffect: Bool = false
    var controlEffect: Bool = false
    var controlDuration: Double = 0
}

struct HitValidationResult {
    let valid: Bool
    let reason: HitValidationFailReason?
    let confidence: Double // 0.0 to 1.0
}

enum HitValidationFailReason: String {
    case distanceTooFar = "Target out of range"
    case rateLimitExceeded = "Attack too fast"
    case positionMismatch = "Position mismatch"
    case cooldownNotReady = "Ability on cooldown"
    case invalidTarget = "Invalid target"
}

struct DamageCalculation {
    let finalDamage: Double
    let isCritical: Bool
    let breakdown: [String]
}

struct ActiveBuff: Identifiable {
    let id: String
    let type: BuffType
    let multiplier: Double
    let expiresAt: Date
    
    var isExpired: Bool { Date() >= expiresAt }
}

enum BuffType {
    case none
    case attackBoost
    case speedBoost
    case defenseBoost
    case energyRegen
    case healthRegen
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

// MARK: - Status Effects

struct StatusEffect: Identifiable {
    let id: String
    let type: StatusEffectType
    let damage: Double
    let duration: TimeInterval
    let tickRate: TimeInterval
    let appliedAt: Date
    
    var isExpired: Bool {
        Date().timeIntervalSince(appliedAt) >= duration
    }
    
    var ticksRemaining: Int {
        let elapsed = Date().timeIntervalSince(appliedAt)
        let remaining = duration - elapsed
        return max(0, Int(remaining / tickRate))
    }
}

enum StatusEffectType: String, CaseIterable {
    case bleed = "Bleed"
    case poison = "Poison"
    case burn = "Burn"
    case slow = "Slow"
    case stun = "Stun"
    case blind = "Blind"
    case silence = "Silence"
    
    var emoji: String {
        switch self {
        case .bleed: return "🩸"
        case .poison: return "☠️"
        case .burn: return "🔥"
        case .slow: return "🐌"
        case .stun: return "💫"
        case .blind: return "🌑"
        case .silence: return "🤐"
        }
    }
    
    var color: String {
        switch self {
        case .bleed: return "red"
        case .poison: return "green"
        case .burn: return "orange"
        case .slow: return "blue"
        case .stun: return "yellow"
        case .blind: return "gray"
        case .silence: return "purple"
        }
    }
}
