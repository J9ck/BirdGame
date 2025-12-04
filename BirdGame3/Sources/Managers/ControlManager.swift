import Foundation

#if canImport(Combine)
import Combine
#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(UIKit)
import UIKit
#endif

/// Manages game control inputs and translates them to bird actions
@MainActor
final class ControlManager: ObservableObject {
    // MARK: - Published Properties
    
    /// Current control input state
    @Published private(set) var currentInput = ControlInput()
    
    /// Cooldown remaining for each skill (by index)
    @Published private(set) var skillCooldowns: [TimeInterval] = [0, 0, 0, 0]
    
    /// Sprint cooldown/stamina remaining
    @Published private(set) var sprintCooldown: TimeInterval = 0
    
    /// Whether sprint is available
    @Published private(set) var canSprint: Bool = true
    
    // MARK: - Configuration
    
    /// Duration of sprint ability
    let sprintDuration: TimeInterval = 2.0
    
    /// Cooldown after sprint
    let sprintCooldownDuration: TimeInterval = 5.0
    
    /// Current bird's skills for cooldown management
    private var currentSkills: [BirdSkill] = []
    
    // MARK: - Private Properties
    
    private var cooldownTimers: [Timer] = []
    private var sprintTimer: Timer?
    
    // MARK: - Initialization
    
    init() {}
    
    /// Configure the manager with the current bird's skills
    func configure(with bird: Bird) {
        currentSkills = bird.skills
        skillCooldowns = Array(repeating: 0, count: bird.skills.count)
    }
    
    // MARK: - Movement Control
    
    /// Update movement direction from joystick input
    func updateMovement(direction: CGVector) {
        currentInput.movementDirection = direction
    }
    
    /// Reset movement to zero
    func stopMovement() {
        currentInput.movementDirection = .zero
    }
    
    // MARK: - Attack Control
    
    /// Trigger primary attack
    func triggerAttack() {
        currentInput.isAttacking = true
        triggerHapticFeedback(.medium)
        
        // Reset attack state after a brief moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.currentInput.isAttacking = false
        }
    }
    
    // MARK: - Sprint Control
    
    /// Trigger sprint/dash
    func triggerSprint() {
        guard canSprint else { return }
        
        currentInput.isSprinting = true
        canSprint = false
        triggerHapticFeedback(.heavy)
        
        // Sprint duration
        DispatchQueue.main.asyncAfter(deadline: .now() + sprintDuration) { [weak self] in
            guard let self = self else { return }
            self.currentInput.isSprinting = false
            self.startSprintCooldown()
        }
    }
    
    private func startSprintCooldown() {
        sprintCooldown = sprintCooldownDuration
        
        sprintTimer?.invalidate()
        sprintTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                self.sprintCooldown -= 0.1
                if self.sprintCooldown <= 0 {
                    self.sprintCooldown = 0
                    self.canSprint = true
                    timer.invalidate()
                }
            }
        }
    }
    
    // MARK: - Target Lock Control
    
    /// Toggle target lock
    func toggleTargetLock() {
        currentInput.isTargetLocked.toggle()
        triggerHapticFeedback(.light)
    }
    
    // MARK: - Skill Control
    
    /// Trigger a skill by index
    func triggerSkill(at index: Int) {
        guard index >= 0 && index < currentSkills.count else { return }
        guard skillCooldowns[index] <= 0 else { return }
        
        currentInput.activeSkillIndex = index
        triggerHapticFeedback(.medium)
        
        // Start cooldown for this skill
        let skill = currentSkills[index]
        startSkillCooldown(at: index, duration: skill.cooldownDuration)
        
        // Reset active skill after brief moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.currentInput.activeSkillIndex = nil
        }
    }
    
    /// Check if a skill is on cooldown
    func isSkillOnCooldown(at index: Int) -> Bool {
        guard index >= 0 && index < skillCooldowns.count else { return true }
        return skillCooldowns[index] > 0
    }
    
    /// Get cooldown progress (0 to 1) for a skill
    func skillCooldownProgress(at index: Int) -> Double {
        guard index >= 0 && index < skillCooldowns.count && index < currentSkills.count else { return 0 }
        let totalCooldown = currentSkills[index].cooldownDuration
        guard totalCooldown > 0 else { return 0 }
        return skillCooldowns[index] / totalCooldown
    }
    
    private func startSkillCooldown(at index: Int, duration: TimeInterval) {
        skillCooldowns[index] = duration
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                self.skillCooldowns[index] -= 0.1
                if self.skillCooldowns[index] <= 0 {
                    self.skillCooldowns[index] = 0
                    timer.invalidate()
                }
            }
        }
        cooldownTimers.append(timer)
    }
    
    // MARK: - Haptic Feedback
    
    /// Trigger haptic feedback
    func triggerHapticFeedback(_ style: HapticStyle) {
        #if canImport(UIKit) && !os(watchOS)
        let generator: UIImpactFeedbackGenerator
        switch style {
        case .light:
            generator = UIImpactFeedbackGenerator(style: .light)
        case .medium:
            generator = UIImpactFeedbackGenerator(style: .medium)
        case .heavy:
            generator = UIImpactFeedbackGenerator(style: .heavy)
        }
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        cooldownTimers.forEach { $0.invalidate() }
        cooldownTimers.removeAll()
        sprintTimer?.invalidate()
        sprintTimer = nil
    }
    
    deinit {
        // Note: cleanup should be called before deinit on MainActor
    }
}
#endif

// MARK: - Haptic Style

enum HapticStyle {
    case light
    case medium
    case heavy
}
