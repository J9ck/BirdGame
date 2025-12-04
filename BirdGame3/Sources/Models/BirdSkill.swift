import Foundation

/// Represents a bird's special skill/ability in the game
struct BirdSkill: Identifiable, Equatable {
    let id: UUID
    let name: String
    let iconName: String
    let cooldownDuration: TimeInterval
    let description: String
    
    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        cooldownDuration: TimeInterval,
        description: String = ""
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.cooldownDuration = cooldownDuration
        self.description = description
    }
}

// MARK: - Sample Skills for different bird types
extension BirdSkill {
    static let fireball = BirdSkill(
        name: "Fireball",
        iconName: "flame.fill",
        cooldownDuration: 5.0,
        description: "Launch a fiery projectile"
    )
    
    static let windGust = BirdSkill(
        name: "Wind Gust",
        iconName: "wind",
        cooldownDuration: 8.0,
        description: "Create a powerful gust of wind"
    )
    
    static let heal = BirdSkill(
        name: "Heal",
        iconName: "cross.fill",
        cooldownDuration: 12.0,
        description: "Restore health over time"
    )
    
    static let shield = BirdSkill(
        name: "Shield",
        iconName: "shield.fill",
        cooldownDuration: 15.0,
        description: "Create a protective barrier"
    )
    
    static let diveBomb = BirdSkill(
        name: "Dive Bomb",
        iconName: "arrow.down.circle.fill",
        cooldownDuration: 10.0,
        description: "Dive attack from above"
    )
    
    static let sonicScream = BirdSkill(
        name: "Sonic Scream",
        iconName: "waveform",
        cooldownDuration: 7.0,
        description: "Stun nearby enemies"
    )
}
