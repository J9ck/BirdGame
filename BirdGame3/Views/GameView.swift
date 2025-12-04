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
    @State private var isPaused: Bool = false
    @State private var showPauseSettings: Bool = false
    
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
            
            // UI Overlay - Wolf-style controls
            VStack {
                // Top bar with pause button
                HStack {
                    // Pause button
                    Button(action: pauseGame) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.7))
                            .shadow(color: .black.opacity(0.5), radius: 2)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                }
                
                Spacer()
                
                // Control buttons (Wolf style)
                WolfStyleControlsView(controller: gameController)
            }
            
            // Pause menu overlay
            if isPaused {
                PauseMenuView(
                    isPaused: $isPaused,
                    showSettings: $showPauseSettings,
                    onResume: resumeGame,
                    onQuit: {
                        scene?.isPaused = false
                        VoiceChatManager.shared.stopBattleCommentary()
                    }
                )
            }
            
            // In-game settings overlay
            if showPauseSettings {
                InGameSettingsView(isPresented: $showPauseSettings)
            }
        }
        .onAppear {
            createScene()
        }
        .onDisappear {
            // Clean up when leaving game view
            scene?.isPaused = true
            VoiceChatManager.shared.stopBattleCommentary()
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
        gameController.scene = newScene
        scene = newScene
    }
    
    private func pauseGame() {
        guard !isPaused else { return }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        scene?.isPaused = true
        VoiceChatManager.shared.stop()
        
        withAnimation(.easeInOut(duration: 0.2)) {
            isPaused = true
        }
    }
    
    private func resumeGame() {
        scene?.isPaused = false
        
        // Resume voice commentary if enabled
        if VoiceChatManager.shared.isEnabled {
            VoiceChatManager.shared.speak("And we're back! Let's go!", priority: .normal)
        }
    }
}

// MARK: - Game Controller

class GameController: ObservableObject, GameSceneDelegate {
    weak var gameState: GameState?
    weak var scene: GameScene?
    
    @Published var sprintCooldown: TimeInterval = 0
    @Published var isSprinting: Bool = false
    @Published var isBlocking: Bool = false
    
    private var sprintTimer: Timer?
    private let sprintDuration: TimeInterval = 1.5
    private let sprintCooldownDuration: TimeInterval = 5.0
    
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
    
    func moveWithJoystick(direction: CGVector) {
        // Convert joystick direction to movement
        // Horizontal movement based on joystick X direction
        if abs(direction.dx) > 0.1 {
            let moveSpeed = direction.dx * 2.0 // Scale factor for movement
            scene?.movePlayer(direction: moveSpeed)
        }
    }
    
    func moveLeft() {
        scene?.movePlayer(direction: -1)
    }
    
    func moveRight() {
        scene?.movePlayer(direction: 1)
    }
    
    func sprint() {
        guard sprintCooldown <= 0 && !isSprinting else { return }
        
        isSprinting = true
        
        // Trigger haptic for sprint
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        // Apply sprint boost (move faster for sprint duration)
        let sprintBoost: CGFloat = 3.0
        
        // Sprint ends after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + sprintDuration) { [weak self] in
            guard let self = self else { return }
            self.isSprinting = false
            self.startSprintCooldown()
        }
        
        // Perform sprint movement
        scene?.movePlayer(direction: sprintBoost)
    }
    
    private func startSprintCooldown() {
        sprintCooldown = sprintCooldownDuration
        
        sprintTimer?.invalidate()
        sprintTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            DispatchQueue.main.async {
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                self.sprintCooldown -= 0.1
                if self.sprintCooldown <= 0 {
                    self.sprintCooldown = 0
                    timer.invalidate()
                }
            }
        }
    }
    
    func block(_ blocking: Bool) {
        isBlocking = blocking
        scene?.playerBlock(blocking)
    }
}

// MARK: - Wolf Style Controls View

struct WolfStyleControlsView: View {
    @ObservedObject var controller: GameController
    @State private var joystickDirection: CGVector = .zero
    @State private var isBlocking: Bool = false
    
    var body: some View {
        HStack(alignment: .bottom) {
            // Left side - Virtual Joystick
            VStack {
                VirtualJoystick(direction: $joystickDirection)
                    .onChange(of: joystickDirection) { _, newValue in
                        controller.moveWithJoystick(direction: newValue)
                    }
                
                Text("MOVE")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.leading, 20)
            
            Spacer()
            
            // Right side - Action buttons (Wolf style layout)
            VStack(alignment: .trailing, spacing: 12) {
                // Top row - Ability button
                ActionButton(
                    actionType: .targetLock,
                    action: { controller.useAbility() },
                    size: 60
                )
                
                // Middle row - Block and Sprint
                HStack(spacing: 12) {
                    // Block button (hold)
                    ActionButton(
                        actionType: .block,
                        action: { },
                        isActive: isBlocking,
                        size: 55
                    )
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
                    
                    // Sprint button
                    ActionButton(
                        actionType: .sprint,
                        action: { controller.sprint() },
                        isEnabled: controller.sprintCooldown <= 0,
                        isActive: controller.isSprinting,
                        cooldownRemaining: controller.sprintCooldown,
                        size: 55
                    )
                }
                
                // Bottom row - Attack button (largest)
                ActionButton(
                    actionType: .attack,
                    action: { controller.attack() },
                    size: 75
                )
            }
            .padding(.trailing, 20)
        }
        .padding(.bottom, 30)
    }
}

// MARK: - Legacy Game Controls View (kept for reference)

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
