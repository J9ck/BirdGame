//
//  CraftingManager.swift
//  BirdGame3
//
//  Crafting system for nest building and item creation
//

import Foundation
import SwiftUI

// MARK: - Crafting Recipe

struct CraftingRecipe: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: CraftingCategory
    let inputs: [ResourceType: Int]
    let outputType: CraftingOutput
    let outputAmount: Int
    let craftTime: TimeInterval
    let requiredLevel: Int
    let unlockBiome: Biome?
    
    var canCraft: Bool {
        let manager = OpenWorldManager.shared
        let playerLevel = PrestigeManager.shared.currentLevel
        
        // Check level requirement
        guard playerLevel >= requiredLevel else { return false }
        
        // Check biome unlock if required
        if let biome = unlockBiome {
            guard manager.playerState.discoveredBiomes.contains(biome.rawValue) else { return false }
        }
        
        // Check resources
        for (resource, amount) in inputs {
            guard manager.playerState.inventory[resource, default: 0] >= amount else { return false }
        }
        
        return true
    }
}

// MARK: - Crafting Category

enum CraftingCategory: String, Codable, CaseIterable {
    case nestComponents = "Nest Building"
    case tools = "Tools"
    case consumables = "Consumables"
    case decorations = "Decorations"
    case traps = "Traps & Defenses"
    
    var emoji: String {
        switch self {
        case .nestComponents: return "🪺"
        case .tools: return "🔧"
        case .consumables: return "🧪"
        case .decorations: return "🎀"
        case .traps: return "🪤"
        }
    }
}

// MARK: - Crafting Output

enum CraftingOutput: Codable {
    case nestComponent(NestComponentType)
    case consumable(ConsumableType)
    case tool(ToolType)
    case decoration(String)
    case trap(DefenseType)
}

// MARK: - Consumable Types

enum ConsumableType: String, Codable, CaseIterable {
    case healthPotion = "Health Nectar"
    case energyPotion = "Energy Seeds"
    case speedBoost = "Swift Feather"
    case attackBoost = "Rage Berry"
    case defenseBoost = "Iron Moss"
    case xpBoost = "Wisdom Fruit"
    
    var effect: String {
        switch self {
        case .healthPotion: return "Restores 50 HP"
        case .energyPotion: return "Restores 75 Energy"
        case .speedBoost: return "+50% Speed for 30s"
        case .attackBoost: return "+25% Attack for 60s"
        case .defenseBoost: return "+25% Defense for 60s"
        case .xpBoost: return "+100% XP for 5 min"
        }
    }
    
    var emoji: String {
        switch self {
        case .healthPotion: return "❤️‍🩹"
        case .energyPotion: return "⚡"
        case .speedBoost: return "💨"
        case .attackBoost: return "💪"
        case .defenseBoost: return "🛡️"
        case .xpBoost: return "📚"
        }
    }
}

// MARK: - Tool Types

enum ToolType: String, Codable, CaseIterable {
    case harvestingClaw = "Harvesting Claw"
    case carryingPouch = "Carrying Pouch"
    case preyTracker = "Prey Tracker"
    case resourceDetector = "Resource Detector"
    case weatherVane = "Weather Vane"
    
    var bonus: String {
        switch self {
        case .harvestingClaw: return "+25% resource gather rate"
        case .carryingPouch: return "+20 inventory slots"
        case .preyTracker: return "Reveals nearby prey on map"
        case .resourceDetector: return "Reveals nearby resources on map"
        case .weatherVane: return "Predicts weather changes"
        }
    }
    
    var emoji: String {
        switch self {
        case .harvestingClaw: return "🦅"
        case .carryingPouch: return "👜"
        case .preyTracker: return "🎯"
        case .resourceDetector: return "🔍"
        case .weatherVane: return "🌪️"
        }
    }
}

// MARK: - Crafting Manager

class CraftingManager: ObservableObject {
    static let shared = CraftingManager()
    
    // MARK: - Published Properties
    
    @Published var recipes: [CraftingRecipe] = []
    @Published var craftingQueue: [CraftingJob] = []
    @Published var unlockedRecipes: Set<String> = []
    @Published var craftedItems: [String: Int] = [:]
    
    // MARK: - Constants
    
    private let maxQueueSize = 3
    private let saveKey = "birdgame3_crafting"
    
    // MARK: - Initialization
    
    private init() {
        loadRecipes()
        loadProgress()
        startCraftingTimer()
    }
    
    // MARK: - Recipes
    
    private func loadRecipes() {
        recipes = [
            // Nest Components
            CraftingRecipe(
                id: "craft_foundation",
                name: "Nest Foundation",
                description: "A sturdy base for your nest",
                category: .nestComponents,
                inputs: [.twigs: 20, .mud: 10],
                outputType: .nestComponent(.foundation),
                outputAmount: 1,
                craftTime: 30,
                requiredLevel: 1,
                unlockBiome: nil
            ),
            CraftingRecipe(
                id: "craft_wall",
                name: "Nest Wall",
                description: "Protective wall segment",
                category: .nestComponents,
                inputs: [.twigs: 10, .leaves: 5],
                outputType: .nestComponent(.wall),
                outputAmount: 1,
                craftTime: 20,
                requiredLevel: 2,
                unlockBiome: nil
            ),
            CraftingRecipe(
                id: "craft_roof",
                name: "Nest Roof",
                description: "Weather protection for your nest",
                category: .nestComponents,
                inputs: [.leaves: 15, .twigs: 5, .moss: 3],
                outputType: .nestComponent(.roof),
                outputAmount: 1,
                craftTime: 45,
                requiredLevel: 5,
                unlockBiome: nil
            ),
            CraftingRecipe(
                id: "craft_storage",
                name: "Storage Box",
                description: "Store extra resources (+25 capacity)",
                category: .nestComponents,
                inputs: [.twigs: 15, .leaves: 10],
                outputType: .nestComponent(.storageBox),
                outputAmount: 1,
                craftTime: 60,
                requiredLevel: 3,
                unlockBiome: nil
            ),
            
            // Consumables
            CraftingRecipe(
                id: "craft_health_nectar",
                name: "Health Nectar",
                description: "Restores 50 HP instantly",
                category: .consumables,
                inputs: [.berries: 5, .bugs: 2],
                outputType: .consumable(.healthPotion),
                outputAmount: 1,
                craftTime: 10,
                requiredLevel: 1,
                unlockBiome: nil
            ),
            CraftingRecipe(
                id: "craft_energy_seeds",
                name: "Energy Seeds",
                description: "Restores 75 Energy instantly",
                category: .consumables,
                inputs: [.berries: 3, .leaves: 2],
                outputType: .consumable(.energyPotion),
                outputAmount: 1,
                craftTime: 10,
                requiredLevel: 1,
                unlockBiome: nil
            ),
            CraftingRecipe(
                id: "craft_swift_feather",
                name: "Swift Feather",
                description: "+50% Speed for 30 seconds",
                category: .consumables,
                inputs: [.feathers: 3, .bugs: 2],
                outputType: .consumable(.speedBoost),
                outputAmount: 1,
                craftTime: 20,
                requiredLevel: 5,
                unlockBiome: nil
            ),
            CraftingRecipe(
                id: "craft_rage_berry",
                name: "Rage Berry",
                description: "+25% Attack for 60 seconds",
                category: .consumables,
                inputs: [.berries: 8, .bugs: 5],
                outputType: .consumable(.attackBoost),
                outputAmount: 1,
                craftTime: 30,
                requiredLevel: 10,
                unlockBiome: .jungle
            ),
            CraftingRecipe(
                id: "craft_iron_moss",
                name: "Iron Moss",
                description: "+25% Defense for 60 seconds",
                category: .consumables,
                inputs: [.moss: 10, .mud: 5],
                outputType: .consumable(.defenseBoost),
                outputAmount: 1,
                craftTime: 30,
                requiredLevel: 10,
                unlockBiome: .swamp
            ),
            
            // Tools
            CraftingRecipe(
                id: "craft_harvesting_claw",
                name: "Harvesting Claw",
                description: "+25% resource gather rate",
                category: .tools,
                inputs: [.twigs: 10, .shinyObjects: 2],
                outputType: .tool(.harvestingClaw),
                outputAmount: 1,
                craftTime: 120,
                requiredLevel: 8,
                unlockBiome: nil
            ),
            CraftingRecipe(
                id: "craft_carrying_pouch",
                name: "Carrying Pouch",
                description: "+20 inventory slots",
                category: .tools,
                inputs: [.leaves: 20, .feathers: 10],
                outputType: .tool(.carryingPouch),
                outputAmount: 1,
                craftTime: 180,
                requiredLevel: 12,
                unlockBiome: nil
            ),
            CraftingRecipe(
                id: "craft_prey_tracker",
                name: "Prey Tracker",
                description: "Reveals nearby prey on minimap",
                category: .tools,
                inputs: [.feathers: 5, .shinyObjects: 3, .bugs: 10],
                outputType: .tool(.preyTracker),
                outputAmount: 1,
                craftTime: 240,
                requiredLevel: 15,
                unlockBiome: nil
            ),
            
            // Traps
            CraftingRecipe(
                id: "craft_spike_trap",
                name: "Spike Trap",
                description: "Damages raiders attacking your nest",
                category: .traps,
                inputs: [.twigs: 15, .shinyObjects: 1],
                outputType: .trap(.spikeTrap),
                outputAmount: 1,
                craftTime: 60,
                requiredLevel: 6,
                unlockBiome: nil
            ),
            CraftingRecipe(
                id: "craft_alarm_feathers",
                name: "Alarm Feathers",
                description: "Alerts you when raiders approach",
                category: .traps,
                inputs: [.feathers: 8, .shinyObjects: 2],
                outputType: .trap(.alarmFeathers),
                outputAmount: 1,
                craftTime: 45,
                requiredLevel: 4,
                unlockBiome: nil
            ),
            
            // Decorations
            CraftingRecipe(
                id: "craft_shiny_mobile",
                name: "Shiny Mobile",
                description: "A beautiful decoration for your nest",
                category: .decorations,
                inputs: [.shinyObjects: 5, .feathers: 3],
                outputType: .decoration("shiny_mobile"),
                outputAmount: 1,
                craftTime: 30,
                requiredLevel: 5,
                unlockBiome: nil
            ),
            CraftingRecipe(
                id: "craft_berry_garland",
                name: "Berry Garland",
                description: "Festive nest decoration",
                category: .decorations,
                inputs: [.berries: 15, .leaves: 10],
                outputType: .decoration("berry_garland"),
                outputAmount: 1,
                craftTime: 25,
                requiredLevel: 3,
                unlockBiome: nil
            )
        ]
    }
    
    // MARK: - Crafting Actions
    
    func startCrafting(recipeId: String) -> Bool {
        guard let recipe = recipes.first(where: { $0.id == recipeId }) else { return false }
        guard recipe.canCraft else { return false }
        guard craftingQueue.count < maxQueueSize else { return false }
        
        // Consume resources
        for (resource, amount) in recipe.inputs {
            _ = OpenWorldManager.shared.playerState.removeResource(resource, amount: amount)
        }
        
        // Add to queue
        let job = CraftingJob(
            id: UUID().uuidString,
            recipeId: recipeId,
            recipeName: recipe.name,
            startTime: Date(),
            completionTime: Date().addingTimeInterval(recipe.craftTime)
        )
        craftingQueue.append(job)
        
        save()
        return true
    }
    
    func cancelCrafting(jobId: String) {
        guard let index = craftingQueue.firstIndex(where: { $0.id == jobId }),
              let recipe = recipes.first(where: { $0.id == craftingQueue[index].recipeId }) else { return }
        
        // Refund 50% of resources
        for (resource, amount) in recipe.inputs {
            _ = OpenWorldManager.shared.playerState.addResource(resource, amount: amount / 2)
        }
        
        craftingQueue.remove(at: index)
        save()
    }
    
    func collectCompletedItem(jobId: String) -> Bool {
        guard let index = craftingQueue.firstIndex(where: { $0.id == jobId }),
              craftingQueue[index].isComplete,
              let recipe = recipes.first(where: { $0.id == craftingQueue[index].recipeId }) else { return false }
        
        // Apply output
        switch recipe.outputType {
        case .nestComponent(let type):
            _ = OpenWorldManager.shared.addNestComponent(type)
        case .consumable(let type):
            craftedItems[type.rawValue, default: 0] += recipe.outputAmount
        case .tool(let type):
            craftedItems[type.rawValue, default: 0] += recipe.outputAmount
        case .decoration(let id):
            craftedItems[id, default: 0] += recipe.outputAmount
        case .trap(let type):
            craftedItems[type.rawValue, default: 0] += recipe.outputAmount
        }
        
        craftingQueue.remove(at: index)
        save()
        return true
    }
    
    // MARK: - Recipe Access
    
    func recipes(for category: CraftingCategory) -> [CraftingRecipe] {
        recipes.filter { $0.category == category }
    }
    
    func availableRecipes() -> [CraftingRecipe] {
        recipes.filter { $0.canCraft }
    }
    
    // MARK: - Item Usage
    
    func useConsumable(_ type: ConsumableType) -> Bool {
        guard craftedItems[type.rawValue, default: 0] > 0 else { return false }
        
        craftedItems[type.rawValue, default: 0] -= 1
        
        // Apply effect
        let manager = OpenWorldManager.shared
        switch type {
        case .healthPotion:
            manager.playerState.health = min(100, manager.playerState.health + 50)
        case .energyPotion:
            manager.playerState.energy = min(100, manager.playerState.energy + 75)
        case .speedBoost:
            // Apply temporary buff (handled by combat system)
            break
        case .attackBoost:
            break
        case .defenseBoost:
            break
        case .xpBoost:
            PrestigeManager.shared.activateXPBoost(hours: 1)
        }
        
        save()
        return true
    }
    
    // MARK: - Timer
    
    private func startCraftingTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkCompletedCrafting()
        }
    }
    
    private func checkCompletedCrafting() {
        let now = Date()
        for job in craftingQueue where !job.isComplete && job.completionTime <= now {
            // Notify player
            NotificationCenter.default.post(
                name: Notification.Name("BirdGame3.CraftingComplete"),
                object: nil,
                userInfo: ["jobId": job.id, "recipeName": job.recipeName]
            )
        }
    }
    
    // MARK: - Persistence
    
    private func save() {
        let data = CraftingSaveData(
            unlockedRecipes: Array(unlockedRecipes),
            craftedItems: craftedItems,
            craftingQueue: craftingQueue
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(CraftingSaveData.self, from: data) {
            unlockedRecipes = Set(decoded.unlockedRecipes)
            craftedItems = decoded.craftedItems
            craftingQueue = decoded.craftingQueue.filter { !$0.isComplete }
        }
    }
}

// MARK: - Crafting Job

struct CraftingJob: Identifiable, Codable {
    let id: String
    let recipeId: String
    let recipeName: String
    let startTime: Date
    let completionTime: Date
    
    var isComplete: Bool { Date() >= completionTime }
    
    var progress: Double {
        let total = completionTime.timeIntervalSince(startTime)
        let elapsed = Date().timeIntervalSince(startTime)
        return min(1.0, elapsed / total)
    }
    
    var timeRemaining: TimeInterval {
        max(0, completionTime.timeIntervalSince(Date()))
    }
    
    var timeRemainingFormatted: String {
        let remaining = Int(timeRemaining)
        if remaining >= 60 {
            return "\(remaining / 60)m \(remaining % 60)s"
        }
        return "\(remaining)s"
    }
}

// MARK: - Save Data

private struct CraftingSaveData: Codable {
    let unlockedRecipes: [String]
    let craftedItems: [String: Int]
    let craftingQueue: [CraftingJob]
}
