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
    
    /// Adjusts a color based on color blind mode
    /// Uses SwiftUI Color transformations to simulate color-blind friendly alternatives
    func adjustedColor(_ color: Color, for mode: ColorBlindMode? = nil) -> Color {
        let activeMode = mode ?? settings.colorBlindMode
        
        guard activeMode != .none else { return color }
        
        // Convert to UIColor to get RGB components
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Apply color blind simulation matrices
        // These are simplified Daltonization algorithms
        let (newRed, newGreen, newBlue): (CGFloat, CGFloat, CGFloat)
        
        switch activeMode {
        case .none:
            return color
            
        case .protanopia:
            // Red-blind: Shift reds toward yellows/blues
            newRed = 0.567 * red + 0.433 * green + 0.0 * blue
            newGreen = 0.558 * red + 0.442 * green + 0.0 * blue
            newBlue = 0.0 * red + 0.242 * green + 0.758 * blue
            
        case .deuteranopia:
            // Green-blind: Shift greens toward yellows/blues
            newRed = 0.625 * red + 0.375 * green + 0.0 * blue
            newGreen = 0.7 * red + 0.3 * green + 0.0 * blue
            newBlue = 0.0 * red + 0.3 * green + 0.7 * blue
            
        case .tritanopia:
            // Blue-blind: Shift blues toward cyans/magentas
            newRed = 0.95 * red + 0.05 * green + 0.0 * blue
            newGreen = 0.0 * red + 0.433 * green + 0.567 * blue
            newBlue = 0.0 * red + 0.475 * green + 0.525 * blue
        }
        
        return Color(
            red: Double(min(1, max(0, newRed))),
            green: Double(min(1, max(0, newGreen))),
            blue: Double(min(1, max(0, newBlue))),
            opacity: Double(alpha)
        )
    }
    
    // Color-blind friendly palette - pre-defined safe colors for UI elements
    var healthBarColor: Color {
        switch settings.colorBlindMode {
        case .none: return .red
        case .protanopia: return Color(red: 1.0, green: 0.6, blue: 0.0) // Orange
        case .deuteranopia: return Color(red: 1.0, green: 0.6, blue: 0.0) // Orange
        case .tritanopia: return Color(red: 1.0, green: 0.2, blue: 0.2) // Red works
        }
    }
    
    var friendlyColor: Color {
        switch settings.colorBlindMode {
        case .none: return .green
        case .protanopia: return Color(red: 0.0, green: 0.6, blue: 1.0) // Blue
        case .deuteranopia: return Color(red: 0.0, green: 0.6, blue: 1.0) // Blue
        case .tritanopia: return Color(red: 0.0, green: 0.8, blue: 0.4) // Green works
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
