import XCTest
@testable import BirdGame3

final class BirdSkillTests: XCTestCase {
    
    func testBirdSkillInitialization() {
        let skill = BirdSkill(
            name: "Test Skill",
            iconName: "star.fill",
            cooldownDuration: 5.0,
            description: "A test skill"
        )
        
        XCTAssertEqual(skill.name, "Test Skill")
        XCTAssertEqual(skill.iconName, "star.fill")
        XCTAssertEqual(skill.cooldownDuration, 5.0)
        XCTAssertEqual(skill.description, "A test skill")
    }
    
    func testStaticSkills() {
        XCTAssertEqual(BirdSkill.fireball.name, "Fireball")
        XCTAssertEqual(BirdSkill.fireball.cooldownDuration, 5.0)
        
        XCTAssertEqual(BirdSkill.heal.name, "Heal")
        XCTAssertEqual(BirdSkill.heal.cooldownDuration, 12.0)
        
        XCTAssertEqual(BirdSkill.shield.name, "Shield")
        XCTAssertEqual(BirdSkill.shield.cooldownDuration, 15.0)
    }
}

final class BirdTests: XCTestCase {
    
    func testBirdInitialization() {
        let bird = Bird(
            name: "Test Bird",
            maxHealth: 100,
            skills: [.fireball, .heal]
        )
        
        XCTAssertEqual(bird.name, "Test Bird")
        XCTAssertEqual(bird.maxHealth, 100)
        XCTAssertEqual(bird.currentHealth, 100)
        XCTAssertEqual(bird.skills.count, 2)
    }
    
    func testHealthPercentage() {
        var bird = Bird(
            name: "Test Bird",
            maxHealth: 100,
            currentHealth: 75,
            skills: []
        )
        
        XCTAssertEqual(bird.healthPercentage, 0.75)
        
        bird.currentHealth = 0
        XCTAssertEqual(bird.healthPercentage, 0)
    }
    
    func testIsAlive() {
        var bird = Bird(
            name: "Test Bird",
            maxHealth: 100,
            currentHealth: 50,
            skills: []
        )
        
        XCTAssertTrue(bird.isAlive)
        
        bird.currentHealth = 0
        XCTAssertFalse(bird.isAlive)
    }
    
    func testStaticBirds() {
        let phoenix = Bird.phoenix
        XCTAssertEqual(phoenix.name, "Phoenix")
        XCTAssertEqual(phoenix.maxHealth, 100)
        XCTAssertEqual(phoenix.skills.count, 4)
        
        let hawk = Bird.hawk
        XCTAssertEqual(hawk.name, "Hawk")
        XCTAssertEqual(hawk.maxHealth, 80)
    }
}

final class ControlInputTests: XCTestCase {
    
    func testDefaultInitialization() {
        let input = ControlInput()
        
        XCTAssertEqual(input.movementDirection, .zero)
        XCTAssertFalse(input.isAttacking)
        XCTAssertFalse(input.isSprinting)
        XCTAssertFalse(input.isTargetLocked)
        XCTAssertNil(input.activeSkillIndex)
    }
    
    func testNormalizedMovement() {
        // Test unit vector
        var input = ControlInput(movementDirection: CGVector(dx: 1, dy: 0))
        XCTAssertEqual(input.normalizedMovement.dx, 1, accuracy: 0.001)
        XCTAssertEqual(input.normalizedMovement.dy, 0, accuracy: 0.001)
        
        // Test diagonal (should be normalized)
        input = ControlInput(movementDirection: CGVector(dx: 1, dy: 1))
        let normalized = input.normalizedMovement
        let magnitude = sqrt(normalized.dx * normalized.dx + normalized.dy * normalized.dy)
        XCTAssertEqual(magnitude, 1.0, accuracy: 0.001)
        
        // Test oversized vector (should be clamped)
        input = ControlInput(movementDirection: CGVector(dx: 2, dy: 0))
        XCTAssertEqual(input.normalizedMovement.dx, 1, accuracy: 0.001)
    }
    
    func testSpeedMultiplier() {
        var input = ControlInput()
        XCTAssertEqual(input.speedMultiplier, 1.0)
        
        input = ControlInput(isSprinting: true)
        XCTAssertEqual(input.speedMultiplier, 1.5)
    }
}
