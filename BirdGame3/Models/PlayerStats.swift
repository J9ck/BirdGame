//
//  PlayerStats.swift
//  BirdGame3
//
//  Tracking your legendary bird combat career
//

import Foundation

class PlayerStats: ObservableObject, Codable {
    @Published var matchesPlayed: Int = 0
    @Published var wins: Int = 0
    @Published var losses: Int = 0
    @Published var totalDamageDealt: Double = 0
    @Published var favoriteCharacter: BirdType = .pigeon
    @Published var pecksLanded: Int = 0
    @Published var abilitiesUsed: Int = 0
    @Published var perfectWins: Int = 0
    @Published var highestArcadeStage: Int = 1
    @Published var winsPerBird: [String: Int] = [:]
    @Published var lastWinDate: Date?
    
    // Codable conformance
    enum CodingKeys: String, CodingKey {
        case matchesPlayed, wins, losses, totalDamageDealt
        case favoriteCharacter, pecksLanded, abilitiesUsed, perfectWins
        case highestArcadeStage, winsPerBird, lastWinDate
    }
    
    init() {}
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        matchesPlayed = try container.decode(Int.self, forKey: .matchesPlayed)
        wins = try container.decode(Int.self, forKey: .wins)
        losses = try container.decode(Int.self, forKey: .losses)
        totalDamageDealt = try container.decode(Double.self, forKey: .totalDamageDealt)
        favoriteCharacter = try container.decode(BirdType.self, forKey: .favoriteCharacter)
        pecksLanded = try container.decode(Int.self, forKey: .pecksLanded)
        abilitiesUsed = try container.decode(Int.self, forKey: .abilitiesUsed)
        perfectWins = try container.decode(Int.self, forKey: .perfectWins)
        highestArcadeStage = try container.decode(Int.self, forKey: .highestArcadeStage)
        winsPerBird = try container.decode([String: Int].self, forKey: .winsPerBird)
        lastWinDate = try container.decodeIfPresent(Date.self, forKey: .lastWinDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(matchesPlayed, forKey: .matchesPlayed)
        try container.encode(wins, forKey: .wins)
        try container.encode(losses, forKey: .losses)
        try container.encode(totalDamageDealt, forKey: .totalDamageDealt)
        try container.encode(favoriteCharacter, forKey: .favoriteCharacter)
        try container.encode(pecksLanded, forKey: .pecksLanded)
        try container.encode(abilitiesUsed, forKey: .abilitiesUsed)
        try container.encode(perfectWins, forKey: .perfectWins)
        try container.encode(highestArcadeStage, forKey: .highestArcadeStage)
        try container.encode(winsPerBird, forKey: .winsPerBird)
        try container.encode(lastWinDate, forKey: .lastWinDate)
    }
    
    // MARK: - Win Tracking
    
    func addWin(for bird: BirdType) {
        winsPerBird[bird.rawValue, default: 0] += 1
        updateFavoriteCharacter()
    }
    
    func getWins(for bird: BirdType) -> Int {
        winsPerBird[bird.rawValue] ?? 0
    }
    
    private func updateFavoriteCharacter() {
        if let mostWins = winsPerBird.max(by: { $0.value < $1.value }),
           let bird = BirdType(rawValue: mostWins.key) {
            favoriteCharacter = bird
        }
    }
    
    // MARK: - Daily Tracking
    
    func isFirstWinOfDay() -> Bool {
        guard let lastWin = lastWinDate else { return true }
        return !Calendar.current.isDateInToday(lastWin)
    }
    
    func recordWinToday() {
        lastWinDate = Date()
    }
    
    // MARK: - Meme Stats
    
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
