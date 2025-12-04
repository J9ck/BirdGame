//
//  BirdTypes.swift
//  BirdGame3
//
//  All the iconic birds, each more OP than the last
//

import Foundation

enum BirdType: String, CaseIterable, Identifiable {
    case pigeon
    case hummingbird
    case eagle
    case crow
    case pelican
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .pigeon: return "Pigeon"
        case .hummingbird: return "Hummingbird"
        case .eagle: return "Eagle"
        case .crow: return "Crow"
        case .pelican: return "Pelican"
        }
    }
    
    var emoji: String {
        switch self {
        case .pigeon: return "🐦"
        case .hummingbird: return "🌸" // No hummingbird emoji, using flower they like
        case .eagle: return "🦅"
        case .crow: return "🦜" // Close enough
        case .pelican: return "🦆" // Also close enough
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
        }
    }
    
    var abilityName: String {
        switch self {
        case .pigeon: return "Breadcrumb Frenzy"
        case .hummingbird: return "Hover Strike"
        case .eagle: return "Talon Dive"
        case .crow: return "Shiny Distraction"
        case .pelican: return "Fish Slap"
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
        }
    }
    
    var color: String {
        switch self {
        case .pigeon: return "gray"
        case .hummingbird: return "green"
        case .eagle: return "brown"
        case .crow: return "black"
        case .pelican: return "white"
        }
    }
}
