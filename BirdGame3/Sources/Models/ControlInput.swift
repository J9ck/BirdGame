import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#else
/// Cross-platform 2D vector type for non-Apple platforms
public struct CGVector: Equatable {
    public var dx: CGFloat
    public var dy: CGFloat
    
    public static let zero = CGVector(dx: 0, dy: 0)
    
    public init(dx: CGFloat, dy: CGFloat) {
        self.dx = dx
        self.dy = dy
    }
}

/// Cross-platform CGFloat for non-Apple platforms
public typealias CGFloat = Double
#endif

/// Represents the current state of control inputs
struct ControlInput: Equatable {
    /// Movement direction from joystick (-1 to 1 for both x and y)
    var movementDirection: CGVector
    
    /// Whether the primary attack button is pressed
    var isAttacking: Bool
    
    /// Whether the sprint button is pressed
    var isSprinting: Bool
    
    /// Whether targeting/lock-on is active
    var isTargetLocked: Bool
    
    /// Index of the skill being activated (nil if none)
    var activeSkillIndex: Int?
    
    init(
        movementDirection: CGVector = .zero,
        isAttacking: Bool = false,
        isSprinting: Bool = false,
        isTargetLocked: Bool = false,
        activeSkillIndex: Int? = nil
    ) {
        self.movementDirection = movementDirection
        self.isAttacking = isAttacking
        self.isSprinting = isSprinting
        self.isTargetLocked = isTargetLocked
        self.activeSkillIndex = activeSkillIndex
    }
    
    /// Returns a normalized movement vector (magnitude clamped to 1)
    var normalizedMovement: CGVector {
        let magnitude = sqrt(movementDirection.dx * movementDirection.dx + 
                           movementDirection.dy * movementDirection.dy)
        guard magnitude > 0 else { return .zero }
        
        let clampedMagnitude = min(magnitude, 1.0)
        return CGVector(
            dx: (movementDirection.dx / magnitude) * clampedMagnitude,
            dy: (movementDirection.dy / magnitude) * clampedMagnitude
        )
    }
    
    /// Movement speed multiplier (1.0 normal, higher when sprinting)
    var speedMultiplier: Double {
        isSprinting ? 1.5 : 1.0
    }
}
