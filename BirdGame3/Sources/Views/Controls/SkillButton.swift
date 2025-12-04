#if canImport(SwiftUI)
import SwiftUI

/// A skill button with cooldown visualization
/// Shows skill icon, cooldown overlay, and provides visual/haptic feedback
struct SkillButton: View {
    // MARK: - Properties
    
    /// The skill this button represents
    let skill: BirdSkill
    
    /// Remaining cooldown time in seconds
    let cooldownRemaining: TimeInterval
    
    /// Action to perform when button is tapped
    let action: () -> Void
    
    /// Button size
    var size: CGFloat = 60
    
    /// Background color
    var backgroundColor: Color = .blue.opacity(0.7)
    
    /// Color when on cooldown
    var cooldownColor: Color = .gray.opacity(0.8)
    
    // MARK: - State
    
    @State private var isPressed: Bool = false
    
    // MARK: - Computed Properties
    
    private var isOnCooldown: Bool {
        cooldownRemaining > 0
    }
    
    private var cooldownProgress: Double {
        guard skill.cooldownDuration > 0 else { return 0 }
        return cooldownRemaining / skill.cooldownDuration
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: handleTap) {
            ZStack {
                // Background
                Circle()
                    .fill(isOnCooldown ? cooldownColor : backgroundColor)
                    .frame(width: size, height: size)
                
                // Cooldown overlay (pie chart style)
                if isOnCooldown {
                    CooldownOverlay(progress: cooldownProgress)
                        .frame(width: size, height: size)
                }
                
                // Border
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    .frame(width: size, height: size)
                
                // Skill icon
                Image(systemName: skill.iconName)
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.white)
                    .opacity(isOnCooldown ? 0.5 : 1.0)
                
                // Cooldown timer text
                if isOnCooldown {
                    Text(String(format: "%.0f", ceil(cooldownRemaining)))
                        .font(.system(size: size * 0.25, weight: .bold))
                        .foregroundColor(.white)
                        .offset(y: size * 0.25)
                }
            }
        }
        .buttonStyle(SkillButtonStyle(isPressed: $isPressed, isDisabled: isOnCooldown))
        .disabled(isOnCooldown)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(skill.name) skill")
        .accessibilityHint(isOnCooldown ? "On cooldown, \(Int(cooldownRemaining)) seconds remaining" : "Double tap to activate")
        .accessibilityAddTraits(isOnCooldown ? .isButton : [.isButton])
    }
    
    // MARK: - Actions
    
    private func handleTap() {
        guard !isOnCooldown else { return }
        action()
    }
}

// MARK: - Cooldown Overlay

struct CooldownOverlay: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2
            
            Path { path in
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(-90 + 360 * progress),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(Color.black.opacity(0.5))
        }
    }
}

// MARK: - Skill Button Style

struct SkillButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    let isDisabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !isDisabled ? 0.9 : 1.0)
            .opacity(configuration.isPressed && !isDisabled ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        HStack(spacing: 20) {
            SkillButton(
                skill: .fireball,
                cooldownRemaining: 0,
                action: {}
            )
            
            SkillButton(
                skill: .heal,
                cooldownRemaining: 5.5,
                action: {}
            )
            
            SkillButton(
                skill: .shield,
                cooldownRemaining: 10,
                action: {}
            )
        }
    }
}
#endif
