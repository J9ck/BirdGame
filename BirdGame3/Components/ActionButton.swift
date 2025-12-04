//
//  ActionButton.swift
//  BirdGame3
//
//  Wolf-style action buttons for attack, sprint, and special actions
//

import SwiftUI

/// A general action button for attack, sprint, and target lock actions
/// Provides visual and haptic feedback on press
struct ActionButton: View {
    // MARK: - Properties
    
    /// Type of action this button performs
    let actionType: ActionType
    
    /// Action to perform when button is tapped
    let action: () -> Void
    
    /// Whether the button is enabled
    var isEnabled: Bool = true
    
    /// Whether the action is currently active (for toggle-style buttons)
    var isActive: Bool = false
    
    /// Optional cooldown remaining (for sprint)
    var cooldownRemaining: TimeInterval = 0
    
    /// Button size
    var size: CGFloat = 70
    
    // MARK: - State
    
    @State private var isPressed: Bool = false
    
    // MARK: - Computed Properties
    
    private var isOnCooldown: Bool {
        cooldownRemaining > 0
    }
    
    private var buttonColor: Color {
        if isOnCooldown {
            return .gray.opacity(0.6)
        }
        
        switch actionType {
        case .attack:
            return isActive ? .red : .red.opacity(0.8)
        case .sprint:
            return isActive ? .orange : .orange.opacity(0.8)
        case .targetLock:
            return isActive ? .yellow : .blue.opacity(0.7)
        case .block:
            return isActive ? .cyan : .blue.opacity(0.7)
        }
    }
    
    private var iconName: String {
        switch actionType {
        case .attack:
            return "bolt.fill"
        case .sprint:
            return "hare.fill"
        case .targetLock:
            return isActive ? "scope" : "target"
        case .block:
            return "shield.fill"
        }
    }
    
    private var buttonLabel: String {
        switch actionType {
        case .attack:
            return "ATTACK"
        case .sprint:
            return "SPRINT"
        case .targetLock:
            return "TARGET"
        case .block:
            return "BLOCK"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: handleTap) {
            ZStack {
                // Background with glow effect when active
                Circle()
                    .fill(buttonColor)
                    .frame(width: size, height: size)
                    .shadow(color: isActive ? buttonColor : .clear, radius: 10)
                
                // Border
                Circle()
                    .stroke(Color.white.opacity(0.6), lineWidth: 3)
                    .frame(width: size, height: size)
                
                // Inner glow when pressed
                if isPressed {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: size * 0.8, height: size * 0.8)
                }
                
                // Icon and label
                VStack(spacing: 2) {
                    Image(systemName: iconName)
                        .font(.system(size: size * 0.35, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(buttonLabel)
                        .font(.system(size: size * 0.12, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Cooldown overlay for sprint
                if isOnCooldown {
                    cooldownOverlay
                }
            }
        }
        .buttonStyle(ActionButtonStyle(isPressed: $isPressed, isDisabled: !isEnabled || isOnCooldown))
        .disabled(!isEnabled || isOnCooldown)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(buttonLabel) button")
        .accessibilityHint(accessibilityHintText)
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Subviews
    
    private var cooldownOverlay: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.4))
                .frame(width: size, height: size)
            
            Text(String(format: "%.0f", ceil(cooldownRemaining)))
                .font(.system(size: size * 0.3, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Computed Text
    
    private var accessibilityHintText: String {
        if isOnCooldown {
            return "On cooldown, \(Int(cooldownRemaining)) seconds remaining"
        }
        
        switch actionType {
        case .attack:
            return "Double tap to attack"
        case .sprint:
            return "Double tap to sprint"
        case .targetLock:
            return isActive ? "Double tap to unlock target" : "Double tap to lock onto target"
        case .block:
            return isActive ? "Release to stop blocking" : "Hold to block"
        }
    }
    
    // MARK: - Actions
    
    private func handleTap() {
        guard isEnabled && !isOnCooldown else { return }
        triggerHaptic(.medium)
        action()
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Action Type

enum ActionType {
    case attack
    case sprint
    case targetLock
    case block
}

// MARK: - Action Button Style

struct ActionButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    let isDisabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !isDisabled ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { newValue in
                isPressed = newValue
            }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        HStack(spacing: 20) {
            ActionButton(
                actionType: .attack,
                action: {}
            )
            
            ActionButton(
                actionType: .sprint,
                action: {},
                cooldownRemaining: 3
            )
            
            ActionButton(
                actionType: .targetLock,
                action: {},
                isActive: true
            )
            
            ActionButton(
                actionType: .block,
                action: {}
            )
        }
    }
}
