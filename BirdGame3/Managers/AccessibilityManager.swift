//
//  AccessibilityManager.swift
//  BirdGame3
//
//  Accessibility features for inclusive gameplay
//

import Foundation
import SwiftUI
import AVFoundation

// MARK: - Accessibility Settings

struct AccessibilitySettings: Codable {
    // Visual
    var highContrastMode: Bool = false
    var largeText: Bool = false
    var reduceMotion: Bool = false
    var colorBlindMode: ColorBlindMode = .none
    var screenFlashEnabled: Bool = true
    
    // Audio
    var subtitlesEnabled: Bool = false
    var voiceOverDescriptions: Bool = true
    var soundIndicators: Bool = true // Visual indicators for audio cues
    
    // Controls
    var hapticFeedback: Bool = true
    var autoAim: Bool = false
    var extendedTimers: Bool = false // Extra time for timed actions
    var simplifiedControls: Bool = false
    var holdToAttack: Bool = false // Hold instead of tap
    
    // Game
    var difficultyAssist: Bool = false
    var skipTutorials: Bool = false
}

// MARK: - Color Blind Mode

enum ColorBlindMode: String, Codable, CaseIterable {
    case none
    case protanopia      // Red-blind
    case deuteranopia    // Green-blind
    case tritanopia      // Blue-blind
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .protanopia: return "Protanopia (Red-Blind)"
        case .deuteranopia: return "Deuteranopia (Green-Blind)"
        case .tritanopia: return "Tritanopia (Blue-Blind)"
        }
    }
    
    var description: String {
        switch self {
        case .none: return "Standard colors"
        case .protanopia: return "Adjusts reds to be more visible"
        case .deuteranopia: return "Adjusts greens to be more visible"
        case .tritanopia: return "Adjusts blues to be more visible"
        }
    }
}

// MARK: - Accessibility Manager

class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()
    
    // MARK: - Published Properties
    
    @Published var settings: AccessibilitySettings {
        didSet { save() }
    }
    
    // MARK: - Private Properties
    
    private let saveKey = "birdgame3_accessibility"
    
    // MARK: - Initialization
    
    private init() {
        settings = Self.load()
        syncWithSystemSettings()
    }
    
    // MARK: - System Settings Sync
    
    private func syncWithSystemSettings() {
        // Sync with iOS accessibility settings
        if UIAccessibility.isReduceMotionEnabled && !settings.reduceMotion {
            settings.reduceMotion = true
        }
        
        if UIAccessibility.isVoiceOverRunning && !settings.voiceOverDescriptions {
            settings.voiceOverDescriptions = true
        }
        
        if UIAccessibility.isBoldTextEnabled && !settings.largeText {
            settings.largeText = true
        }
    }
    
    // MARK: - Color Adjustments
    
    func adjustedColor(_ color: Color, for mode: ColorBlindMode? = nil) -> Color {
        let activeMode = mode ?? settings.colorBlindMode
        
        guard activeMode != .none else { return color }
        
        // Note: In production, this would use proper color transformation matrices
        // This is a simplified version
        switch activeMode {
        case .none:
            return color
        case .protanopia:
            // Shift reds toward yellow
            return color
        case .deuteranopia:
            // Shift greens toward yellow
            return color
        case .tritanopia:
            // Shift blues toward cyan
            return color
        }
    }
    
    // Color-blind friendly palette
    var healthBarColor: Color {
        switch settings.colorBlindMode {
        case .none: return .red
        case .protanopia: return .orange
        case .deuteranopia: return .orange
        case .tritanopia: return .red
        }
    }
    
    var friendlyColor: Color {
        switch settings.colorBlindMode {
        case .none: return .green
        case .protanopia: return .blue
        case .deuteranopia: return .blue
        case .tritanopia: return .green
        }
    }
    
    var enemyColor: Color {
        switch settings.colorBlindMode {
        case .none: return .red
        case .protanopia: return .yellow
        case .deuteranopia: return .yellow
        case .tritanopia: return .red
        }
    }
    
    // MARK: - Text Scaling
    
    var textScaleFactor: CGFloat {
        settings.largeText ? 1.3 : 1.0
    }
    
    func scaledFont(_ size: CGFloat) -> Font {
        .system(size: size * textScaleFactor)
    }
    
    // MARK: - Animation
    
    var animationDuration: Double {
        settings.reduceMotion ? 0.01 : 0.3
    }
    
    func withAccessibleAnimation<Result>(_ body: () throws -> Result) rethrows -> Result {
        if settings.reduceMotion {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            return try withTransaction(transaction) {
                try body()
            }
        }
        return try body()
    }
    
    // MARK: - Haptic Feedback
    
    func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard settings.hapticFeedback else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func triggerNotificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard settings.hapticFeedback else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    // MARK: - Voice Over Announcements
    
    func announce(_ message: String, priority: Bool = false) {
        guard settings.voiceOverDescriptions else { return }
        
        let announcement = NSAttributedString(
            string: message,
            attributes: [.accessibilitySpeechQueueAnnouncement: !priority]
        )
        
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
    
    // MARK: - Game Difficulty Adjustments
    
    var damageMultiplier: Double {
        settings.difficultyAssist ? 1.25 : 1.0 // Player deals 25% more damage
    }
    
    var incomingDamageMultiplier: Double {
        settings.difficultyAssist ? 0.75 : 1.0 // Player takes 25% less damage
    }
    
    var timerMultiplier: Double {
        settings.extendedTimers ? 1.5 : 1.0 // 50% more time
    }
    
    // MARK: - Persistence
    
    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
    
    private static func load() -> AccessibilitySettings {
        if let data = UserDefaults.standard.data(forKey: "birdgame3_accessibility"),
           let settings = try? JSONDecoder().decode(AccessibilitySettings.self, from: data) {
            return settings
        }
        return AccessibilitySettings()
    }
    
    func reset() {
        settings = AccessibilitySettings()
    }
}

// MARK: - View Modifiers

struct AccessibleText: ViewModifier {
    @ObservedObject var accessibility = AccessibilityManager.shared
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(accessibility.textScaleFactor)
    }
}

struct AccessibleAnimation: ViewModifier {
    @ObservedObject var accessibility = AccessibilityManager.shared
    let value: any Equatable
    
    func body(content: Content) -> some View {
        if accessibility.settings.reduceMotion {
            content
        } else {
            content.animation(.default, value: value as? Bool ?? false)
        }
    }
}

struct HighContrastBorder: ViewModifier {
    @ObservedObject var accessibility = AccessibilityManager.shared
    
    func body(content: Content) -> some View {
        if accessibility.settings.highContrastMode {
            content
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: 2)
                )
        } else {
            content
        }
    }
}

// MARK: - View Extensions

extension View {
    func accessibleText() -> some View {
        modifier(AccessibleText())
    }
    
    func highContrastBorder() -> some View {
        modifier(HighContrastBorder())
    }
    
    func accessibilityGameElement(label: String, hint: String? = nil, value: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
    }
}
