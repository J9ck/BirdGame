//
//  GameView.swift
//  BirdGame3
//
//  Where the epic bird battles unfold
//

import SwiftUI
import SpriteKit

struct GameView: View {
    @EnvironmentObject var gameState: GameState
    @State private var scene: GameScene?
    @StateObject private var gameController = GameController()
    
    var body: some View {
        ZStack {
            // SpriteKit Game Scene
            if let scene = scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
                    .onAppear {
                        createScene()
                    }
            }
            
            // UI Overlay
            VStack {
                Spacer()
                
                // Control buttons
                GameControlsView(controller: gameController)
            }
        }
        .onAppear {
            createScene()
        }
    }
    
    private func createScene() {
        let newScene = GameScene(size: UIScreen.main.bounds.size)
        newScene.scaleMode = .aspectFill
        newScene.playerType = gameState.selectedBird
        newScene.opponentType = gameState.opponentBird
        newScene.isTrainingMode = gameState.gameMode == .training
        newScene.gameDelegate = gameController
        gameController.gameState = gameState
        scene = newScene
    }
}

// MARK: - Game Controller

class GameController: ObservableObject, GameSceneDelegate {
    weak var gameState: GameState?
    weak var scene: GameScene?
    
    func battleDidEnd(playerWon: Bool, duration: TimeInterval, damageDealt: Double, damageReceived: Double) {
        DispatchQueue.main.async { [weak self] in
            self?.gameState?.endBattle(
                playerWon: playerWon,
                duration: duration,
                damageDealt: damageDealt,
                damageReceived: damageReceived
            )
        }
    }
    
    func attack() {
        scene?.playerAttack()
    }
    
    func useAbility() {
        scene?.playerUseAbility()
    }
    
    func moveLeft() {
        scene?.movePlayer(direction: -1)
    }
    
    func moveRight() {
        scene?.movePlayer(direction: 1)
    }
    
    func block(_ blocking: Bool) {
        scene?.playerBlock(blocking)
    }
}

// MARK: - Game Controls View

struct GameControlsView: View {
    @ObservedObject var controller: GameController
    @State private var isBlocking = false
    
    var body: some View {
        HStack(spacing: 40) {
            // Movement controls
            VStack(spacing: 10) {
                HStack(spacing: 20) {
                    // Left button
                    ControlButton(icon: "←", color: .gray) {
                        controller.moveLeft()
                    }
                    
                    // Right button
                    ControlButton(icon: "→", color: .gray) {
                        controller.moveRight()
                    }
                }
                
                Text("MOVE")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Action controls
            VStack(spacing: 10) {
                HStack(spacing: 15) {
                    // Block button (hold)
                    ControlButton(icon: "🛡️", color: .blue) {
                        // Handle in gesture
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !isBlocking {
                                    isBlocking = true
                                    controller.block(true)
                                }
                            }
                            .onEnded { _ in
                                isBlocking = false
                                controller.block(false)
                            }
                    )
                    
                    // Attack button
                    ControlButton(icon: "👊", color: .red) {
                        controller.attack()
                    }
                    
                    // Ability button
                    ControlButton(icon: "✨", color: .yellow) {
                        controller.useAbility()
                    }
                }
                
                Text("ACTIONS")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 40)
    }
}

// MARK: - Control Button

struct ControlButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Text(icon)
                .font(.system(size: 24))
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(color.opacity(isPressed ? 0.8 : 0.5))
                        .shadow(color: color.opacity(0.5), radius: 5)
                )
                .overlay(
                    Circle()
                        .stroke(color, lineWidth: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.2), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    GameView()
        .environmentObject(GameState())
}
