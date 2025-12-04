#if canImport(SwiftUI)
import SwiftUI

/// Main content view for Bird Game 3
/// Displays the game arena with The Wolf-style control overlay
struct ContentView: View {
    // MARK: - State
    
    @StateObject private var controlManager = ControlManager()
    @State private var playerBird = Bird.phoenix
    @State private var enemyBird: Bird? = Bird.hawk
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Game background
                gameBackground
                
                // Game arena placeholder
                gameArena
                
                // Game controls overlay (The Wolf style)
                GameControlsView(
                    playerBird: playerBird,
                    enemyBird: enemyBird,
                    controlManager: controlManager
                )
            }
            .ignoresSafeArea()
        }
        .onAppear {
            controlManager.configure(with: playerBird)
        }
        .statusBar(hidden: true)
    }
    
    // MARK: - Background
    
    private var gameBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.2, blue: 0.4),
                Color(red: 0.2, green: 0.3, blue: 0.5),
                Color(red: 0.1, green: 0.15, blue: 0.3)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Game Arena
    
    private var gameArena: some View {
        VStack {
            Spacer()
            
            // Arena indicator (placeholder for actual game content)
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.green.opacity(0.1))
                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
                
                VStack(spacing: 10) {
                    Text("GAME ARENA")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("Bird Combat Area")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.3))
                    
                    // Show current input state for debugging
                    debugInputDisplay
                }
            }
            .frame(height: 250)
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Debug Display
    
    private var debugInputDisplay: some View {
        VStack(spacing: 4) {
            let input = controlManager.currentInput
            
            Text("Direction: (\(String(format: "%.2f", input.movementDirection.dx)), \(String(format: "%.2f", input.movementDirection.dy)))")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
            
            HStack(spacing: 8) {
                if input.isAttacking {
                    Text("⚔️ ATTACKING")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red)
                }
                if input.isSprinting {
                    Text("🏃 SPRINTING")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)
                }
                if input.isTargetLocked {
                    Text("🎯 LOCKED")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.yellow)
                }
            }
            
            if let skillIndex = input.activeSkillIndex {
                Text("SKILL \(skillIndex + 1) ACTIVATED")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.purple)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
#endif
