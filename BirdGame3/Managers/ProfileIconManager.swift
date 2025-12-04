//
//  ProfileIconManager.swift
//  BirdGame3
//
//  Profile icon/avatar system - bird icons earned from Battle Pass and achievements
//

import Foundation
import SwiftUI

// MARK: - Profile Icon

struct ProfileIcon: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let imageName: String  // SF Symbol or asset name
    let emoji: String      // Fallback emoji
    let category: ProfileIconCategory
    let rarity: IconRarity
    let source: IconSource
    var isUnlocked: Bool
    
    static func == (lhs: ProfileIcon, rhs: ProfileIcon) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Profile Icon Category

enum ProfileIconCategory: String, Codable, CaseIterable {
    case birds
    case achievements
    case battlePass
    case special
    case seasonal
    
    var displayName: String {
        switch self {
        case .birds: return "Birds"
        case .achievements: return "Achievements"
        case .battlePass: return "Battle Pass"
        case .special: return "Special"
        case .seasonal: return "Seasonal"
        }
    }
}

// MARK: - Icon Rarity

enum IconRarity: String, Codable, CaseIterable {
    case common
    case rare
    case epic
    case legendary
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .common: return 2
        case .rare: return 3
        case .epic: return 4
        case .legendary: return 5
        }
    }
}

// MARK: - Icon Source

enum IconSource: String, Codable {
    case free           // Available by default
    case levelUp        // Earned by reaching certain levels
    case achievement    // Earned from achievements
    case battlePass     // Battle Pass rewards
    case purchase       // Purchased with currency
    case event          // Limited time events
    case hidden         // Secret/easter egg
}

// MARK: - Profile Icon Manager

class ProfileIconManager: ObservableObject {
    static let shared = ProfileIconManager()
    
    // MARK: - Published Properties
    
    @Published var icons: [ProfileIcon] = []
    @Published var equippedIconId: String = "icon_pigeon_default"
    
    // MARK: - Private Properties
    
    private let saveKey = "birdgame3_profileIcons"
    private let equippedKey = "birdgame3_equippedIcon"
    
    // MARK: - Initialization
    
    private init() {
        loadIcons()
        loadEquippedIcon()
    }
    
    // MARK: - Equipped Icon
    
    var equippedIcon: ProfileIcon? {
        icons.first { $0.id == equippedIconId }
    }
    
    func equipIcon(_ icon: ProfileIcon) {
        guard icon.isUnlocked else { return }
        equippedIconId = icon.id
        saveEquippedIcon()
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // MARK: - Unlocking
    
    func unlockIcon(_ iconId: String) {
        guard let index = icons.firstIndex(where: { $0.id == iconId && !$0.isUnlocked }) else { return }
        
        icons[index].isUnlocked = true
        saveIcons()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        VoiceChatManager.shared.speak("New profile icon unlocked!", priority: .normal)
    }
    
    // MARK: - Queries
    
    var unlockedIcons: [ProfileIcon] {
        icons.filter { $0.isUnlocked }
    }
    
    func icons(for category: ProfileIconCategory) -> [ProfileIcon] {
        icons.filter { $0.category == category }
    }
    
    func unlockedIcons(for category: ProfileIconCategory) -> [ProfileIcon] {
        icons.filter { $0.category == category && $0.isUnlocked }
    }
    
    // MARK: - Persistence
    
    private func saveIcons() {
        if let data = try? JSONEncoder().encode(icons) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
    
    private func loadIcons() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let saved = try? JSONDecoder().decode([ProfileIcon].self, from: data) {
            icons = saved
        } else {
            icons = createDefaultIcons()
            saveIcons()
        }
    }
    
    private func saveEquippedIcon() {
        UserDefaults.standard.set(equippedIconId, forKey: equippedKey)
    }
    
    private func loadEquippedIcon() {
        if let saved = UserDefaults.standard.string(forKey: equippedKey) {
            equippedIconId = saved
        }
    }
    
    // MARK: - Default Icons
    
    private func createDefaultIcons() -> [ProfileIcon] {
        return [
            // FREE BIRD ICONS (Default unlocked)
            ProfileIcon(id: "icon_pigeon_default", name: "Pigeon", imageName: "bird", emoji: "🐦", category: .birds, rarity: .common, source: .free, isUnlocked: true),
            ProfileIcon(id: "icon_eagle_default", name: "Eagle", imageName: "bird.fill", emoji: "🦅", category: .birds, rarity: .common, source: .free, isUnlocked: true),
            ProfileIcon(id: "icon_crow_default", name: "Crow", imageName: "bird", emoji: "🐦‍⬛", category: .birds, rarity: .common, source: .free, isUnlocked: true),
            ProfileIcon(id: "icon_hummingbird_default", name: "Hummingbird", imageName: "bird.fill", emoji: "🪶", category: .birds, rarity: .common, source: .free, isUnlocked: true),
            ProfileIcon(id: "icon_pelican_default", name: "Pelican", imageName: "bird", emoji: "🦤", category: .birds, rarity: .common, source: .free, isUnlocked: true),
            
            // LEVEL UP ICONS
            ProfileIcon(id: "icon_level_10", name: "Rising Star", imageName: "star.fill", emoji: "⭐", category: .achievements, rarity: .common, source: .levelUp, isUnlocked: false),
            ProfileIcon(id: "icon_level_25", name: "Veteran Bird", imageName: "medal.fill", emoji: "🎖️", category: .achievements, rarity: .rare, source: .levelUp, isUnlocked: false),
            ProfileIcon(id: "icon_level_50", name: "Max Level", imageName: "flame.fill", emoji: "🔥", category: .achievements, rarity: .epic, source: .levelUp, isUnlocked: false),
            
            // ACHIEVEMENT ICONS
            ProfileIcon(id: "icon_first_win", name: "First Victory", imageName: "trophy.fill", emoji: "🏆", category: .achievements, rarity: .common, source: .achievement, isUnlocked: false),
            ProfileIcon(id: "icon_100_wins", name: "Century", imageName: "100.circle.fill", emoji: "💯", category: .achievements, rarity: .epic, source: .achievement, isUnlocked: false),
            ProfileIcon(id: "icon_flawless", name: "Flawless", imageName: "sparkles", emoji: "✨", category: .achievements, rarity: .epic, source: .achievement, isUnlocked: false),
            ProfileIcon(id: "icon_nest_master", name: "Nest Master", imageName: "house.fill", emoji: "🪺", category: .achievements, rarity: .rare, source: .achievement, isUnlocked: false),
            
            // BATTLE PASS ICONS
            ProfileIcon(id: "icon_bp_tier_10", name: "Season Starter", imageName: "10.circle.fill", emoji: "🔟", category: .battlePass, rarity: .common, source: .battlePass, isUnlocked: false),
            ProfileIcon(id: "icon_bp_tier_25", name: "Climbing", imageName: "arrow.up.circle.fill", emoji: "📈", category: .battlePass, rarity: .rare, source: .battlePass, isUnlocked: false),
            ProfileIcon(id: "icon_bp_tier_50", name: "Halfway Hero", imageName: "star.circle.fill", emoji: "🌟", category: .battlePass, rarity: .rare, source: .battlePass, isUnlocked: false),
            ProfileIcon(id: "icon_bp_tier_75", name: "Elite", imageName: "crown.fill", emoji: "👑", category: .battlePass, rarity: .epic, source: .battlePass, isUnlocked: false),
            ProfileIcon(id: "icon_bp_tier_100", name: "Season Champion", imageName: "trophy.circle.fill", emoji: "🏅", category: .battlePass, rarity: .legendary, source: .battlePass, isUnlocked: false),
            
            // SPECIAL ICONS
            ProfileIcon(id: "icon_founder", name: "Founder", imageName: "building.columns.fill", emoji: "🏛️", category: .special, rarity: .legendary, source: .event, isUnlocked: false),
            ProfileIcon(id: "icon_prestige_1", name: "Prestige I", imageName: "star.fill", emoji: "⭐", category: .special, rarity: .epic, source: .levelUp, isUnlocked: false),
            ProfileIcon(id: "icon_prestige_5", name: "Prestige V", imageName: "star.circle.fill", emoji: "🌟", category: .special, rarity: .legendary, source: .levelUp, isUnlocked: false),
            ProfileIcon(id: "icon_prestige_10", name: "Prestige Master", imageName: "crown.fill", emoji: "👑", category: .special, rarity: .legendary, source: .levelUp, isUnlocked: false),
            
            // HIDDEN/EASTER EGG ICONS
            ProfileIcon(id: "icon_bowling", name: "Striker", imageName: "circle.fill", emoji: "🎳", category: .special, rarity: .legendary, source: .hidden, isUnlocked: false),
            ProfileIcon(id: "icon_chairbnb", name: "CHairBNB Host", imageName: "chair.fill", emoji: "🪑", category: .special, rarity: .legendary, source: .hidden, isUnlocked: false),
            
            // BIRD VARIANT ICONS
            ProfileIcon(id: "icon_pigeon_golden", name: "Golden Pigeon", imageName: "bird.fill", emoji: "🥇🐦", category: .birds, rarity: .epic, source: .levelUp, isUnlocked: false),
            ProfileIcon(id: "icon_eagle_thunder", name: "Thunder Eagle", imageName: "bolt.fill", emoji: "⚡🦅", category: .birds, rarity: .legendary, source: .battlePass, isUnlocked: false),
            ProfileIcon(id: "icon_crow_shadow", name: "Shadow Crow", imageName: "moon.fill", emoji: "🌑🐦‍⬛", category: .birds, rarity: .epic, source: .achievement, isUnlocked: false),
            ProfileIcon(id: "icon_hummingbird_rainbow", name: "Rainbow Hummingbird", imageName: "rainbow", emoji: "🌈🪶", category: .birds, rarity: .rare, source: .battlePass, isUnlocked: false),
            ProfileIcon(id: "icon_pelican_pirate", name: "Pirate Pelican", imageName: "flag.fill", emoji: "🏴‍☠️🦤", category: .birds, rarity: .legendary, source: .levelUp, isUnlocked: false),
        ]
    }
}
