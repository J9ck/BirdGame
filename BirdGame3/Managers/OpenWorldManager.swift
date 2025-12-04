//
//  OpenWorldManager.swift
//  BirdGame3
//
//  Rust-style open world with nest building and survival mechanics
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - World Position

struct WorldPosition: Codable, Equatable {
    var x: Double
    var y: Double
    var z: Double // Altitude
    
    static let zero = WorldPosition(x: 0, y: 0, z: 0)
    
    func distance(to other: WorldPosition) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        let dz = z - other.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
}

// MARK: - Biome

enum Biome: String, Codable, CaseIterable {
    case forest
    case desert
    case mountain
    case swamp
    case beach
    case tundra
    case jungle
    case plains
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var emoji: String {
        switch self {
        case .forest: return "🌲"
        case .desert: return "🏜️"
        case .mountain: return "🏔️"
        case .swamp: return "🐊"
        case .beach: return "🏖️"
        case .tundra: return "❄️"
        case .jungle: return "🌴"
        case .plains: return "🌾"
        }
    }
    
    var resourceMultiplier: Double {
        switch self {
        case .forest: return 1.5
        case .jungle: return 1.3
        case .plains: return 1.0
        case .beach: return 0.8
        case .swamp: return 1.1
        case .mountain: return 0.7
        case .desert: return 0.5
        case .tundra: return 0.6
        }
    }
    
    var dangerLevel: Int {
        switch self {
        case .plains: return 1
        case .forest: return 2
        case .beach: return 2
        case .jungle: return 3
        case .swamp: return 3
        case .mountain: return 4
        case .desert: return 4
        case .tundra: return 5
        }
    }
}

// MARK: - Resource

struct Resource: Identifiable, Codable {
    let id: String
    let type: ResourceType
    var amount: Int
    let position: WorldPosition
    var lastHarvested: Date?
    
    var canHarvest: Bool {
        guard let last = lastHarvested else { return true }
        return Date().timeIntervalSince(last) > type.respawnTime
    }
}

enum ResourceType: String, Codable, CaseIterable {
    case twigs
    case leaves
    case feathers
    case berries
    case bugs
    case shinyObjects
    case moss
    case mud
    
    var displayName: String {
        switch self {
        case .twigs: return "Twigs"
        case .leaves: return "Leaves"
        case .feathers: return "Feathers"
        case .berries: return "Berries"
        case .bugs: return "Bugs"
        case .shinyObjects: return "Shiny Objects"
        case .moss: return "Moss"
        case .mud: return "Mud"
        }
    }
    
    var emoji: String {
        switch self {
        case .twigs: return "🪵"
        case .leaves: return "🍃"
        case .feathers: return "🪶"
        case .berries: return "🫐"
        case .bugs: return "🐛"
        case .shinyObjects: return "✨"
        case .moss: return "🌿"
        case .mud: return "🟤"
        }
    }
    
    var respawnTime: TimeInterval {
        switch self {
        case .twigs: return 300 // 5 min
        case .leaves: return 180 // 3 min
        case .feathers: return 600 // 10 min
        case .berries: return 240 // 4 min
        case .bugs: return 120 // 2 min
        case .shinyObjects: return 900 // 15 min
        case .moss: return 420 // 7 min
        case .mud: return 60 // 1 min
        }
    }
    
    var baseYield: Int {
        switch self {
        case .twigs: return 5
        case .leaves: return 8
        case .feathers: return 2
        case .berries: return 10
        case .bugs: return 6
        case .shinyObjects: return 1
        case .moss: return 4
        case .mud: return 15
        }
    }
}

// MARK: - Nest

struct Nest: Identifiable, Codable {
    let id: String
    var ownerId: String
    var ownerName: String
    var position: WorldPosition
    var level: Int
    var health: Double
    var maxHealth: Double
    var components: [NestComponent]
    var storage: [ResourceType: Int]
    var defenses: [NestDefense]
    var lastRaided: Date?
    var createdAt: Date
    
    var isProtected: Bool {
        // 30 minute raid protection after being raided
        guard let lastRaid = lastRaided else { return false }
        return Date().timeIntervalSince(lastRaid) < 1800
    }
    
    var storageCapacity: Int {
        100 + (level * 50) + components.filter { $0.type == .storageBox }.count * 25
    }
    
    var totalStoredItems: Int {
        storage.values.reduce(0, +)
    }
    
    mutating func upgrade() -> Bool {
        guard level < 10 else { return false }
        level += 1
        maxHealth += 50
        health = maxHealth
        return true
    }
}

// MARK: - Nest Component

struct NestComponent: Identifiable, Codable {
    let id: String
    let type: NestComponentType
    var health: Double
    var position: NestPosition // Relative position in nest
}

enum NestComponentType: String, Codable, CaseIterable {
    case foundation
    case wall
    case roof
    case door
    case window
    case storageBox
    case perch
    case decoration
    case trap
    
    var displayName: String {
        switch self {
        case .foundation: return "Foundation"
        case .wall: return "Wall"
        case .roof: return "Roof"
        case .door: return "Door"
        case .window: return "Window"
        case .storageBox: return "Storage Box"
        case .perch: return "Perch"
        case .decoration: return "Decoration"
        case .trap: return "Bird Trap"
        }
    }
    
    var emoji: String {
        switch self {
        case .foundation: return "🟫"
        case .wall: return "🧱"
        case .roof: return "🏠"
        case .door: return "🚪"
        case .window: return "🪟"
        case .storageBox: return "📦"
        case .perch: return "🪵"
        case .decoration: return "🎀"
        case .trap: return "🪤"
        }
    }
    
    var requiredResources: [ResourceType: Int] {
        switch self {
        case .foundation: return [.twigs: 20, .mud: 10]
        case .wall: return [.twigs: 10, .leaves: 5]
        case .roof: return [.leaves: 15, .twigs: 5]
        case .door: return [.twigs: 8, .feathers: 2]
        case .window: return [.shinyObjects: 1, .twigs: 4]
        case .storageBox: return [.twigs: 15, .leaves: 10]
        case .perch: return [.twigs: 5]
        case .decoration: return [.shinyObjects: 2, .feathers: 5]
        case .trap: return [.twigs: 10, .bugs: 5, .shinyObjects: 1]
        }
    }
    
    var health: Double {
        switch self {
        case .foundation: return 200
        case .wall: return 100
        case .roof: return 80
        case .door: return 50
        case .window: return 30
        case .storageBox: return 40
        case .perch: return 20
        case .decoration: return 10
        case .trap: return 25
        }
    }
}

struct NestPosition: Codable {
    var gridX: Int
    var gridY: Int
    var layer: Int // 0 = foundation, 1 = walls, 2 = roof
}

// MARK: - Nest Defense

struct NestDefense: Identifiable, Codable {
    let id: String
    let type: DefenseType
    var ammo: Int
    var isActive: Bool
}

enum DefenseType: String, Codable {
    case spikeTrap
    case alarmFeathers
    case guardCrow
    case shinyDecoy
    
    var displayName: String {
        switch self {
        case .spikeTrap: return "Spike Trap"
        case .alarmFeathers: return "Alarm Feathers"
        case .guardCrow: return "Guard Crow"
        case .shinyDecoy: return "Shiny Decoy"
        }
    }
    
    var damage: Double {
        switch self {
        case .spikeTrap: return 25
        case .alarmFeathers: return 0
        case .guardCrow: return 15
        case .shinyDecoy: return 0
        }
    }
}

// MARK: - Player World State

struct PlayerWorldState: Codable {
    var position: WorldPosition
    var currentBiome: Biome
    var inventory: [ResourceType: Int]
    var hunger: Double // 0-100
    var energy: Double // 0-100
    var health: Double // 0-100
    var homeNestId: String?
    var discoveredBiomes: Set<String>
    var lastPosition: WorldPosition?
    
    static func new() -> PlayerWorldState {
        PlayerWorldState(
            position: WorldPosition(x: 0, y: 0, z: 50),
            currentBiome: .plains,
            inventory: [:],
            hunger: 100,
            energy: 100,
            health: 100,
            homeNestId: nil,
            discoveredBiomes: ["plains"],
            lastPosition: nil
        )
    }
    
    var inventoryCount: Int {
        inventory.values.reduce(0, +)
    }
    
    var maxInventory: Int {
        50 // Base inventory size
    }
    
    var canCarryMore: Bool {
        inventoryCount < maxInventory
    }
    
    mutating func addResource(_ type: ResourceType, amount: Int) -> Int {
        let space = maxInventory - inventoryCount
        let actualAmount = min(amount, space)
        inventory[type, default: 0] += actualAmount
        return actualAmount
    }
    
    mutating func removeResource(_ type: ResourceType, amount: Int) -> Bool {
        guard let current = inventory[type], current >= amount else { return false }
        inventory[type] = current - amount
        if inventory[type] == 0 {
            inventory.removeValue(forKey: type)
        }
        return true
    }
}

// MARK: - Open World Manager

class OpenWorldManager: ObservableObject {
    static let shared = OpenWorldManager()
    
    // MARK: - Published Properties
    
    @Published var playerState: PlayerWorldState
    @Published var nearbyResources: [Resource] = []
    @Published var nearbyNests: [Nest] = []
    @Published var nearbyPlayers: [WorldPlayer] = []
    @Published var currentWeather: Weather = .clear
    @Published var timeOfDay: TimeOfDay = .day
    @Published var worldEvents: [WorldEvent] = []
    
    // Player's nest
    @Published var homeNest: Nest?
    
    // MARK: - Constants
    
    private let resourceScanRadius: Double = 100
    private let nestScanRadius: Double = 200
    private let hungerDecayRate: Double = 0.1 // Per second
    private let energyDecayRate: Double = 0.05
    
    // MARK: - Persistence Keys
    
    private let playerStateKey = "birdgame3_openworld_playerState"
    private let homeNestKey = "birdgame3_openworld_homeNest"
    
    // MARK: - Initialization
    
    private init() {
        // Load saved state or create new
        if let data = UserDefaults.standard.data(forKey: playerStateKey),
           let state = try? JSONDecoder().decode(PlayerWorldState.self, from: data) {
            self.playerState = state
        } else {
            self.playerState = PlayerWorldState.new()
        }
        
        if let data = UserDefaults.standard.data(forKey: homeNestKey),
           let nest = try? JSONDecoder().decode(Nest.self, from: data) {
            self.homeNest = nest
            self.playerState.homeNestId = nest.id
        }
        
        generateNearbyContent()
        startWorldSimulation()
    }
    
    // MARK: - Movement
    
    func move(direction: WorldPosition, speed: Double = 1.0) {
        playerState.lastPosition = playerState.position
        
        playerState.position.x += direction.x * speed
        playerState.position.y += direction.y * speed
        playerState.position.z += direction.z * speed
        
        // Clamp altitude
        playerState.position.z = max(0, min(500, playerState.position.z))
        
        // Consume energy for movement
        playerState.energy -= 0.1 * speed
        
        // Update biome based on position
        updateCurrentBiome()
        
        // Regenerate nearby content periodically
        generateNearbyContent()
        
        save()
    }
    
    func flyTo(position: WorldPosition) {
        let distance = playerState.position.distance(to: position)
        let energyCost = distance * 0.01
        
        guard playerState.energy >= energyCost else { return }
        
        playerState.energy -= energyCost
        playerState.lastPosition = playerState.position
        playerState.position = position
        
        updateCurrentBiome()
        generateNearbyContent()
        save()
    }
    
    private func updateCurrentBiome() {
        // Simple biome calculation based on position
        let x = Int(playerState.position.x) / 1000
        let y = Int(playerState.position.y) / 1000
        let hash = abs(x * 31 + y * 17) % Biome.allCases.count
        playerState.currentBiome = Biome.allCases[hash]
        playerState.discoveredBiomes.insert(playerState.currentBiome.rawValue)
    }
    
    // MARK: - Resource Gathering
    
    func harvestResource(_ resource: Resource) -> (success: Bool, amount: Int) {
        guard resource.canHarvest else {
            return (false, 0)
        }
        
        guard playerState.canCarryMore else {
            return (false, 0)
        }
        
        let biomeMultiplier = playerState.currentBiome.resourceMultiplier
        let baseAmount = resource.type.baseYield
        let amount = Int(Double(baseAmount) * biomeMultiplier)
        
        let actualAmount = playerState.addResource(resource.type, amount: amount)
        
        // Mark resource as harvested
        if let index = nearbyResources.firstIndex(where: { $0.id == resource.id }) {
            nearbyResources[index].lastHarvested = Date()
        }
        
        // Consume energy
        playerState.energy -= 2
        
        save()
        return (true, actualAmount)
    }
    
    // MARK: - Nest Building
    
    func createNest() -> Bool {
        guard homeNest == nil else { return false }
        
        let playerId = MultiplayerManager.shared.localPlayerId
        let playerName = MultiplayerManager.shared.localPlayerName
        
        let nest = Nest(
            id: UUID().uuidString,
            ownerId: playerId,
            ownerName: playerName,
            position: playerState.position,
            level: 1,
            health: 100,
            maxHealth: 100,
            components: [
                NestComponent(
                    id: UUID().uuidString,
                    type: .foundation,
                    health: NestComponentType.foundation.health,
                    position: NestPosition(gridX: 0, gridY: 0, layer: 0)
                )
            ],
            storage: [:],
            defenses: [],
            lastRaided: nil,
            createdAt: Date()
        )
        
        homeNest = nest
        playerState.homeNestId = nest.id
        save()
        
        VoiceChatManager.shared.speak("Nest established! Time to build it up!", priority: .normal)
        
        return true
    }
    
    func addNestComponent(_ type: NestComponentType) -> Bool {
        guard var nest = homeNest else { return false }
        
        // Check resources
        for (resource, amount) in type.requiredResources {
            guard playerState.inventory[resource, default: 0] >= amount else {
                return false
            }
        }
        
        // Consume resources
        for (resource, amount) in type.requiredResources {
            _ = playerState.removeResource(resource, amount: amount)
        }
        
        // Add component
        let component = NestComponent(
            id: UUID().uuidString,
            type: type,
            health: type.health,
            position: NestPosition(gridX: nest.components.count % 3, gridY: nest.components.count / 3, layer: type == .roof ? 2 : 1)
        )
        
        nest.components.append(component)
        homeNest = nest
        save()
        
        return true
    }
    
    func upgradeNest() -> Bool {
        guard var nest = homeNest else { return false }
        
        // Cost increases with level
        let twigCost = nest.level * 20
        let leafCost = nest.level * 15
        
        guard playerState.inventory[.twigs, default: 0] >= twigCost,
              playerState.inventory[.leaves, default: 0] >= leafCost else {
            return false
        }
        
        _ = playerState.removeResource(.twigs, amount: twigCost)
        _ = playerState.removeResource(.leaves, amount: leafCost)
        
        guard nest.upgrade() else { return false }
        
        homeNest = nest
        save()
        
        return true
    }
    
    func depositToNest(_ type: ResourceType, amount: Int) -> Bool {
        guard var nest = homeNest else { return false }
        guard playerState.inventory[type, default: 0] >= amount else { return false }
        guard nest.totalStoredItems + amount <= nest.storageCapacity else { return false }
        
        _ = playerState.removeResource(type, amount: amount)
        nest.storage[type, default: 0] += amount
        homeNest = nest
        save()
        
        return true
    }
    
    func withdrawFromNest(_ type: ResourceType, amount: Int) -> Bool {
        guard var nest = homeNest else { return false }
        guard nest.storage[type, default: 0] >= amount else { return false }
        guard playerState.canCarryMore else { return false }
        
        nest.storage[type, default: 0] -= amount
        if nest.storage[type] == 0 {
            nest.storage.removeValue(forKey: type)
        }
        _ = playerState.addResource(type, amount: amount)
        homeNest = nest
        save()
        
        return true
    }
    
    // MARK: - Raiding
    
    func raidNest(_ nest: Nest) -> RaidResult {
        guard nest.ownerId != MultiplayerManager.shared.localPlayerId else {
            return RaidResult(success: false, message: "Can't raid your own nest!", loot: [:])
        }
        
        guard !nest.isProtected else {
            return RaidResult(success: false, message: "This nest has raid protection!", loot: [:])
        }
        
        // Calculate raid success based on defenses
        var damage: Double = 0
        for defense in nest.defenses where defense.isActive {
            damage += defense.type.damage
        }
        
        playerState.health -= damage
        
        if playerState.health <= 0 {
            // Player knocked out
            playerState.health = 100
            playerState.position = playerState.lastPosition ?? WorldPosition.zero
            return RaidResult(success: false, message: "You got wrecked by the defenses!", loot: [:])
        }
        
        // Steal some resources (30-50% of storage)
        var loot: [ResourceType: Int] = [:]
        let stealPercent = Double.random(in: 0.3...0.5)
        
        for (resource, amount) in nest.storage {
            let stolen = Int(Double(amount) * stealPercent)
            if stolen > 0 {
                let actual = playerState.addResource(resource, amount: stolen)
                if actual > 0 {
                    loot[resource] = actual
                }
            }
        }
        
        save()
        
        return RaidResult(
            success: true,
            message: "Raid successful!",
            loot: loot
        )
    }
    
    // MARK: - Survival
    
    func eat(_ resource: ResourceType) -> Bool {
        let edibleResources: [ResourceType: Double] = [
            .berries: 20,
            .bugs: 15
        ]
        
        guard let hungerRestore = edibleResources[resource] else { return false }
        guard playerState.removeResource(resource, amount: 1) else { return false }
        
        playerState.hunger = min(100, playerState.hunger + hungerRestore)
        save()
        
        return true
    }
    
    func rest() {
        // Restore energy over time when at nest
        if let nest = homeNest,
           playerState.position.distance(to: nest.position) < 10 {
            playerState.energy = min(100, playerState.energy + 10)
            save()
        }
    }
    
    // MARK: - World Simulation
    
    private func startWorldSimulation() {
        // Decay hunger and energy over time
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.playerState.hunger -= self.hungerDecayRate
            
            // Energy decays faster if hungry
            let energyMultiplier = self.playerState.hunger < 30 ? 2.0 : 1.0
            self.playerState.energy -= self.energyDecayRate * energyMultiplier
            
            // Clamp values
            self.playerState.hunger = max(0, self.playerState.hunger)
            self.playerState.energy = max(0, self.playerState.energy)
            
            // Take damage if starving
            if self.playerState.hunger <= 0 {
                self.playerState.health -= 0.5
            }
            
            // Regenerate health if well-fed and rested
            if self.playerState.hunger > 80 && self.playerState.energy > 80 {
                self.playerState.health = min(100, self.playerState.health + 0.1)
            }
        }
        
        // Weather changes
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.currentWeather = Weather.allCases.randomElement() ?? .clear
        }
        
        // Time of day
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            self?.timeOfDay = TimeOfDay.allCases.randomElement() ?? .day
        }
    }
    
    private func generateNearbyContent() {
        // Generate resources
        nearbyResources = (0..<Int.random(in: 5...15)).map { _ in
            Resource(
                id: UUID().uuidString,
                type: ResourceType.allCases.randomElement()!,
                amount: Int.random(in: 1...10),
                position: WorldPosition(
                    x: playerState.position.x + Double.random(in: -resourceScanRadius...resourceScanRadius),
                    y: playerState.position.y + Double.random(in: -resourceScanRadius...resourceScanRadius),
                    z: playerState.position.z + Double.random(in: -20...20)
                ),
                lastHarvested: nil
            )
        }
        
        // Generate fake nearby nests
        nearbyNests = (0..<Int.random(in: 2...5)).map { _ in
            let names = ["xX_NestMaster_Xx", "PigeonPalace", "EagleEyrie", "CrowsNest420", "FeatheredFortress"]
            return Nest(
                id: UUID().uuidString,
                ownerId: UUID().uuidString,
                ownerName: names.randomElement()!,
                position: WorldPosition(
                    x: playerState.position.x + Double.random(in: -nestScanRadius...nestScanRadius),
                    y: playerState.position.y + Double.random(in: -nestScanRadius...nestScanRadius),
                    z: Double.random(in: 30...100)
                ),
                level: Int.random(in: 1...10),
                health: Double.random(in: 50...200),
                maxHealth: 200,
                components: [],
                storage: [
                    .twigs: Int.random(in: 0...100),
                    .leaves: Int.random(in: 0...80),
                    .shinyObjects: Int.random(in: 0...10)
                ],
                defenses: [],
                lastRaided: nil,
                createdAt: Date()
            )
        }
        
        // Generate fake nearby players
        nearbyPlayers = (0..<Int.random(in: 0...8)).map { _ in
            WorldPlayer(
                id: UUID().uuidString,
                name: ["BirdBro", "WingWizard", "PeckMaster", "FeatherFiend"].randomElement()!,
                birdType: BirdType.allCases.randomElement()!,
                position: WorldPosition(
                    x: playerState.position.x + Double.random(in: -150...150),
                    y: playerState.position.y + Double.random(in: -150...150),
                    z: Double.random(in: 20...150)
                ),
                isHostile: Bool.random()
            )
        }
    }
    
    // MARK: - Persistence
    
    private func save() {
        if let data = try? JSONEncoder().encode(playerState) {
            UserDefaults.standard.set(data, forKey: playerStateKey)
        }
        if let nest = homeNest, let data = try? JSONEncoder().encode(nest) {
            UserDefaults.standard.set(data, forKey: homeNestKey)
        }
    }
    
    func reset() {
        playerState = PlayerWorldState.new()
        homeNest = nil
        UserDefaults.standard.removeObject(forKey: playerStateKey)
        UserDefaults.standard.removeObject(forKey: homeNestKey)
    }
}

// MARK: - Supporting Types

struct WorldPlayer: Identifiable {
    let id: String
    let name: String
    let birdType: BirdType
    let position: WorldPosition
    let isHostile: Bool
}

struct RaidResult {
    let success: Bool
    let message: String
    let loot: [ResourceType: Int]
}

enum Weather: String, CaseIterable {
    case clear
    case cloudy
    case rainy
    case stormy
    case windy
    case foggy
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var emoji: String {
        switch self {
        case .clear: return "☀️"
        case .cloudy: return "☁️"
        case .rainy: return "🌧️"
        case .stormy: return "⛈️"
        case .windy: return "💨"
        case .foggy: return "🌫️"
        }
    }
}

enum TimeOfDay: String, CaseIterable {
    case dawn
    case day
    case dusk
    case night
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var emoji: String {
        switch self {
        case .dawn: return "🌅"
        case .day: return "☀️"
        case .dusk: return "🌇"
        case .night: return "🌙"
        }
    }
}

struct WorldEvent: Identifiable {
    let id: String
    let type: WorldEventType
    let message: String
    let timestamp: Date
}

enum WorldEventType {
    case playerNearby
    case resourceSpawn
    case raidAlert
    case weatherChange
    case worldBoss
}

// MARK: - Special Hidden Locations

struct SpecialLocation: Identifiable {
    let id: String
    let name: String
    let position: WorldPosition
    let radius: Double
    let isHidden: Bool
    let requiredBird: BirdType?
    let achievementId: String?
    let badgeId: String?
    let description: String
}

extension OpenWorldManager {
    
    // MARK: - Special Locations
    
    static let specialLocations: [SpecialLocation] = [
        // Bowling Alley - Hidden achievement for Crow only
        SpecialLocation(
            id: "bowling_alley",
            name: "Bowling Alley",
            position: WorldPosition(x: 4200, y: 1337, z: 50),
            radius: 50,
            isHidden: true,
            requiredBird: .crow,
            achievementId: nil,
            badgeId: "badge_bowling_crow",
            description: "A mysterious bowling alley. Only crows understand why this place is special."
        ),
        
        // CHairBNB - Easter egg reference
        SpecialLocation(
            id: "chairbnb",
            name: "CHairBNB",
            position: WorldPosition(x: -2500, y: 3141, z: 75),
            radius: 40,
            isHidden: true,
            requiredBird: nil,
            achievementId: nil,
            badgeId: "badge_chairbnb",
            description: "A cozy rental spot with a suspiciously modified sign. 'CH' has been spray painted in front of 'airBNB'."
        ),
        
        // Regular discoverable locations
        SpecialLocation(
            id: "ancient_tree",
            name: "The Ancient Tree",
            position: WorldPosition(x: 0, y: 0, z: 200),
            radius: 100,
            isHidden: false,
            requiredBird: nil,
            achievementId: nil,
            badgeId: nil,
            description: "A massive ancient tree at the center of the world. Legend says it's been here since the beginning."
        ),
        
        SpecialLocation(
            id: "sky_temple",
            name: "Sky Temple",
            position: WorldPosition(x: 5000, y: 5000, z: 450),
            radius: 80,
            isHidden: false,
            requiredBird: nil,
            achievementId: nil,
            badgeId: nil,
            description: "A temple floating high in the sky. Only the bravest birds dare to visit."
        )
    ]
    
    /// Check if player has entered any special location
    func checkSpecialLocations(currentBird: BirdType) {
        for location in Self.specialLocations {
            let distance = playerState.position.distance(to: location.position)
            
            if distance <= location.radius {
                // Check if bird requirement is met
                if let requiredBird = location.requiredBird {
                    if currentBird == requiredBird {
                        triggerLocationDiscovery(location, withCorrectBird: true)
                    }
                    // Don't trigger if wrong bird for hidden locations
                } else {
                    triggerLocationDiscovery(location, withCorrectBird: true)
                }
            }
        }
    }
    
    private func triggerLocationDiscovery(_ location: SpecialLocation, withCorrectBird: Bool) {
        let discoveryKey = "birdgame3_discovered_\(location.id)"
        
        // Check if already discovered
        guard !UserDefaults.standard.bool(forKey: discoveryKey) else { return }
        
        // Mark as discovered
        UserDefaults.standard.set(true, forKey: discoveryKey)
        
        // Unlock badge if applicable
        if let badgeId = location.badgeId, withCorrectBird {
            if location.id == "bowling_alley" {
                AchievementManager.shared.trackBowlingAlleyVisit(asCrow: true)
                ProfileIconManager.shared.unlockIcon("icon_bowling")
            } else if location.id == "chairbnb" {
                AchievementManager.shared.trackChairBNBVisit()
                ProfileIconManager.shared.unlockIcon("icon_chairbnb")
            } else {
                AchievementManager.shared.unlockBadge(badgeId)
            }
        }
        
        // Add world event
        let event = WorldEvent(
            id: UUID().uuidString,
            type: .resourceSpawn, // Reuse type for discovery
            message: "Discovered: \(location.name)!",
            timestamp: Date()
        )
        worldEvents.append(event)
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Get directions to a special location
    func getDirectionTo(locationId: String) -> (distance: Double, direction: String)? {
        guard let location = Self.specialLocations.first(where: { $0.id == locationId && !$0.isHidden }) else {
            return nil
        }
        
        let distance = playerState.position.distance(to: location.position)
        
        let dx = location.position.x - playerState.position.x
        let dy = location.position.y - playerState.position.y
        
        let direction: String
        if abs(dx) > abs(dy) {
            direction = dx > 0 ? "East" : "West"
        } else {
            direction = dy > 0 ? "North" : "South"
        }
        
        return (distance, direction)
    }
}
