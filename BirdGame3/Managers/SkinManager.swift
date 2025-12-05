//
//  SkinManager.swift
//  BirdGame3
//
//  Manages bird skins, cosmetics, and unlockables
//

import Foundation
import SwiftUI

// MARK: - Bird Skin

struct BirdSkin: Identifiable, Codable, Equatable {
    let id: String
    let birdType: String // BirdType.rawValue
    let name: String
    let description: String
    let rarity: SkinRarity
    let colorScheme: SkinColorScheme
    let price: SkinPrice
    let unlockRequirement: UnlockRequirement?
    
    var isDefault: Bool {
        id.hasSuffix("_default")
    }
}

// MARK: - Skin Rarity

enum SkinRarity: String, Codable, CaseIterable {
    case common
    case rare
    case epic
    case legendary
    case mythic
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        case .mythic: return .red
        }
    }
    
    var glowColor: Color {
        switch self {
        case .common: return .clear
        case .rare: return .blue.opacity(0.3)
        case .epic: return .purple.opacity(0.4)
        case .legendary: return .orange.opacity(0.5)
        case .mythic: return .red.opacity(0.6)
        }
    }
}

// MARK: - Skin Color Scheme

struct SkinColorScheme: Codable, Equatable {
    let primary: String // Hex color
    let secondary: String
    let accent: String
    let effect: SkinEffect?
    
    enum SkinEffect: String, Codable {
        case glow
        case sparkle
        case fire
        case ice
        case electric
        case shadow
        case rainbow
    }
}

// MARK: - Skin Price

struct SkinPrice: Codable, Equatable {
    let coins: Int
    let feathers: Int
    
    static let free = SkinPrice(coins: 0, feathers: 0)
    
    var isFree: Bool {
        coins == 0 && feathers == 0
    }
}

// MARK: - Unlock Requirement

struct UnlockRequirement: Codable, Equatable {
    let type: RequirementType
    let value: Int
    let description: String
    
    enum RequirementType: String, Codable {
        case wins
        case prestigeLevel
        case arcadeStage
        case perfectWins
        case birdWins // Wins with specific bird
    }
}

// MARK: - Skin Manager

class SkinManager: ObservableObject {
    static let shared = SkinManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var ownedSkins: Set<String> = []
    @Published private(set) var equippedSkins: [String: String] = [:] // BirdType.rawValue: SkinID
    
    // MARK: - All Available Skins
    
    let allSkins: [BirdSkin] = {
        var skins: [BirdSkin] = []
        
        // PIGEON SKINS
        skins.append(contentsOf: [
            BirdSkin(
                id: "pigeon_default",
                birdType: "pigeon",
                name: "City Pigeon",
                description: "The classic urban warrior. Coo coo.",
                rarity: .common,
                colorScheme: SkinColorScheme(primary: "#808080", secondary: "#606060", accent: "#A0A0A0", effect: nil),
                price: .free,
                unlockRequirement: nil
            ),
            BirdSkin(
                id: "pigeon_golden",
                birdType: "pigeon",
                name: "Golden Pigeon",
                description: "Dripped out in gold. Still eats breadcrumbs.",
                rarity: .rare,
                colorScheme: SkinColorScheme(primary: "#FFD700", secondary: "#DAA520", accent: "#FFF8DC", effect: .glow),
                price: SkinPrice(coins: 500, feathers: 0),
                unlockRequirement: nil
            ),
            BirdSkin(
                id: "pigeon_neon",
                birdType: "pigeon",
                name: "Neon Pigeon",
                description: "Cyberpunk coo coo in the year 2077.",
                rarity: .epic,
                colorScheme: SkinColorScheme(primary: "#FF00FF", secondary: "#00FFFF", accent: "#FF1493", effect: .electric),
                price: SkinPrice(coins: 1500, feathers: 5),
                unlockRequirement: nil
            ),
            BirdSkin(
                id: "pigeon_divine",
                birdType: "pigeon",
                name: "Divine Messenger",
                description: "Legend says this pigeon delivered messages for the gods.",
                rarity: .legendary,
                colorScheme: SkinColorScheme(primary: "#FFFFFF", secondary: "#FFD700", accent: "#E6E6FA", effect: .sparkle),
                price: SkinPrice(coins: 0, feathers: 25),
                unlockRequirement: UnlockRequirement(type: .wins, value: 50, description: "Win 50 battles")
            ),
            BirdSkin(
                id: "pigeon_void",
                birdType: "pigeon",
                name: "Void Walker",
                description: "From the depths of the pigeon dimension.",
                rarity: .mythic,
                colorScheme: SkinColorScheme(primary: "#1a1a2e", secondary: "#16213e", accent: "#0f3460", effect: .shadow),
                price: SkinPrice(coins: 0, feathers: 50),
                unlockRequirement: UnlockRequirement(type: .prestigeLevel, value: 3, description: "Reach Prestige 3")
            ),
            // NEW PIGEON SKINS - Urban, Fancy, Custom Names
            BirdSkin(
                id: "pigeon_urban",
                birdType: "pigeon",
                name: "Urban Pigeon",
                description: "Street smart and city tough. Born in the concrete jungle.",
                rarity: .rare,
                colorScheme: SkinColorScheme(primary: "#4A4A4A", secondary: "#2D2D2D", accent: "#808080", effect: nil),
                price: SkinPrice(coins: 350, feathers: 0),
                unlockRequirement: nil
            ),
            BirdSkin(
                id: "pigeon_fancy",
                birdType: "pigeon",
                name: "Fancy Pigeon",
                description: "Top hat, monocle, and impeccable manners. Tea time, anyone?",
                rarity: .epic,
                colorScheme: SkinColorScheme(primary: "#8B4513", secondary: "#D2691E", accent: "#FFD700", effect: .sparkle),
                price: SkinPrice(coins: 1200, feathers: 3),
                unlockRequirement: nil
            ),
            BirdSkin(
                id: "pigeon_custom_names",
                birdType: "pigeon",
                name: "Custom Names",
                description: "A pigeon so cool, it gets a custom name tag. You are THE pigeon.",
                rarity: .legendary,
                colorScheme: SkinColorScheme(primary: "#FF6B6B", secondary: "#4ECDC4", accent: "#FFE66D", effect: .rainbow),
                price: SkinPrice(coins: 2500, feathers: 15),
                unlockRequirement: nil
            )
        ])
        
        // HUMMINGBIRD SKINS
        skins.append(contentsOf: [
            BirdSkin(
                id: "hummingbird_default",
                birdType: "hummingbird",
                name: "Ruby-Throat",
                description: "Still OP after 47 nerfs.",
                rarity: .common,
                colorScheme: SkinColorScheme(primary: "#228B22", secondary: "#FF0000", accent: "#90EE90", effect: nil),
                price: .free,
                unlockRequirement: nil
            ),
            BirdSkin(
                id: "hummingbird_crystal",
                birdType: "hummingbird",
                name: "Crystal Wings",
                description: "So fast it looks like glass in motion.",
                rarity: .rare,
                colorScheme: SkinColorScheme(primary: "#E0FFFF", secondary: "#87CEEB", accent: "#B0E0E6", effect: .sparkle),
                price: SkinPrice(coins: 500, feathers: 0),
                unlockRequirement: nil
            ),
            BirdSkin(
                id: "hummingbird_phoenix",
                birdType: "hummingbird",
                name: "Phoenix Hum",
                description: "Burns so bright, devs had to nerf it again.",
                rarity: .epic,
                colorScheme: SkinColorScheme(primary: "#FF4500", secondary: "#FF6347", accent: "#FFD700", effect: .fire),
                price: SkinPrice(coins: 1500, feathers: 5),
                unlockRequirement: nil
            ),
            BirdSkin(
                id: "hummingbird_galaxy",
                birdType: "hummingbird",
                name: "Cosmic Zephyr",
                description: "Contains an entire galaxy in its tiny body.",
                rarity: .legendary,
                colorScheme: SkinColorScheme(primary: "#191970", secondary: "#4B0082", accent: "#9400D3", effect: .rainbow),
                price: SkinPrice(coins: 0, feathers: 25),
                unlockRequirement: UnlockRequirement(type: .perfectWins, value: 10, description: "Get 10 perfect wins")
            ),
            // NEW HUMMINGBIRD SKINS - Rainbow Glow, Sapphire Shine
            BirdSkin(
                id: "hummingbird_rainbow_glow",
                birdType: "hummingbird",
                name: "Rainbow Glow",
                description: "Every color of the spectrum, all at 80 wingbeats per second.",
                rarity: .epic,
                colorScheme: SkinColorScheme(primary: "#FF0000", secondary: "#00FF00", accent: "#0000FF", effect: .rainbow),
                price: SkinPrice(coins: 1800, feathers: 8),
                unlockRequirement: nil
            ),
            BirdSkin(
                id: "hummingbird_sapphire_shine",
                birdType: "hummingbird",
                name: "Sapphire Shine",
                description: "Deep blue brilliance that mesmerizes opponents mid-combo.",
                rarity: .legendary,
                colorScheme: SkinColorScheme(primary: "#0F52BA", secondary: "#1E90FF", accent: "#87CEEB", effect: .glow),
                price: SkinPrice(coins: 0, feathers: 30),
                unlockRequirement: UnlockRequirement(type: .birdWins, value: 30, description: "Win 30 battles as Hummingbird")
            )
        ])
        
        // EAGLE SKINS
        skins.append(contentsOf: [
            BirdSkin(
                id: "eagle_default",
                birdType: "eagle",
                name: "Bald Eagle",
                description: "FREEDOM INTENSIFIES 🇺🇸",
                rarity: .common,
                colorScheme: SkinColorScheme(primary: "#8B4513", secondary: "#FFFFFF", accent: "#FFD700", effect: nil),
                price: .free,
                unlockRequirement: nil
            ),
            BirdSkin(
                id: "eagle_steel",
                birdType: "eagle",
                name: "Steel Talon",
                description: "Forged in the fires of democracy.",
                rarity: .rare,
                colorScheme: SkinColorScheme(primary: "#708090", secondary: "#C0C0C0", accent: "#B8860B", effect: .glow),
                price: SkinPrice(coins: 500, feathers: 0),
                unlockRequirement: nil
            ),
            BirdSkin(
                id: "eagle_patriot",
                birdType: "eagle",
                name: "Star Spangled",
                description: "Red, white, and absolutely OP.",
                rarity: .epic,
                colorScheme: SkinColorScheme(primary: "#B22234", secondary: "#FFFFFF", accent: "#3C3B6E", effect: .sparkle),
                price: SkinPrice(coins: 1500, feathers: 5),
                unlockRequirement: nil
            ),
            BirdSkin(
                id: "eagle_thunder",
                birdType: "eagle",
                name: "Thunderbird",
                description: "Calls down lightning with every dive.",
                rarity: .legendary,
                colorScheme: SkinColorScheme(primary: "#1E90FF", secondary: "#FFD700", accent: "#87CEEB", effect: .electric),
                price: SkinPrice(coins: 0, feathers: 25),
                unlockRequirement: UnlockRequirement(type: .birdWins, value: 25, description: "Win 25 battles as Eagle")
            ),
            // NEW EAGLE SKINS - Spotted, Clear Majestic
            BirdSkin(
                id: "eagle_spotted",
                birdType: "eagle",
                name: "Spotted Eagle",
                description: "Camouflaged hunter of the mountain ranges. Spots everything.",
                rarity: .rare,
                colorScheme: SkinColorScheme(primary: "#8B7355", secondary: "#D2B48C", accent: "#F5DEB3", effect: nil),
                price: SkinPrice(coins: 600, feathers: 0),
                unlockRequirement: nil
            ),
            BirdSkin(
                id: "eagle_clear_majestic",
                birdType: "eagle",
                name: "Clear Majestic",
                description: "Crystal clarity, majestic presence. FREEDOM in its purest form.",
                rarity: .mythic,
                colorScheme: SkinColorScheme(primary: "#E8E8E8", secondary: "#FFFAFA", accent: "#F0F8FF", effect: .sparkle),
                price: SkinPrice(coins: 0, feathers: 60),
                unlockRequirement: UnlockRequirement(type: .prestigeLevel, value: 5, description: "Reach Prestige 5")
            )
        ])
        
        // CROW SKINS
        skins.append(contentsOf: [
            BirdSkin(
                id: "crow_default",
                birdType: "crow",
                name: "Common Crow",
                description: "Knows your secrets. All of them.",
                rarity: .common,
                colorScheme: SkinColorScheme(primary: "#000000", secondary: "#1a1a1a", accent: "#4a4a4a", effect: nil),
                price: .free,
                unlockRequirement: nil
            ),
            BirdSkin(
                id: "crow_phantom",
                birdType: "crow",
                name: "Phantom Crow",
                description: "Now you see it, now you don't.",
                rarity: .rare,
                colorScheme: SkinColorScheme(primary: "#2F4F4F", secondary: "#696969", accent: "#A9A9A9", effect: .shadow),
                price: SkinPrice(coins: 500, feathers: 0),
                unlockRequirement: nil
            ),
            BirdSkin(
                id: "crow_plague",
                birdType: "crow",
                name: "Plague Doctor",
                description: "The cure is more violence.",
                rarity: .epic,
                colorScheme: SkinColorScheme(primary: "#1a1a1a", secondary: "#8B0000", accent: "#006400", effect: nil),
                price: SkinPrice(coins: 1500, feathers: 5),
                unlockRequirement: nil
            ),
            BirdSkin(
                id: "crow_odin",
                birdType: "crow",
                name: "Huginn",
                description: "Odin's own messenger. Knows EVERYTHING.",
                rarity: .legendary,
                colorScheme: SkinColorScheme(primary: "#4169E1", secondary: "#000080", accent: "#FFD700", effect: .glow),
                price: SkinPrice(coins: 0, feathers: 25),
                unlockRequirement: UnlockRequirement(type: .arcadeStage, value: 10, description: "Complete Arcade Stage 10")
            )
        ])
        
        // PELICAN SKINS
        skins.append(contentsOf: [
            BirdSkin(
                id: "pelican_default",
                birdType: "pelican",
                name: "Beach Pelican",
                description: "Thicc boy energy. Pocket dimension mouth.",
                rarity: .common,
                colorScheme: SkinColorScheme(primary: "#FFFFFF", secondary: "#FFD700", accent: "#FFA500", effect: nil),
                price: .free,
                unlockRequirement: nil
            ),
            BirdSkin(
                id: "pelican_pirate",
                birdType: "pelican",
                name: "Captain Beak",
                description: "Arr! That fish be mine!",
                rarity: .rare,
                colorScheme: SkinColorScheme(primary: "#8B4513", secondary: "#000000", accent: "#FF0000", effect: nil),
                price: SkinPrice(coins: 500, feathers: 0),
                unlockRequirement: nil
            ),
            BirdSkin(
                id: "pelican_arctic",
                birdType: "pelican",
                name: "Frost Beak",
                description: "Cold fish slaps hit different.",
                rarity: .epic,
                colorScheme: SkinColorScheme(primary: "#E0FFFF", secondary: "#87CEEB", accent: "#00CED1", effect: .ice),
                price: SkinPrice(coins: 1500, feathers: 5),
                unlockRequirement: nil
            ),
            BirdSkin(
                id: "pelican_kraken",
                birdType: "pelican",
                name: "Kraken's Chosen",
                description: "That pouch leads to the deep...",
                rarity: .legendary,
                colorScheme: SkinColorScheme(primary: "#2E0854", secondary: "#006064", accent: "#00BCD4", effect: .shadow),
                price: SkinPrice(coins: 0, feathers: 25),
                unlockRequirement: UnlockRequirement(type: .wins, value: 100, description: "Win 100 battles total")
            ),
            // NEW PELICAN SKINS - Inner Rage Cage variants
            BirdSkin(
                id: "pelican_inner_rage",
                birdType: "pelican",
                name: "Inner Rage",
                description: "The fury inside that pouch is barely contained. RELEASE THE FISH!",
                rarity: .epic,
                colorScheme: SkinColorScheme(primary: "#DC143C", secondary: "#8B0000", accent: "#FF4500", effect: .fire),
                price: SkinPrice(coins: 1800, feathers: 8),
                unlockRequirement: nil
            ),
            BirdSkin(
                id: "pelican_cage_breaker",
                birdType: "pelican",
                name: "Cage Breaker",
                description: "The rage cage has been expanded. Nothing can contain this thicc boy now.",
                rarity: .legendary,
                colorScheme: SkinColorScheme(primary: "#4B0082", secondary: "#9400D3", accent: "#FF1493", effect: .electric),
                price: SkinPrice(coins: 0, feathers: 35),
                unlockRequirement: UnlockRequirement(type: .birdWins, value: 40, description: "Win 40 battles as Pelican")
            ),
            BirdSkin(
                id: "pelican_void_pouch",
                birdType: "pelican",
                name: "Void Pouch",
                description: "That pouch doesn't just hold fish... it holds entire dimensions of RAGE.",
                rarity: .mythic,
                colorScheme: SkinColorScheme(primary: "#0D0D0D", secondary: "#1C1C1C", accent: "#6A0DAD", effect: .shadow),
                price: SkinPrice(coins: 0, feathers: 75),
                unlockRequirement: UnlockRequirement(type: .prestigeLevel, value: 4, description: "Reach Prestige 4")
            )
        ])
        
        return skins
    }()
    
    // MARK: - Persistence Keys
    
    private let ownedSkinsKey = "birdgame3_ownedSkins"
    private let equippedSkinsKey = "birdgame3_equippedSkins"
    
    // MARK: - Initialization
    
    private init() {
        loadData()
        
        // Ensure all default skins are owned
        for birdType in BirdType.allCases {
            let defaultSkinId = "\(birdType.rawValue)_default"
            ownedSkins.insert(defaultSkinId)
            
            // Equip default if nothing equipped
            if equippedSkins[birdType.rawValue] == nil {
                equippedSkins[birdType.rawValue] = defaultSkinId
            }
        }
        saveData()
    }
    
    // MARK: - Public Methods
    
    /// Get all skins for a specific bird type
    func skins(for birdType: BirdType) -> [BirdSkin] {
        allSkins.filter { $0.birdType == birdType.rawValue }
    }
    
    /// Check if player owns a skin
    func owns(skinId: String) -> Bool {
        ownedSkins.contains(skinId)
    }
    
    /// Get the currently equipped skin for a bird type
    func equippedSkin(for birdType: BirdType) -> BirdSkin? {
        guard let skinId = equippedSkins[birdType.rawValue] else { return nil }
        return allSkins.first { $0.id == skinId }
    }
    
    /// Purchase a skin
    func purchase(skin: BirdSkin) -> Bool {
        guard !owns(skinId: skin.id) else { return false }
        
        let currency = CurrencyManager.shared
        guard currency.canAfford(coins: skin.price.coins, feathers: skin.price.feathers) else {
            return false
        }
        
        // Spend currency
        if skin.price.coins > 0 {
            _ = currency.spendCoins(skin.price.coins)
        }
        if skin.price.feathers > 0 {
            _ = currency.spendFeathers(skin.price.feathers)
        }
        
        // Grant skin
        ownedSkins.insert(skin.id)
        saveData()
        return true
    }
    
    /// Unlock a skin (for achievement unlocks, doesn't cost currency)
    func unlock(skinId: String) {
        ownedSkins.insert(skinId)
        saveData()
    }
    
    /// Equip a skin
    func equip(skin: BirdSkin) -> Bool {
        guard owns(skinId: skin.id) else { return false }
        equippedSkins[skin.birdType] = skin.id
        saveData()
        return true
    }
    
    /// Check if player meets unlock requirement
    func meetsRequirement(_ requirement: UnlockRequirement, playerStats: PlayerStats, prestigeLevel: Int) -> Bool {
        switch requirement.type {
        case .wins:
            return playerStats.wins >= requirement.value
        case .prestigeLevel:
            return prestigeLevel >= requirement.value
        case .arcadeStage:
            return false // Would need arcade progress tracking
        case .perfectWins:
            return playerStats.perfectWins >= requirement.value
        case .birdWins:
            return false // Would need per-bird win tracking
        }
    }
    
    // MARK: - Persistence
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: ownedSkinsKey),
           let skins = try? JSONDecoder().decode(Set<String>.self, from: data) {
            ownedSkins = skins
        }
        
        if let data = UserDefaults.standard.data(forKey: equippedSkinsKey),
           let equipped = try? JSONDecoder().decode([String: String].self, from: data) {
            equippedSkins = equipped
        }
    }
    
    private func saveData() {
        if let data = try? JSONEncoder().encode(ownedSkins) {
            UserDefaults.standard.set(data, forKey: ownedSkinsKey)
        }
        
        if let data = try? JSONEncoder().encode(equippedSkins) {
            UserDefaults.standard.set(data, forKey: equippedSkinsKey)
        }
    }
    
    /// Reset all skins (for testing)
    func reset() {
        ownedSkins = Set(BirdType.allCases.map { "\($0.rawValue)_default" })
        equippedSkins = Dictionary(uniqueKeysWithValues: BirdType.allCases.map { ($0.rawValue, "\($0.rawValue)_default") })
        saveData()
    }
}
