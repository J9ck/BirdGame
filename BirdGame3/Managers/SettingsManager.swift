//
//  SettingsManager.swift
//  BirdGame3
//
//  Centralized settings for camera, graphics, audio, and controls
//

import Foundation
import SwiftUI
import UIKit

// MARK: - Graphics Quality

enum GraphicsQuality: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case ultra = "Ultra"
    
    var shadowQuality: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .ultra: return 3
        }
    }
    
    var textureResolution: Float {
        switch self {
        case .low: return 0.5
        case .medium: return 0.75
        case .high: return 1.0
        case .ultra: return 1.0
        }
    }
    
    var particleCount: Int {
        switch self {
        case .low: return 10
        case .medium: return 25
        case .high: return 50
        case .ultra: return 100
        }
    }
    
    var drawDistance: Float {
        switch self {
        case .low: return 500
        case .medium: return 1000
        case .high: return 2000
        case .ultra: return 5000
        }
    }
    
    var antiAliasing: Bool {
        switch self {
        case .low, .medium: return false
        case .high, .ultra: return true
        }
    }
    
    var description: String {
        switch self {
        case .low: return "Best performance, reduced visuals"
        case .medium: return "Balanced performance and quality"
        case .high: return "High quality, may impact battery"
        case .ultra: return "Maximum quality, high battery usage"
        }
    }
}

// MARK: - Frame Rate Target

enum FrameRateTarget: Int, Codable, CaseIterable {
    case fps30 = 30
    case fps60 = 60
    
    var displayName: String {
        "\(rawValue) FPS"
    }
}

// MARK: - Control Scheme

enum ControlScheme: String, Codable, CaseIterable {
    case standard = "Standard"
    case simplified = "Simplified"
    case custom = "Custom"
    
    var description: String {
        switch self {
        case .standard: return "Default layout with all controls"
        case .simplified: return "Reduced buttons, auto-targeting"
        case .custom: return "Customize button positions"
        }
    }
}

// MARK: - Game Settings

struct GameSettings: Codable {
    // Graphics
    var graphicsQuality: GraphicsQuality = .high
    var targetFrameRate: FrameRateTarget = .fps60
    var shadows: Bool = true
    var postProcessing: Bool = true
    var dynamicResolution: Bool = true
    var reducedMotion: Bool = false
    
    // Camera
    var cameraSensitivityX: Float = 1.0
    var cameraSensitivityY: Float = 1.0
    var invertCameraX: Bool = false
    var invertCameraY: Bool = false
    var cameraSmoothing: Float = 5.0
    var autoRotateCamera: Bool = true
    
    // Audio
    var masterVolume: Float = 1.0
    var musicVolume: Float = 0.7
    var sfxVolume: Float = 1.0
    var voiceVolume: Float = 1.0
    var ambientVolume: Float = 0.5
    
    // Controls
    var controlScheme: ControlScheme = .standard
    var hapticFeedback: Bool = true
    var hapticIntensity: Float = 1.0
    var joystickSize: Float = 1.0
    var joystickDeadzone: Float = 0.1
    var buttonScale: Float = 1.0
    var showDamageNumbers: Bool = true
    var autoTarget: Bool = false
    
    // Accessibility
    var colorBlindMode: ColorBlindMode = .none
    var largeText: Bool = false
    var highContrast: Bool = false
    var screenShakeReduced: Bool = false
    
    // Gameplay
    var autoSprint: Bool = false
    var showMinimap: Bool = true
    var showQuestTracker: Bool = true
    var showOtherPlayers: Bool = true
    var profanityFilter: Bool = true
    
    // Notifications
    var pushNotifications: Bool = true
    var inGameNotifications: Bool = true
    var soundOnNotification: Bool = true
    
    static let `default` = GameSettings()
}

// MARK: - Color Blind Mode

enum ColorBlindMode: String, Codable, CaseIterable {
    case none = "None"
    case protanopia = "Protanopia"
    case deuteranopia = "Deuteranopia"
    case tritanopia = "Tritanopia"
    
    var description: String {
        switch self {
        case .none: return "No color adjustment"
        case .protanopia: return "Red-green (red weak)"
        case .deuteranopia: return "Red-green (green weak)"
        case .tritanopia: return "Blue-yellow"
        }
    }
}

// MARK: - Settings Manager

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // MARK: - Published Properties
    
    @Published var settings: GameSettings = .default {
        didSet {
            save()
            applySettings()
        }
    }
    
    // MARK: - Private Properties
    
    private let saveKey = "birdgame3_settings"
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let lightFeedback = UIImpactFeedbackGenerator(style: .light)
    private let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    // MARK: - Initialization
    
    private init() {
        loadSettings()
        applySettings()
    }
    
    // MARK: - Haptic Feedback
    
    func triggerHaptic(style: HapticStyle) {
        guard settings.hapticFeedback else { return }
        
        switch style {
        case .light:
            lightFeedback.impactOccurred(intensity: CGFloat(settings.hapticIntensity))
        case .medium:
            feedbackGenerator.impactOccurred(intensity: CGFloat(settings.hapticIntensity))
        case .heavy:
            heavyFeedback.impactOccurred(intensity: CGFloat(settings.hapticIntensity))
        case .success:
            notificationFeedback.notificationOccurred(.success)
        case .warning:
            notificationFeedback.notificationOccurred(.warning)
        case .error:
            notificationFeedback.notificationOccurred(.error)
        }
    }
    
    // MARK: - Settings Application
    
    private func applySettings() {
        // Apply graphics settings
        applyGraphicsSettings()
        
        // Apply audio settings
        applyAudioSettings()
        
        // Apply accessibility settings
        applyAccessibilitySettings()
    }
    
    private func applyGraphicsSettings() {
        // These would be applied to the SceneKit renderer
        // For now, store values for the scene to read
        UserDefaults.standard.set(settings.graphicsQuality.rawValue, forKey: "graphics_quality")
        UserDefaults.standard.set(settings.targetFrameRate.rawValue, forKey: "target_fps")
        UserDefaults.standard.set(settings.shadows, forKey: "shadows_enabled")
        UserDefaults.standard.set(settings.postProcessing, forKey: "post_processing")
        UserDefaults.standard.set(settings.graphicsQuality.drawDistance, forKey: "draw_distance")
    }
    
    private func applyAudioSettings() {
        // Apply to sound manager
        SoundManager.shared.masterVolume = settings.masterVolume
        SoundManager.shared.musicVolume = settings.musicVolume
        SoundManager.shared.sfxVolume = settings.sfxVolume
    }
    
    private func applyAccessibilitySettings() {
        // Apply to accessibility manager
        AccessibilityManager.shared.settings.colorBlindMode = settings.colorBlindMode
        AccessibilityManager.shared.settings.largeText = settings.largeText
        AccessibilityManager.shared.settings.highContrastMode = settings.highContrast
        AccessibilityManager.shared.settings.reducedMotion = settings.reducedMotion
    }
    
    // MARK: - Presets
    
    func applyPreset(_ preset: SettingsPreset) {
        switch preset {
        case .performance:
            settings.graphicsQuality = .low
            settings.targetFrameRate = .fps60
            settings.shadows = false
            settings.postProcessing = false
            settings.dynamicResolution = true
            settings.hapticFeedback = false
        case .balanced:
            settings.graphicsQuality = .medium
            settings.targetFrameRate = .fps60
            settings.shadows = true
            settings.postProcessing = false
            settings.dynamicResolution = true
            settings.hapticFeedback = true
        case .quality:
            settings.graphicsQuality = .high
            settings.targetFrameRate = .fps30
            settings.shadows = true
            settings.postProcessing = true
            settings.dynamicResolution = false
            settings.hapticFeedback = true
        case .batteryLife:
            settings.graphicsQuality = .low
            settings.targetFrameRate = .fps30
            settings.shadows = false
            settings.postProcessing = false
            settings.dynamicResolution = true
            settings.hapticFeedback = false
        }
    }
    
    func resetToDefaults() {
        settings = .default
    }
    
    // MARK: - Camera Sensitivity
    
    func setCameraSensitivity(_ value: Float) {
        settings.cameraSensitivityX = value
        settings.cameraSensitivityY = value
    }
    
    // MARK: - Volume Control
    
    func setMasterVolume(_ value: Float) {
        settings.masterVolume = value
        applyAudioSettings()
    }
    
    // MARK: - Persistence
    
    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let loaded = try? JSONDecoder().decode(GameSettings.self, from: data) {
            settings = loaded
        }
    }
}

// MARK: - Haptic Style

enum HapticStyle {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
}

// MARK: - Settings Preset

enum SettingsPreset: String, CaseIterable {
    case performance = "Performance"
    case balanced = "Balanced"
    case quality = "Quality"
    case batteryLife = "Battery Saver"
    
    var description: String {
        switch self {
        case .performance: return "Maximum FPS, reduced visuals"
        case .balanced: return "Good balance of quality and performance"
        case .quality: return "Best visuals, may reduce FPS"
        case .batteryLife: return "Optimized for long play sessions"
        }
    }
    
    var emoji: String {
        switch self {
        case .performance: return "⚡"
        case .balanced: return "⚖️"
        case .quality: return "✨"
        case .batteryLife: return "🔋"
        }
    }
}

// MARK: - Sound Manager Extension

extension SoundManager {
    var masterVolume: Float {
        get { UserDefaults.standard.float(forKey: "sound_master") }
        set { UserDefaults.standard.set(newValue, forKey: "sound_master") }
    }
    
    var musicVolume: Float {
        get { UserDefaults.standard.float(forKey: "sound_music") }
        set { UserDefaults.standard.set(newValue, forKey: "sound_music") }
    }
    
    var sfxVolume: Float {
        get { UserDefaults.standard.float(forKey: "sound_sfx") }
        set { UserDefaults.standard.set(newValue, forKey: "sound_sfx") }
    }
}
