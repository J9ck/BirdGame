import Foundation

/// Represents a bird character in the game
struct Bird: Identifiable, Equatable {
    let id: UUID
    let name: String
    let maxHealth: Double
    var currentHealth: Double
    let skills: [BirdSkill]
    
    init(
        id: UUID = UUID(),
        name: String,
        maxHealth: Double,
        currentHealth: Double? = nil,
        skills: [BirdSkill]
    ) {
        self.id = id
        self.name = name
        self.maxHealth = maxHealth
        self.currentHealth = currentHealth ?? maxHealth
        self.skills = skills
    }
    
    var healthPercentage: Double {
        guard maxHealth > 0 else { return 0 }
        return currentHealth / maxHealth
    }
    
    var isAlive: Bool {
        currentHealth > 0
    }
}

// MARK: - Sample Birds
extension Bird {
    static let phoenix = Bird(
        name: "Phoenix",
        maxHealth: 100,
        skills: [.fireball, .heal, .shield, .windGust]
    )
    
    static let hawk = Bird(
        name: "Hawk",
        maxHealth: 80,
        skills: [.diveBomb, .windGust, .sonicScream, .shield]
    )
    
    static let owl = Bird(
        name: "Owl",
        maxHealth: 90,
        skills: [.sonicScream, .heal, .shield, .windGust]
    )
}
