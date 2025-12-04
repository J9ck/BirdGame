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
    case characterSelect
    case game
    case results
}

enum GameMode {
    case quickMatch
    case arcade
    case training
}

class GameState: ObservableObject {
    @Published var currentScreen: GameScreen = .mainMenu
    @Published var selectedBird: BirdType = .pigeon
    @Published var opponentBird: BirdType = .eagle
    @Published var gameMode: GameMode = .quickMatch
    @Published var playerWon: Bool = false
    @Published var arcadeLevel: Int = 1
    @Published var playerStats = PlayerStats()
    @Published var lastMatchDuration: TimeInterval = 0
    @Published var lastMatchDamageDealt: Double = 0
    @Published var lastMatchDamageReceived: Double = 0
    
    // Fun fake stats
    @Published var fakeOnlinePlayers: Int = Int.random(in: 42069...99999)
    @Published var fakeServerPing: Int = Int.random(in: 1...999)
    
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
        arcadeLevel = 1
        opponentBird = BirdType.allCases[min(arcadeLevel - 1, BirdType.allCases.count - 1)]
        navigateTo(.characterSelect)
    }
    
    func startTraining() {
        gameMode = .training
        opponentBird = .pigeon
        navigateTo(.characterSelect)
    }
    
    func startBattle() {
        navigateTo(.game)
    }
    
    func endBattle(playerWon: Bool, duration: TimeInterval, damageDealt: Double, damageReceived: Double) {
        self.playerWon = playerWon
        self.lastMatchDuration = duration
        self.lastMatchDamageDealt = damageDealt
        self.lastMatchDamageReceived = damageReceived
        
        if playerWon {
            playerStats.wins += 1
            playerStats.totalDamageDealt += damageDealt
            if gameMode == .arcade {
                arcadeLevel += 1
            }
        } else {
            playerStats.losses += 1
        }
        playerStats.matchesPlayed += 1
        
        navigateTo(.results)
    }
    
    func returnToMenu() {
        navigateTo(.mainMenu)
        refreshFakeStats()
    }
    
    func playAgain() {
        if gameMode == .arcade && playerWon {
            if arcadeLevel <= BirdType.allCases.count {
                opponentBird = BirdType.allCases[min(arcadeLevel - 1, BirdType.allCases.count - 1)]
            }
        } else if gameMode == .quickMatch {
            opponentBird = BirdType.allCases.randomElement() ?? .pigeon
        }
        navigateTo(.game)
    }
    
    private func refreshFakeStats() {
        fakeOnlinePlayers = Int.random(in: 42069...99999)
        fakeServerPing = Int.random(in: 1...999)
    }
}
