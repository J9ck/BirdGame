#if canImport(SwiftUI)
import SwiftUI

/// Main game controls view implementing The Wolf-style UI layout
/// Contains joystick on left, action/skill buttons on right, and health bars at top
struct GameControlsView: View {
    // MARK: - Properties
    
    /// The player's bird
    let playerBird: Bird
    
    /// The enemy bird (optional)
    let enemyBird: Bird?
    
    /// Control manager for handling inputs
    @ObservedObject var controlManager: ControlManager
    
    // MARK: - State
    
    @State private var joystickDirection: CGVector = .zero
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Top HUD - Health bars
                VStack {
                    topHUD
                    Spacer()
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                
                // Bottom Controls
                VStack {
                    Spacer()
                    bottomControls(in: geometry)
                }
                .padding(.bottom, 30)
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Top HUD
    
    private var topHUD: some View {
        HStack {
            // Player health
            HealthBar(
                name: playerBird.name,
                currentHealth: playerBird.currentHealth,
                maxHealth: playerBird.maxHealth
            )
            
            Spacer()
            
            // Enemy health (if present)
            if let enemy = enemyBird {
                HealthBar(
                    name: enemy.name,
                    currentHealth: enemy.currentHealth,
                    maxHealth: enemy.maxHealth,
                    isEnemy: true
                )
            }
        }
    }
    
    // MARK: - Bottom Controls
    
    private func bottomControls(in geometry: GeometryProxy) -> some View {
        HStack(alignment: .bottom) {
            // Left side - Joystick
            joystickArea
            
            Spacer()
            
            // Right side - Action buttons and skills
            rightControlsArea
        }
    }
    
    // MARK: - Joystick Area
    
    private var joystickArea: some View {
        VStack {
            VirtualJoystick(direction: $joystickDirection)
                .onChange(of: joystickDirection) { _, newValue in
                    controlManager.updateMovement(direction: newValue)
                }
        }
    }
    
    // MARK: - Right Controls Area
    
    private var rightControlsArea: some View {
        VStack(alignment: .trailing, spacing: 12) {
            // Skill buttons in 2x2 grid
            skillButtonsGrid
            
            // Main action buttons row
            mainActionButtons
        }
    }
    
    // MARK: - Skill Buttons Grid
    
    private var skillButtonsGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                if playerBird.skills.count > 0 {
                    SkillButton(
                        skill: playerBird.skills[0],
                        cooldownRemaining: controlManager.skillCooldowns.indices.contains(0) ? controlManager.skillCooldowns[0] : 0,
                        action: { controlManager.triggerSkill(at: 0) },
                        size: 55,
                        backgroundColor: .purple.opacity(0.7)
                    )
                }
                
                if playerBird.skills.count > 1 {
                    SkillButton(
                        skill: playerBird.skills[1],
                        cooldownRemaining: controlManager.skillCooldowns.indices.contains(1) ? controlManager.skillCooldowns[1] : 0,
                        action: { controlManager.triggerSkill(at: 1) },
                        size: 55,
                        backgroundColor: .teal.opacity(0.7)
                    )
                }
            }
            
            HStack(spacing: 8) {
                if playerBird.skills.count > 2 {
                    SkillButton(
                        skill: playerBird.skills[2],
                        cooldownRemaining: controlManager.skillCooldowns.indices.contains(2) ? controlManager.skillCooldowns[2] : 0,
                        action: { controlManager.triggerSkill(at: 2) },
                        size: 55,
                        backgroundColor: .green.opacity(0.7)
                    )
                }
                
                if playerBird.skills.count > 3 {
                    SkillButton(
                        skill: playerBird.skills[3],
                        cooldownRemaining: controlManager.skillCooldowns.indices.contains(3) ? controlManager.skillCooldowns[3] : 0,
                        action: { controlManager.triggerSkill(at: 3) },
                        size: 55,
                        backgroundColor: .cyan.opacity(0.7)
                    )
                }
            }
        }
    }
    
    // MARK: - Main Action Buttons
    
    private var mainActionButtons: some View {
        HStack(spacing: 12) {
            // Target lock button
            ActionButton(
                actionType: .targetLock,
                action: { controlManager.toggleTargetLock() },
                isActive: controlManager.currentInput.isTargetLocked,
                size: 55
            )
            
            // Sprint button
            ActionButton(
                actionType: .sprint,
                action: { controlManager.triggerSprint() },
                isEnabled: controlManager.canSprint,
                isActive: controlManager.currentInput.isSprinting,
                cooldownRemaining: controlManager.sprintCooldown,
                size: 60
            )
            
            // Attack button (largest)
            ActionButton(
                actionType: .attack,
                action: { controlManager.triggerAttack() },
                isActive: controlManager.currentInput.isAttacking,
                size: 75
            )
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // Sample game background
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        // Sample arena area
        Rectangle()
            .fill(Color.green.opacity(0.2))
            .frame(height: 300)
        
        // Controls overlay
        GameControlsView(
            playerBird: .phoenix,
            enemyBird: .hawk,
            controlManager: {
                let manager = ControlManager()
                manager.configure(with: .phoenix)
                return manager
            }()
        )
    }
}
#endif
