//
//  Localizable.swift
//  BirdGame3
//
//  Localization infrastructure for App Store international support
//

import Foundation
import SwiftUI

// MARK: - Localization Manager

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    // MARK: - Published Properties
    
    @Published var currentLanguage: AppLanguage
    
    // MARK: - Supported Languages
    
    enum AppLanguage: String, CaseIterable, Identifiable {
        case english = "en"
        case spanish = "es"
        case french = "fr"
        case german = "de"
        case italian = "it"
        case portuguese = "pt"
        case japanese = "ja"
        case korean = "ko"
        case chineseSimplified = "zh-Hans"
        case chineseTraditional = "zh-Hant"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .spanish: return "Español"
            case .french: return "Français"
            case .german: return "Deutsch"
            case .italian: return "Italiano"
            case .portuguese: return "Português"
            case .japanese: return "日本語"
            case .korean: return "한국어"
            case .chineseSimplified: return "简体中文"
            case .chineseTraditional: return "繁體中文"
            }
        }
        
        var nativeName: String {
            displayName
        }
    }
    
    // MARK: - Private Properties
    
    private let saveKey = "birdgame3_language"
    
    // MARK: - Initialization
    
    private init() {
        // Default to system language or English
        if let saved = UserDefaults.standard.string(forKey: saveKey),
           let language = AppLanguage(rawValue: saved) {
            currentLanguage = language
        } else {
            currentLanguage = Self.systemLanguage
        }
    }
    
    // MARK: - Language Detection
    
    static var systemLanguage: AppLanguage {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        
        for language in AppLanguage.allCases {
            if preferredLanguage.starts(with: language.rawValue) {
                return language
            }
        }
        
        return .english
    }
    
    // MARK: - Language Switching
    
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: saveKey)
        
        // Update app bundle for localized strings
        // Note: In production, this would trigger app restart or view refresh
    }
    
    // MARK: - Localized Strings
    
    func localized(_ key: String) -> String {
        // In production, this would fetch from Localizable.strings files
        // For now, returns the key or default English
        return localizedStrings[key] ?? key
    }
}

// MARK: - Localized String Keys

/// String keys for localization
/// In production, these would be in Localizable.strings files for each language
enum LocalizedKey: String {
    // General
    case appName = "app_name"
    case ok = "ok"
    case cancel = "cancel"
    case confirm = "confirm"
    case back = "back"
    case done = "done"
    case save = "save"
    case delete = "delete"
    case edit = "edit"
    case loading = "loading"
    case error = "error"
    case success = "success"
    case retry = "retry"
    
    // Main Menu
    case play = "play"
    case playOnline = "play_online"
    case quickMatch = "quick_match"
    case arcadeMode = "arcade_mode"
    case training = "training"
    case openWorld = "open_world"
    case shop = "shop"
    case settings = "settings"
    case profile = "profile"
    
    // Character Select
    case selectCharacter = "select_character"
    case selectBird = "select_bird"
    case locked = "locked"
    case equip = "equip"
    case equipped = "equipped"
    
    // Game
    case attack = "attack"
    case block = "block"
    case sprint = "sprint"
    case ability = "ability"
    case pause = "pause"
    case resume = "resume"
    case quit = "quit"
    case victory = "victory"
    case defeat = "defeat"
    
    // Shop
    case buy = "buy"
    case purchase = "purchase"
    case owned = "owned"
    case coins = "coins"
    case feathers = "feathers"
    case notEnoughCurrency = "not_enough_currency"
    
    // Social
    case friends = "friends"
    case party = "party"
    case invite = "invite"
    case join = "join"
    case leave = "leave"
    case kick = "kick"
    case mute = "mute"
    case unmute = "unmute"
    case block = "block_user"
    case report = "report"
    
    // Settings
    case sound = "sound"
    case music = "music"
    case notifications = "notifications"
    case language = "language"
    case privacy = "privacy"
    case terms = "terms"
    case support = "support"
    case logout = "logout"
    case deleteAccount = "delete_account"
}

// MARK: - Default English Strings

private let localizedStrings: [String: String] = [
    // General
    "app_name": "Bird Game 3",
    "ok": "OK",
    "cancel": "Cancel",
    "confirm": "Confirm",
    "back": "Back",
    "done": "Done",
    "save": "Save",
    "delete": "Delete",
    "edit": "Edit",
    "loading": "Loading...",
    "error": "Error",
    "success": "Success",
    "retry": "Retry",
    
    // Main Menu
    "play": "PLAY",
    "play_online": "PLAY ONLINE",
    "quick_match": "QUICK MATCH",
    "arcade_mode": "ARCADE MODE",
    "training": "TRAINING",
    "open_world": "OPEN WORLD",
    "shop": "SHOP",
    "settings": "SETTINGS",
    "profile": "PROFILE",
    
    // Character Select
    "select_character": "SELECT CHARACTER",
    "select_bird": "SELECT YOUR BIRD",
    "locked": "LOCKED",
    "equip": "EQUIP",
    "equipped": "EQUIPPED",
    
    // Game
    "attack": "ATTACK",
    "block": "BLOCK",
    "sprint": "SPRINT",
    "ability": "ABILITY",
    "pause": "PAUSE",
    "resume": "RESUME",
    "quit": "QUIT",
    "victory": "VICTORY!",
    "defeat": "DEFEAT",
    
    // Shop
    "buy": "BUY",
    "purchase": "PURCHASE",
    "owned": "OWNED",
    "coins": "Coins",
    "feathers": "Feathers",
    "not_enough_currency": "Not enough currency",
    
    // Social
    "friends": "Friends",
    "party": "Party",
    "invite": "Invite",
    "join": "Join",
    "leave": "Leave",
    "kick": "Kick",
    "mute": "Mute",
    "unmute": "Unmute",
    "block_user": "Block",
    "report": "Report",
    
    // Settings
    "sound": "Sound",
    "music": "Music",
    "notifications": "Notifications",
    "language": "Language",
    "privacy": "Privacy Policy",
    "terms": "Terms of Service",
    "support": "Support",
    "logout": "Log Out",
    "delete_account": "Delete Account",
]

// MARK: - String Extension

extension String {
    var localized: String {
        LocalizationManager.shared.localized(self)
    }
    
    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}

// MARK: - SwiftUI Text Extension

extension Text {
    init(localized key: String) {
        self.init(key.localized)
    }
    
    init(localized key: LocalizedKey) {
        self.init(key.rawValue.localized)
    }
}
