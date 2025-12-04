//
//  PlayerStats.swift
//  BirdGame3
//
//  Tracking your legendary bird combat career
//

import Foundation

class PlayerStats: ObservableObject {
    @Published var matchesPlayed: Int = 0
    @Published var wins: Int = 0
    @Published var losses: Int = 0
    @Published var totalDamageDealt: Double = 0
    @Published var favoriteCharacter: BirdType = .pigeon
    @Published var pecksLanded: Int = 0
    @Published var abilitiesUsed: Int = 0
    @Published var perfectWins: Int = 0
    
    // Meme stats
    var breadcrumbsConsumed: Int {
        return Int.random(in: 10000...99999)
    }
    
    var timesCalledOP: Int {
        return wins * Int.random(in: 3...10)
    }
    
    var saltLevel: String {
        if losses > wins {
            return "MAXIMUM 🧂🧂🧂"
        } else if wins > losses * 2 {
            return "Zero (ur just built different)"
        } else {
            return "Moderate"
        }
    }
    
    var winRate: Double {
        guard matchesPlayed > 0 else { return 0 }
        return Double(wins) / Double(matchesPlayed) * 100
    }
    
    var rank: String {
        switch wins {
        case 0:
            return "Egg 🥚"
        case 1...5:
            return "Hatchling 🐣"
        case 6...10:
            return "Fledgling 🐤"
        case 11...20:
            return "Skyward Scrub 🐦"
        case 21...50:
            return "Wing Commander 🦅"
        case 51...100:
            return "Talon Terror 🦉"
        default:
            return "LEGENDARY BIRD GOD 👑🦜"
        }
    }
}
