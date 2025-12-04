//
//  BirdGame3App.swift
//  BirdGame3
//
//  The iconic Bird Game 3 - where pigeons rise up and hummingbirds are still OP
//

import SwiftUI

@main
struct BirdGame3App: App {
    @StateObject private var gameState = GameState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameState)
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        NavigationStack {
            switch gameState.currentScreen {
            case .mainMenu:
                MainMenuView()
            case .characterSelect:
                CharacterSelectView()
            case .game:
                GameView()
            case .results:
                ResultsView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: gameState.currentScreen)
    }
}
