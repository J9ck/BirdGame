//
//  BirdTypes.swift
//  BirdGame3
//
//  All the iconic birds, each more OP than the last
//

import Foundation

enum BirdType: String, CaseIterable, Identifiable, Codable {
    case pigeon
    case hummingbird
    case eagle
    case crow
    case pelican
    case owl
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .pigeon: return "Pigeon"
        case .hummingbird: return "Hummingbird"
        case .eagle: return "Eagle"
        case .crow: return "Crow"
        case .pelican: return "Pelican"
        case .owl: return "Owl"
        }
    }
    
    var emoji: String {
        switch self {
        case .pigeon: return "🐦"
        case .hummingbird: return "🌸" // No hummingbird emoji, using flower they like
        case .eagle: return "🦅"
        case .crow: return "🦜" // Close enough
        case .pelican: return "🦆" // Also close enough
        case .owl: return "🦉"
        }
    }
    
    var flavorText: String {
        switch self {
        case .pigeon:
            return "The iconic main character. Coo coo mothercooo."
        case .hummingbird:
            return "Has been nerfed 47 times. Still OP. Devs pls."
        case .eagle:
            return "FREEDOM INTENSIFIES. Bald and beautiful."
        case .crow:
            return "Will steal your lunch AND your win. Caw caw."
        case .pelican:
            return "Thicc boy with a pocket dimension for a mouth."
        case .owl:
            return "The silent night hunter. Who? WHO? That's classified."
        }
    }
    
    var abilityName: String {
        switch self {
        case .pigeon: return "Breadcrumb Frenzy"
        case .hummingbird: return "Hover Strike"
        case .eagle: return "Talon Dive"
        case .crow: return "Shiny Distraction"
        case .pelican: return "Fish Slap"
        case .owl: return "Silent Strike"
        }
    }
    
    var abilityDescription: String {
        switch self {
        case .pigeon:
            return "Gains temporary speed boost and attack power. Spam pecks incoming!"
        case .hummingbird:
            return "Rapid multi-hit attack that hits 5 times. Absolutely broken."
        case .eagle:
            return "Devastating aerial dive dealing massive damage. MURICA!"
        case .crow:
            return "Throws a shiny object that stuns the opponent briefly."
        case .pelican:
            return "Slaps opponent with a fish, dealing damage and knockback."
        case .owl:
            return "Swoops silently from behind, dealing bonus damage and applying bleed."
        }
    }
    
    var baseStats: BirdStats {
        switch self {
        case .pigeon:
            return BirdStats(
                health: 100,
                maxHealth: 100,
                attack: 12,
                defense: 10,
                speed: 10,
                abilityCooldown: 5.0,
                abilityDamage: 20,
                featherDensity: 847,
                cooPower: "Maximum",
                wingspan: "Perfectly Average",
                intimidationLevel: "Surprisingly High"
            )
        case .hummingbird:
            return BirdStats(
                health: 70,
                maxHealth: 70,
                attack: 8,
                defense: 5,
                speed: 20,
                abilityCooldown: 3.0,
                abilityDamage: 8, // x5 hits = 40 total
                featherDensity: 2847,
                cooPower: "N/A (Hums Instead)",
                wingspan: "Smol but Deadly",
                intimidationLevel: "DON'T LET THE SIZE FOOL YOU"
            )
        case .eagle:
            return BirdStats(
                health: 120,
                maxHealth: 120,
                attack: 18,
                defense: 12,
                speed: 6,
                abilityCooldown: 8.0,
                abilityDamage: 45,
                featherDensity: 420,
                cooPower: "SCREEEEE",
                wingspan: "FREEDOM UNITS",
                intimidationLevel: "🇺🇸🇺🇸🇺🇸"
            )
        case .crow:
            return BirdStats(
                health: 85,
                maxHealth: 85,
                attack: 10,
                defense: 8,
                speed: 14,
                abilityCooldown: 6.0,
                abilityDamage: 5, // + stun
                featherDensity: 666,
                cooPower: "Caw Caw",
                wingspan: "Mysterious",
                intimidationLevel: "Knows Your Secrets"
            )
        case .pelican:
            return BirdStats(
                health: 150,
                maxHealth: 150,
                attack: 14,
                defense: 15,
                speed: 5,
                abilityCooldown: 7.0,
                abilityDamage: 25,
                featherDensity: 1337,
                cooPower: "Gulp",
                wingspan: "CHONKY",
                intimidationLevel: "That Beak Tho"
            )
        case .owl:
            return BirdStats(
                health: 95,
                maxHealth: 95,
                attack: 15,
                defense: 9,
                speed: 11,
                abilityCooldown: 9.0,
                abilityDamage: 35, // + bleed effect
                featherDensity: 1024,
                cooPower: "Hoo Hoo",
                wingspan: "Silent Death",
                intimidationLevel: "The Night Watches Back"
            )
        }
    }
    
    var color: String {
        switch self {
        case .pigeon: return "gray"
        case .hummingbird: return "green"
        case .eagle: return "brown"
        case .crow: return "black"
        case .pelican: return "white"
        case .owl: return "tawny"
        }
    }
}

// MARK: - Bird Skill

/// Represents an active skill for a bird archetype
struct BirdSkill: Identifiable {
    let id: String
    let name: String
    let description: String
    let cooldown: TimeInterval
    let energyCost: Double
    let damage: Double
    let effectType: SkillEffectType
    let icon: String
    
    enum SkillEffectType {
        case damage
        case buff
        case debuff
        case heal
        case movement
        case control
    }
}

extension BirdType {
    /// Returns all active skills for this bird type (3-4 skills per bird)
    var skills: [BirdSkill] {
        switch self {
        case .pigeon:
            return [
                BirdSkill(id: "pigeon_peck", name: "Rapid Peck", description: "Quick pecking combo", cooldown: 2.0, energyCost: 10, damage: 15, effectType: .damage, icon: "⚡"),
                BirdSkill(id: "pigeon_frenzy", name: "Breadcrumb Frenzy", description: "Speed and attack boost", cooldown: 5.0, energyCost: 25, damage: 0, effectType: .buff, icon: "🍞"),
                BirdSkill(id: "pigeon_coo", name: "Intimidating Coo", description: "Reduces enemy defense", cooldown: 8.0, energyCost: 20, damage: 0, effectType: .debuff, icon: "🗣️"),
                BirdSkill(id: "pigeon_flutter", name: "Evasive Flutter", description: "Quick dodge movement", cooldown: 3.0, energyCost: 15, damage: 0, effectType: .movement, icon: "💨")
            ]
        case .hummingbird:
            return [
                BirdSkill(id: "hummingbird_dart", name: "Needle Dart", description: "Precise beak strike", cooldown: 1.5, energyCost: 8, damage: 12, effectType: .damage, icon: "🎯"),
                BirdSkill(id: "hummingbird_hover", name: "Hover Strike", description: "5-hit rapid combo", cooldown: 3.0, energyCost: 30, damage: 8, effectType: .damage, icon: "🌀"),
                BirdSkill(id: "hummingbird_blur", name: "Speed Blur", description: "Massive speed boost", cooldown: 6.0, energyCost: 35, damage: 0, effectType: .buff, icon: "⚡"),
                BirdSkill(id: "hummingbird_drain", name: "Nectar Drain", description: "Steal enemy energy", cooldown: 10.0, energyCost: 20, damage: 5, effectType: .debuff, icon: "🌸")
            ]
        case .eagle:
            return [
                BirdSkill(id: "eagle_swipe", name: "Talon Swipe", description: "Powerful claw attack", cooldown: 3.0, energyCost: 20, damage: 25, effectType: .damage, icon: "🦅"),
                BirdSkill(id: "eagle_dive", name: "Talon Dive", description: "Devastating aerial strike", cooldown: 8.0, energyCost: 40, damage: 45, effectType: .damage, icon: "⬇️"),
                BirdSkill(id: "eagle_screech", name: "Freedom Screech", description: "Stuns nearby enemies", cooldown: 12.0, energyCost: 35, damage: 10, effectType: .control, icon: "📢"),
                BirdSkill(id: "eagle_soar", name: "Majestic Soar", description: "Gain altitude rapidly", cooldown: 5.0, energyCost: 25, damage: 0, effectType: .movement, icon: "🆙")
            ]
        case .crow:
            return [
                BirdSkill(id: "crow_peck", name: "Shadow Peck", description: "Dark-infused strike", cooldown: 2.0, energyCost: 12, damage: 18, effectType: .damage, icon: "🌑"),
                BirdSkill(id: "crow_shiny", name: "Shiny Distraction", description: "Stuns opponent", cooldown: 6.0, energyCost: 25, damage: 5, effectType: .control, icon: "✨"),
                BirdSkill(id: "crow_mimic", name: "Mimic Call", description: "Confuses enemies", cooldown: 10.0, energyCost: 30, damage: 0, effectType: .debuff, icon: "🎭"),
                BirdSkill(id: "crow_vanish", name: "Murder's Vanish", description: "Brief invisibility", cooldown: 15.0, energyCost: 40, damage: 0, effectType: .movement, icon: "👻")
            ]
        case .pelican:
            return [
                BirdSkill(id: "pelican_chomp", name: "Pouch Chomp", description: "Bite with large beak", cooldown: 2.5, energyCost: 15, damage: 20, effectType: .damage, icon: "🐟"),
                BirdSkill(id: "pelican_slap", name: "Fish Slap", description: "Knockback attack", cooldown: 7.0, energyCost: 30, damage: 25, effectType: .damage, icon: "👋"),
                BirdSkill(id: "pelican_belly", name: "Belly Bounce", description: "Absorb damage", cooldown: 8.0, energyCost: 20, damage: 0, effectType: .buff, icon: "🛡️"),
                BirdSkill(id: "pelican_gulp", name: "Massive Gulp", description: "Heal by eating", cooldown: 12.0, energyCost: 35, damage: 0, effectType: .heal, icon: "❤️‍🩹")
            ]
        case .owl:
            return [
                BirdSkill(id: "owl_talon", name: "Silent Talon", description: "Quiet deadly strike", cooldown: 2.0, energyCost: 15, damage: 22, effectType: .damage, icon: "🦉"),
                BirdSkill(id: "owl_strike", name: "Silent Strike", description: "Backstab with bleed", cooldown: 9.0, energyCost: 35, damage: 35, effectType: .damage, icon: "🩸"),
                BirdSkill(id: "owl_gaze", name: "Hypnotic Gaze", description: "Slow enemy movement", cooldown: 10.0, energyCost: 30, damage: 0, effectType: .control, icon: "👁️"),
                BirdSkill(id: "owl_wisdom", name: "Wisdom Aura", description: "Regen health over time", cooldown: 15.0, energyCost: 40, damage: 0, effectType: .heal, icon: "📚")
            ]
        }
    }
    
    /// Passive ability for this bird type
    var passive: (name: String, description: String) {
        switch self {
        case .pigeon:
            return ("Street Smarts", "+10% XP from all sources")
        case .hummingbird:
            return ("Hypermetabolism", "Energy regenerates 50% faster")
        case .eagle:
            return ("Apex Predator", "+15% damage to prey below 50% HP")
        case .crow:
            return ("Collector's Eye", "Find 20% more shiny objects")
        case .pelican:
            return ("Thick Skin", "Take 10% less damage from all sources")
        case .owl:
            return ("Night Hunter", "+25% damage and stealth at night")
        }
    }
}
