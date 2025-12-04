import XCTest
@testable import BirdGame3

#if canImport(SwiftUI)
@MainActor
final class ControlManagerTests: XCTestCase {
    
    var controlManager: ControlManager!
    
    override func setUp() {
        super.setUp()
        controlManager = ControlManager()
        controlManager.configure(with: .phoenix)
    }
    
    override func tearDown() {
        controlManager.cleanup()
        controlManager = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(controlManager.currentInput.movementDirection, .zero)
        XCTAssertFalse(controlManager.currentInput.isAttacking)
        XCTAssertFalse(controlManager.currentInput.isSprinting)
        XCTAssertFalse(controlManager.currentInput.isTargetLocked)
        XCTAssertTrue(controlManager.canSprint)
    }
    
    func testUpdateMovement() {
        let direction = CGVector(dx: 0.5, dy: -0.3)
        controlManager.updateMovement(direction: direction)
        
        XCTAssertEqual(controlManager.currentInput.movementDirection.dx, 0.5, accuracy: 0.001)
        XCTAssertEqual(controlManager.currentInput.movementDirection.dy, -0.3, accuracy: 0.001)
    }
    
    func testStopMovement() {
        controlManager.updateMovement(direction: CGVector(dx: 1, dy: 1))
        controlManager.stopMovement()
        
        XCTAssertEqual(controlManager.currentInput.movementDirection, .zero)
    }
    
    func testTriggerAttack() {
        controlManager.triggerAttack()
        
        // Attack should be active momentarily
        XCTAssertTrue(controlManager.currentInput.isAttacking)
    }
    
    func testToggleTargetLock() {
        XCTAssertFalse(controlManager.currentInput.isTargetLocked)
        
        controlManager.toggleTargetLock()
        XCTAssertTrue(controlManager.currentInput.isTargetLocked)
        
        controlManager.toggleTargetLock()
        XCTAssertFalse(controlManager.currentInput.isTargetLocked)
    }
    
    func testSkillCooldownInitialization() {
        // Phoenix has 4 skills
        XCTAssertEqual(controlManager.skillCooldowns.count, 4)
        XCTAssertTrue(controlManager.skillCooldowns.allSatisfy { $0 == 0 })
    }
    
    func testTriggerSkillStartsCooldown() {
        // All skills should start with no cooldown
        XCTAssertFalse(controlManager.isSkillOnCooldown(at: 0))
        
        controlManager.triggerSkill(at: 0)
        
        // Skill should now be on cooldown
        XCTAssertTrue(controlManager.skillCooldowns[0] > 0)
        XCTAssertTrue(controlManager.isSkillOnCooldown(at: 0))
    }
    
    func testSkillCooldownProgress() {
        // No cooldown initially
        XCTAssertEqual(controlManager.skillCooldownProgress(at: 0), 0)
        
        // After triggering, should have progress
        controlManager.triggerSkill(at: 0)
        XCTAssertGreaterThan(controlManager.skillCooldownProgress(at: 0), 0)
    }
    
    func testInvalidSkillIndex() {
        // Should not crash with invalid index
        controlManager.triggerSkill(at: -1)
        controlManager.triggerSkill(at: 100)
        
        XCTAssertFalse(controlManager.isSkillOnCooldown(at: -1))
        XCTAssertTrue(controlManager.isSkillOnCooldown(at: 100)) // Returns true for invalid
    }
    
    func testTriggerSprint() {
        XCTAssertTrue(controlManager.canSprint)
        XCTAssertFalse(controlManager.currentInput.isSprinting)
        
        controlManager.triggerSprint()
        
        XCTAssertTrue(controlManager.currentInput.isSprinting)
        XCTAssertFalse(controlManager.canSprint)
    }
    
    func testSprintWhileOnCooldown() {
        controlManager.triggerSprint()
        
        // Try to sprint again while already sprinting
        let previousSprintState = controlManager.currentInput.isSprinting
        controlManager.triggerSprint()
        
        // State should not change
        XCTAssertEqual(controlManager.currentInput.isSprinting, previousSprintState)
    }
    
    func testConfigureWithDifferentBird() {
        // Reconfigure with a different bird
        controlManager.configure(with: .hawk)
        
        // Should have hawk's 4 skills
        XCTAssertEqual(controlManager.skillCooldowns.count, 4)
    }
}
#endif
