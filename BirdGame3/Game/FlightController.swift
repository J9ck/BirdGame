//
//  FlightController.swift
//  BirdGame3
//
//  Enhanced 3D flight locomotion system with takeoff, landing, banking, gliding, and stamina
//

import Foundation
import SceneKit

// MARK: - Flight State

enum FlightState: String, CaseIterable {
    case grounded       // On the ground, walking
    case takeoff        // Transitioning to flight
    case flying         // Normal flight
    case gliding        // Energy-efficient glide
    case diving         // Fast downward dive
    case landing        // Transitioning to ground
    case hovering       // Stationary in air
    case sprinting      // Fast flight with extra energy cost
    
    var canAttack: Bool {
        switch self {
        case .flying, .gliding, .hovering, .sprinting:
            return true
        case .grounded, .takeoff, .landing, .diving:
            return false
        }
    }
    
    var energyDrainRate: Double {
        switch self {
        case .grounded: return 0.0
        case .takeoff: return 2.0
        case .flying: return 0.5
        case .gliding: return 0.1
        case .diving: return 0.2
        case .landing: return 0.3
        case .hovering: return 0.8
        case .sprinting: return 2.5
        }
    }
    
    var speedMultiplier: Double {
        switch self {
        case .grounded: return 0.3
        case .takeoff: return 0.5
        case .flying: return 1.0
        case .gliding: return 1.2
        case .diving: return 2.0
        case .landing: return 0.4
        case .hovering: return 0.0
        case .sprinting: return 1.8
        }
    }
}

// MARK: - Flight Controller

/// Controls 3D bird locomotion including ground movement, flight, and transitions
class FlightController: ObservableObject {
    
    // MARK: - Properties
    
    /// Current flight state
    @Published private(set) var state: FlightState = .grounded
    
    /// Current velocity vector
    @Published private(set) var velocity: SCNVector3 = SCNVector3.zero
    
    /// Current position
    @Published private(set) var position: SCNVector3 = SCNVector3(0, 50, 0)
    
    /// Current rotation (euler angles)
    @Published private(set) var rotation: SCNVector3 = SCNVector3.zero
    
    /// Current energy (stamina)
    @Published var energy: Double = 100.0
    
    /// Maximum energy
    let maxEnergy: Double = 100.0
    
    /// Energy regeneration rate per second
    var energyRegenRate: Double = 5.0
    
    /// Bank angle for turns (visual feedback)
    @Published private(set) var bankAngle: Float = 0.0
    
    /// Pitch angle for ascent/descent
    @Published private(set) var pitchAngle: Float = 0.0
    
    /// Reference to the bird type for speed calculations
    let birdType: BirdType
    
    /// Whether the bird is on the ground
    var isGrounded: Bool { state == .grounded }
    
    /// Whether the bird is in the air
    var isAirborne: Bool {
        switch state {
        case .grounded, .takeoff, .landing:
            return false
        case .flying, .gliding, .diving, .hovering, .sprinting:
            return true
        }
    }
    
    // MARK: - Constants
    
    private let gravity: Float = 9.8
    private let maxSpeed: Float = 50.0
    private let groundHeight: Float = 5.0
    private let maxAltitude: Float = 500.0
    private let bankingSpeed: Float = 2.0
    private let pitchingSpeed: Float = 1.5
    private let maxBankAngle: Float = .pi / 4 // 45 degrees
    private let maxPitchAngle: Float = .pi / 6 // 30 degrees
    private let rotationSmoothing: Float = 5.0
    private let velocitySmoothing: Float = 5.0
    
    // MARK: - Initialization
    
    init(birdType: BirdType) {
        self.birdType = birdType
        
        // Adjust energy regen based on bird type
        if birdType == .hummingbird {
            energyRegenRate = 7.5 // Hypermetabolism passive
        }
    }
    
    // MARK: - Flight Control
    
    /// Initiate takeoff from ground
    func takeoff() {
        guard state == .grounded && energy >= 10 else { return }
        
        state = .takeoff
        energy -= 10
        
        // Apply upward velocity
        velocity.y = 15.0
        
        // Transition to flying after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.state = .flying
        }
    }
    
    /// Initiate landing
    func land() {
        guard isAirborne else { return }
        
        state = .landing
        
        // Reduce horizontal velocity
        velocity.x *= 0.5
        velocity.z *= 0.5
        velocity.y = -5.0 // Gentle descent
    }
    
    /// Start gliding (energy-efficient mode)
    func startGliding() {
        guard state == .flying || state == .sprinting else { return }
        state = .gliding
    }
    
    /// Start diving (fast descent)
    func startDiving() {
        guard isAirborne else { return }
        state = .diving
        velocity.y = -30.0
    }
    
    /// Start sprinting (fast flight, high energy cost)
    func startSprinting() {
        guard (state == .flying || state == .gliding) && energy >= 20 else { return }
        state = .sprinting
    }
    
    /// Stop sprinting
    func stopSprinting() {
        if state == .sprinting {
            state = .flying
        }
    }
    
    /// Start hovering (stationary in air)
    func hover() {
        guard isAirborne && energy >= 10 else { return }
        state = .hovering
        velocity = SCNVector3.zero
    }
    
    /// Stop hovering
    func stopHovering() {
        if state == .hovering {
            state = .flying
        }
    }
    
    // MARK: - Movement Input
    
    /// Apply directional movement input
    /// - Parameters:
    ///   - direction: Normalized direction vector from joystick (x, y = horizontal, z = vertical)
    ///   - deltaTime: Time since last update
    func applyMovementInput(_ direction: SCNVector3, deltaTime: TimeInterval) {
        let dt = Float(deltaTime)
        let baseSpeed = Float(birdType.baseStats.speed) * 3.0
        let speedMult = Float(state.speedMultiplier)
        
        // Calculate target velocity
        let targetVelocity = SCNVector3(
            direction.x * baseSpeed * speedMult,
            direction.z * baseSpeed * speedMult * 0.5, // Vertical is slower
            direction.y * baseSpeed * speedMult
        )
        
        // Smooth velocity transition
        velocity.x += (targetVelocity.x - velocity.x) * velocitySmoothing * dt
        velocity.z += (targetVelocity.z - velocity.z) * velocitySmoothing * dt
        
        // Handle vertical movement based on state
        switch state {
        case .grounded:
            velocity.y = 0
        case .flying, .sprinting:
            velocity.y += (targetVelocity.y - velocity.y) * velocitySmoothing * dt
        case .gliding:
            // Gliding slowly descends
            velocity.y = max(-5.0, velocity.y - gravity * 0.1 * dt)
        case .diving:
            velocity.y = max(-50.0, velocity.y - gravity * 2.0 * dt)
        case .hovering:
            velocity.y = 0
        case .takeoff:
            velocity.y = min(20.0, velocity.y + 20.0 * dt)
        case .landing:
            velocity.y = max(-10.0, velocity.y - 5.0 * dt)
        }
        
        // Apply banking for turns
        updateBanking(direction.x, deltaTime: dt)
        
        // Apply pitching for ascent/descent
        updatePitching(direction.z, deltaTime: dt)
        
        // Update rotation to face movement direction
        if abs(direction.x) > 0.1 || abs(direction.y) > 0.1 {
            let targetYaw = atan2(direction.x, direction.y)
            rotation.y += (targetYaw - rotation.y) * rotationSmoothing * dt
        }
    }
    
    /// Update physics simulation
    func update(deltaTime: TimeInterval) {
        let dt = Float(deltaTime)
        
        // Update position
        position.x += velocity.x * dt
        position.y += velocity.y * dt
        position.z += velocity.z * dt
        
        // Clamp altitude
        position.y = max(groundHeight, min(maxAltitude, position.y))
        
        // Check for ground collision
        if position.y <= groundHeight && state != .grounded {
            if state == .landing || velocity.y < 0 {
                state = .grounded
                position.y = groundHeight
                velocity = SCNVector3.zero
                bankAngle = 0
                pitchAngle = 0
            }
        }
        
        // Drain energy based on state
        let energyDrain = state.energyDrainRate * deltaTime
        energy = max(0, energy - energyDrain)
        
        // Regenerate energy when grounded or gliding
        if state == .grounded || state == .gliding {
            energy = min(maxEnergy, energy + energyRegenRate * deltaTime)
        }
        
        // Force landing if out of energy while airborne
        if energy <= 0 && isAirborne && state != .landing && state != .diving {
            land()
        }
        
        // Apply drag
        let drag: Float = 0.98
        velocity.x *= drag
        velocity.z *= drag
    }
    
    // MARK: - Banking & Pitching
    
    private func updateBanking(_ turnInput: Float, deltaTime: Float) {
        // Calculate target bank based on turn input
        let targetBank = -turnInput * maxBankAngle
        
        // Smooth transition
        bankAngle += (targetBank - bankAngle) * bankingSpeed * deltaTime
    }
    
    private func updatePitching(_ verticalInput: Float, deltaTime: Float) {
        guard isAirborne else {
            pitchAngle = 0
            return
        }
        
        // Calculate target pitch based on vertical movement
        var targetPitch: Float = 0
        
        switch state {
        case .diving:
            targetPitch = maxPitchAngle * 2 // Nose down
        case .takeoff:
            targetPitch = -maxPitchAngle // Nose up
        default:
            targetPitch = verticalInput * maxPitchAngle
        }
        
        // Smooth transition
        pitchAngle += (targetPitch - pitchAngle) * pitchingSpeed * deltaTime
    }
    
    // MARK: - Dash/Sprint
    
    /// Perform a quick dash in the current direction
    func dash() {
        guard energy >= 15 else { return }
        
        energy -= 15
        
        // Apply burst of speed
        let dashSpeed: Float = 30.0
        velocity.x += sin(rotation.y) * dashSpeed
        velocity.z += cos(rotation.y) * dashSpeed
    }
    
    // MARK: - Reset
    
    func reset() {
        state = .flying
        position = SCNVector3(0, 50, 0)
        velocity = SCNVector3.zero
        rotation = SCNVector3.zero
        energy = maxEnergy
        bankAngle = 0
        pitchAngle = 0
    }
}

// MARK: - SCNVector3 Extensions

extension SCNVector3 {
    var magnitude: Float {
        sqrt(x * x + y * y + z * z)
    }
    
    var normalized: SCNVector3 {
        let mag = magnitude
        guard mag > 0 else { return SCNVector3.zero }
        return SCNVector3(x / mag, y / mag, z / mag)
    }
    
    static func + (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        SCNVector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }
    
    static func - (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        SCNVector3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }
    
    static func * (lhs: SCNVector3, rhs: Float) -> SCNVector3 {
        SCNVector3(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }
}
