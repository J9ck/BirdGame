//
//  GameState.swift
//  BirdGame3
//
//  Global game state management
//

import Foundation
import SwiftUI

enum GameScreen {
    case mainMenu
    case login
    case lobby
    case characterSelect
    case game
    case results
    case shop
    case settings
    case openWorld
    case nestBuilder
}

enum GameMode {
    case quickMatch
    case arcade
    case training
    case squadBattle
    case openWorld
    case nestWars
    case battleRoyale
}

class GameState: ObservableObject {
    @Published var currentScreen: GameScreen = .mainMenu
    @Published var selectedBird: BirdType = .pigeon
    @Published var opponentBird: BirdType = .eagle
    @Published var gameMode: GameMode = .quickMatch
    @Published var playerWon: Bool = false
    @Published var arcadeLevel: Int = 1
    @Published var playerStats: PlayerStats
    @Published var lastMatchDuration: TimeInterval = 0
    @Published var lastMatchDamageDealt: Double = 0
    @Published var lastMatchDamageReceived: Double = 0
    @Published var lastBattleReward: BattleReward?
    @Published var levelUpRewards: [LevelUpReward] = []
    
    // Fun fake stats
    @Published var fakeOnlinePlayers: Int = Int.random(in: 42069...99999)
    @Published var fakeServerPing: Int = Int.random(in: 1...999)
    
    // Persistence key
    private let statsKey = "birdgame3_playerStats"
    
    init() {
        // Load player stats
        if let data = UserDefaults.standard.data(forKey: statsKey),
           let stats = try? JSONDecoder().decode(PlayerStats.self, from: data) {
            self.playerStats = stats
        } else {
            self.playerStats = PlayerStats()
        }
    }
    
    func navigateTo(_ screen: GameScreen) {
        currentScreen = screen
    }
    
    func startQuickMatch() {
        gameMode = .quickMatch
        opponentBird = BirdType.allCases.randomElement() ?? .pigeon
        navigateTo(.characterSelect)
    }
    
    func startArcade() {
        gameMode = .arcade
        arcadeLevel = max(1, playerStats.highestArcadeStage)
        opponentBird = BirdType.allCases[min(arcadeLevel - 1, BirdType.allCases.count - 1)]
        navigateTo(.characterSelect)
    }
    
    func startTraining() {
        gameMode = .training
        opponentBird = .pigeon
        navigateTo(.characterSelect)
    }
    
    func openShop() {
        navigateTo(.shop)
    }
    
    func openSettings() {
        navigateTo(.settings)
    }
    
    func openLobby() {
        // Check if logged in first
        if AccountManager.shared.isLoggedIn {
            navigateTo(.lobby)
        } else {
            navigateTo(.login)
        }
    }
    
    func openOpenWorld() {
        if AccountManager.shared.isLoggedIn {
            navigateTo(.openWorld)
        } else {
            navigateTo(.login)
        }
    }
    
    func startBattle() {
        // Start voice commentary
        VoiceChatManager.shared.startBattleCommentary(playerBird: selectedBird, opponentBird: opponentBird)
        navigateTo(.game)
    }
    
    func endBattle(playerWon: Bool, duration: TimeInterval, damageDealt: Double, damageReceived: Double) {
        self.playerWon = playerWon
        self.lastMatchDuration = duration
        self.lastMatchDamageDealt = damageDealt
        self.lastMatchDamageReceived = damageReceived
        
        // Stop voice commentary
        VoiceChatManager.shared.stopBattleCommentary()
        
        // Announce result
        VoiceChatManager.shared.commentOnEvent(playerWon ? .playerWin(isPerfect: damageReceived == 0) : .playerLose)
        
        // Check for perfect win
        let isPerfect = damageReceived == 0 && playerWon
        
        // Update stats
        if playerWon {
            playerStats.wins += 1
            playerStats.totalDamageDealt += damageDealt
            if isPerfect {
                playerStats.perfectWins += 1
            }
            if gameMode == .arcade {
                arcadeLevel += 1
                if arcadeLevel > playerStats.highestArcadeStage {
                    playerStats.highestArcadeStage = arcadeLevel
                }
            }
            // Track wins per bird
            playerStats.addWin(for: selectedBird)
        } else {
            playerStats.losses += 1
        }
        playerStats.matchesPlayed += 1
        
        // Grant currency rewards
        let reward = CurrencyManager.shared.grantBattleRewards(
            won: playerWon,
            isPerfect: isPerfect,
            arcadeStage: gameMode == .arcade ? arcadeLevel : nil,
            isFirstWinOfDay: playerStats.isFirstWinOfDay() && playerWon
        )
        lastBattleReward = reward
        
        // Grant XP and check for level ups
        let xp = PrestigeManager.shared.calculateBattleXP(
            won: playerWon,
            isPerfect: isPerfect,
            matchDuration: duration,
            arcadeStage: gameMode == .arcade ? arcadeLevel : nil
        )
        levelUpRewards = PrestigeManager.shared.addXP(xp)
        
        // Mark first win of day
        if playerWon {
            playerStats.recordWinToday()
        }
        
        // Save stats
        saveStats()
        
        navigateTo(.results)
    }
    
    func returnToMenu() {
        lastBattleReward = nil
        levelUpRewards = []
        navigateTo(.mainMenu)
        refreshFakeStats()
    }
    
    func playAgain() {
        lastBattleReward = nil
        levelUpRewards = []
        
        if gameMode == .arcade && playerWon {
            if arcadeLevel <= BirdType.allCases.count {
                opponentBird = BirdType.allCases[min(arcadeLevel - 1, BirdType.allCases.count - 1)]
            } else {
                // Loop back with harder versions
                opponentBird = BirdType.allCases.randomElement() ?? .eagle
            }
        } else if gameMode == .quickMatch {
            opponentBird = BirdType.allCases.randomElement() ?? .pigeon
        }
        
        // Restart voice commentary
        VoiceChatManager.shared.startBattleCommentary(playerBird: selectedBird, opponentBird: opponentBird)
        navigateTo(.game)
    }
    
    private func refreshFakeStats() {
        fakeOnlinePlayers = Int.random(in: 42069...99999)
        fakeServerPing = Int.random(in: 1...999)
    }
    
    private func saveStats() {
        if let data = try? JSONEncoder().encode(playerStats) {
            UserDefaults.standard.set(data, forKey: statsKey)
        }
    }
    
    /// Reset player stats to default values
    func resetPlayerStats() {
        playerStats = PlayerStats()
        arcadeLevel = 1
        saveStats()
    }
}
