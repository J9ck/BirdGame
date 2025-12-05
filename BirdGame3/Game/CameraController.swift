//
//  CameraController.swift
//  BirdGame3
//
//  Third-person camera system with follow, collision, lock-on, and configurable sensitivity
//

import Foundation
import SceneKit

// MARK: - Camera Mode

enum CameraMode: String, CaseIterable {
    case follow      // Standard third-person follow
    case lockOn      // Lock-on to target
    case aim         // Over-the-shoulder aim mode
    case cinematic   // Wide cinematic view
    case topDown     // Top-down strategic view
    
    var distance: Float {
        switch self {
        case .follow: return 30.0
        case .lockOn: return 25.0
        case .aim: return 15.0
        case .cinematic: return 50.0
        case .topDown: return 100.0
        }
    }
    
    var heightOffset: Float {
        switch self {
        case .follow: return 15.0
        case .lockOn: return 10.0
        case .aim: return 8.0
        case .cinematic: return 20.0
        case .topDown: return 80.0
        }
    }
    
    var fieldOfView: CGFloat {
        switch self {
        case .follow: return 70.0
        case .lockOn: return 60.0
        case .aim: return 50.0
        case .cinematic: return 80.0
        case .topDown: return 60.0
        }
    }
}

// MARK: - Camera Settings

struct CameraSettings: Codable {
    var sensitivityX: Float = 1.0
    var sensitivityY: Float = 1.0
    var invertY: Bool = false
    var invertX: Bool = false
    var smoothing: Float = 5.0
    var autoRotate: Bool = true
    var collisionEnabled: Bool = true
    var shakeEnabled: Bool = true
    
    static let `default` = CameraSettings()
    
    mutating func setSensitivity(_ value: Float) {
        sensitivityX = value
        sensitivityY = value
    }
}

// MARK: - Camera Controller

/// Controls the third-person camera in the 3D scene
class CameraController: ObservableObject {
    
    // MARK: - Properties
    
    /// The camera node
    let cameraNode: SCNNode
    
    /// Current camera mode
    @Published var mode: CameraMode = .follow {
        didSet { updateCameraForMode() }
    }
    
    /// Camera settings
    @Published var settings: CameraSettings = .default {
        didSet { saveSettings() }
    }
    
    /// Current lock-on target
    @Published var lockOnTarget: SCNNode?
    
    /// Whether the camera is locked on
    var isLockedOn: Bool { lockOnTarget != nil && mode == .lockOn }
    
    /// Target to follow (player bird)
    weak var target: SCNNode?
    
    /// Current camera offset from target
    private var currentOffset: SCNVector3 = SCNVector3(0, 15, 30)
    
    /// Target offset (for smooth transitions)
    private var targetOffset: SCNVector3 = SCNVector3(0, 15, 30)
    
    /// Camera yaw (horizontal rotation)
    private var yaw: Float = 0.0
    
    /// Camera pitch (vertical rotation)
    private var pitch: Float = -0.2
    
    /// Minimum pitch (looking down)
    private let minPitch: Float = -Float.pi / 3
    
    /// Maximum pitch (looking up)
    private let maxPitch: Float = Float.pi / 6
    
    /// Camera shake intensity
    private var shakeIntensity: Float = 0.0
    
    /// Camera shake decay rate
    private let shakeDecay: Float = 5.0
    
    // MARK: - Collision
    
    /// Collision detection layer mask
    private let collisionMask: Int = 0b0001 // Terrain layer
    
    /// Minimum distance from obstacles
    private let minDistanceFromObstacle: Float = 2.0
    
    // MARK: - Persistence
    
    private let settingsKey = "birdgame3_cameraSettings"
    
    // MARK: - Initialization
    
    init() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 5000
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.fieldOfView = 70
        cameraNode.name = "mainCamera"
        
        loadSettings()
    }
    
    // MARK: - Update
    
    /// Update camera position and rotation
    /// - Parameters:
    ///   - deltaTime: Time since last update
    func update(deltaTime: TimeInterval) {
        guard let target = target else { return }
        
        let dt = Float(deltaTime)
        
        // Calculate desired position based on mode
        let desiredPosition: SCNVector3
        let lookAtPosition: SCNVector3
        
        if isLockedOn, let lockOn = lockOnTarget {
            // Lock-on mode: position camera to show both player and target
            let midpoint = SCNVector3(
                (target.position.x + lockOn.position.x) / 2,
                (target.position.y + lockOn.position.y) / 2 + mode.heightOffset,
                (target.position.z + lockOn.position.z) / 2
            )
            
            let distanceToTarget = distance(from: target.position, to: lockOn.position)
            let cameraDistance = max(mode.distance, distanceToTarget * 0.8)
            
            desiredPosition = SCNVector3(
                midpoint.x - sin(yaw) * cameraDistance,
                midpoint.y + mode.heightOffset,
                midpoint.z - cos(yaw) * cameraDistance
            )
            lookAtPosition = lockOn.position
        } else {
            // Normal follow mode
            let offsetX = sin(yaw) * mode.distance
            let offsetZ = cos(yaw) * mode.distance
            let offsetY = mode.heightOffset + sin(pitch) * mode.distance * 0.5
            
            desiredPosition = SCNVector3(
                target.position.x - offsetX,
                target.position.y + offsetY,
                target.position.z - offsetZ
            )
            lookAtPosition = SCNVector3(
                target.position.x,
                target.position.y + 5,
                target.position.z
            )
        }
        
        // Apply collision detection
        var finalPosition = desiredPosition
        if settings.collisionEnabled {
            finalPosition = applyCollision(from: target.position, to: desiredPosition)
        }
        
        // Smooth position transition
        let smoothing = settings.smoothing * dt
        currentOffset.x += (finalPosition.x - cameraNode.position.x) * smoothing
        currentOffset.y += (finalPosition.y - cameraNode.position.y) * smoothing
        currentOffset.z += (finalPosition.z - cameraNode.position.z) * smoothing
        
        // Apply camera shake
        var shakeOffset = SCNVector3.zero
        if shakeIntensity > 0 && settings.shakeEnabled {
            shakeOffset = SCNVector3(
                Float.random(in: -shakeIntensity...shakeIntensity),
                Float.random(in: -shakeIntensity...shakeIntensity),
                Float.random(in: -shakeIntensity...shakeIntensity)
            )
            shakeIntensity = max(0, shakeIntensity - shakeDecay * dt)
        }
        
        cameraNode.position = SCNVector3(
            currentOffset.x + shakeOffset.x,
            currentOffset.y + shakeOffset.y,
            currentOffset.z + shakeOffset.z
        )
        
        // Look at target
        cameraNode.look(at: lookAtPosition)
    }
    
    // MARK: - Input Handling
    
    /// Handle camera rotation input (from touch/joystick)
    func handleRotationInput(x: Float, y: Float) {
        let sensitivityScale: Float = 0.01
        
        // Apply sensitivity and inversion
        let deltaX = x * settings.sensitivityX * sensitivityScale * (settings.invertX ? -1 : 1)
        let deltaY = y * settings.sensitivityY * sensitivityScale * (settings.invertY ? -1 : 1)
        
        // Update yaw (horizontal)
        yaw += deltaX
        
        // Update pitch (vertical) with clamping
        pitch = max(minPitch, min(maxPitch, pitch - deltaY))
    }
    
    /// Reset camera to default position behind target
    func resetBehindTarget() {
        guard let target = target else { return }
        yaw = target.eulerAngles.y
        pitch = -0.2
    }
    
    // MARK: - Lock-On
    
    /// Toggle lock-on to nearest enemy
    func toggleLockOn(enemies: [SCNNode]) {
        if isLockedOn {
            // Disable lock-on
            lockOnTarget = nil
            mode = .follow
        } else if let target = target {
            // Find nearest enemy
            let sortedEnemies = enemies.sorted { enemy1, enemy2 in
                distance(from: target.position, to: enemy1.position) <
                distance(from: target.position, to: enemy2.position)
            }
            
            if let nearest = sortedEnemies.first {
                lockOnTarget = nearest
                mode = .lockOn
            }
        }
    }
    
    /// Cycle to next lock-on target
    func cycleTarget(enemies: [SCNNode], forward: Bool = true) {
        guard let current = lockOnTarget,
              let currentIndex = enemies.firstIndex(of: current) else { return }
        
        let nextIndex: Int
        if forward {
            nextIndex = (currentIndex + 1) % enemies.count
        } else {
            nextIndex = (currentIndex - 1 + enemies.count) % enemies.count
        }
        
        lockOnTarget = enemies[nextIndex]
    }
    
    // MARK: - Camera Effects
    
    /// Trigger camera shake
    func shake(intensity: Float, duration: TimeInterval? = nil) {
        shakeIntensity = intensity
        
        if let dur = duration {
            DispatchQueue.main.asyncAfter(deadline: .now() + dur) { [weak self] in
                self?.shakeIntensity = 0
            }
        }
    }
    
    /// Zoom camera
    func zoom(to fov: CGFloat, duration: TimeInterval = 0.3) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = duration
        cameraNode.camera?.fieldOfView = fov
        SCNTransaction.commit()
    }
    
    /// Reset zoom to mode default
    func resetZoom() {
        zoom(to: mode.fieldOfView)
    }
    
    // MARK: - Mode Changes
    
    private func updateCameraForMode() {
        targetOffset = SCNVector3(0, mode.heightOffset, mode.distance)
        zoom(to: mode.fieldOfView)
    }
    
    // MARK: - Collision Detection
    
    private func applyCollision(from playerPos: SCNVector3, to desiredCamPos: SCNVector3) -> SCNVector3 {
        // Simple ray-based collision
        // In a real implementation, this would use SceneKit's physics raycast
        
        let direction = SCNVector3(
            desiredCamPos.x - playerPos.x,
            desiredCamPos.y - playerPos.y,
            desiredCamPos.z - playerPos.z
        )
        
        let length = direction.magnitude
        
        // Check minimum height
        if desiredCamPos.y < 5 {
            return SCNVector3(
                desiredCamPos.x,
                max(5, desiredCamPos.y),
                desiredCamPos.z
            )
        }
        
        return desiredCamPos
    }
    
    // MARK: - Helpers
    
    private func distance(from a: SCNVector3, to b: SCNVector3) -> Float {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let dz = b.z - a.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
    
    // MARK: - Persistence
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let loaded = try? JSONDecoder().decode(CameraSettings.self, from: data) {
            settings = loaded
        }
    }
}

// MARK: - Camera Presets

extension CameraController {
    
    /// Apply a preset camera configuration
    func applyPreset(_ preset: CameraPreset) {
        switch preset {
        case .default:
            settings = .default
        case .sensitive:
            settings.sensitivityX = 1.5
            settings.sensitivityY = 1.5
        case .relaxed:
            settings.sensitivityX = 0.7
            settings.sensitivityY = 0.7
            settings.smoothing = 3.0
        case .competitive:
            settings.sensitivityX = 1.2
            settings.sensitivityY = 1.2
            settings.smoothing = 8.0
            settings.collisionEnabled = false
        }
    }
}

enum CameraPreset: String, CaseIterable {
    case `default` = "Default"
    case sensitive = "Sensitive"
    case relaxed = "Relaxed"
    case competitive = "Competitive"
}
