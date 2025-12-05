//
//  OpenWorld3DScene.swift
//  BirdGame3
//
//  Main SceneKit scene for 3D open world exploration
//

import SceneKit
import SwiftUI

// MARK: - Open World 3D Scene

/// Main SceneKit scene for the 3D open world flying experience
class OpenWorld3DScene: SCNScene {
    
    // MARK: - Properties
    
    /// The player's 3D bird node
    var playerBird: Bird3DNode?
    
    /// The camera node that follows the player
    var cameraNode: SCNNode!
    
    /// The terrain generator
    var terrain: Terrain3D!
    
    /// Reference to the open world manager
    weak var openWorldManager: OpenWorldManager?
    
    /// Current biome visual settings
    private var currentBiome: Biome = .plains
    
    /// Prey nodes in the scene
    private var preyNodes: [String: SCNNode] = [:]
    
    /// Resource nodes in the scene
    private var resourceNodes: [String: SCNNode] = [:]
    
    /// Player marker nodes
    private var playerMarkerNodes: [String: SCNNode] = [:]
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupScene()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupScene()
    }
    
    /// Initialize with a specific bird type and manager reference
    convenience init(birdType: BirdType, manager: OpenWorldManager) {
        self.init()
        self.openWorldManager = manager
        setupPlayerBird(type: birdType)
        updateBiome(manager.playerState.currentBiome)
    }
    
    // MARK: - Scene Setup
    
    private func setupScene() {
        setupLighting()
        setupCamera()
        setupTerrain()
        setupSkybox()
        setupFog()
    }
    
    private func setupLighting() {
        // Ambient light for base illumination
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 500
        ambientLight.light?.color = UIColor(white: 0.6, alpha: 1.0)
        rootNode.addChildNode(ambientLight)
        
        // Directional light (sun)
        let sunNode = SCNNode()
        sunNode.light = SCNLight()
        sunNode.light?.type = .directional
        sunNode.light?.intensity = 1000
        sunNode.light?.color = UIColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1.0)
        sunNode.light?.castsShadow = true
        sunNode.light?.shadowMode = .deferred
        sunNode.light?.shadowColor = UIColor.black.withAlphaComponent(0.5)
        sunNode.light?.shadowRadius = 3
        sunNode.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 6, 0)
        sunNode.name = "sunLight"
        rootNode.addChildNode(sunNode)
    }
    
    private func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 5000
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.fieldOfView = 70
        cameraNode.name = "mainCamera"
        
        // Position camera behind and above the player
        cameraNode.position = SCNVector3(0, 30, 50)
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 8, 0, 0)
        
        rootNode.addChildNode(cameraNode)
    }
    
    private func setupTerrain() {
        terrain = Terrain3D()
        rootNode.addChildNode(terrain.terrainNode)
    }
    
    private func setupSkybox() {
        // Create a simple gradient sky using a large sphere
        let skyGeometry = SCNSphere(radius: 2000)
        skyGeometry.segmentCount = 24
        
        let skyMaterial = SCNMaterial()
        skyMaterial.isDoubleSided = true
        skyMaterial.diffuse.contents = createSkyGradient()
        skyMaterial.lightingModel = .constant
        skyGeometry.materials = [skyMaterial]
        
        let skyNode = SCNNode(geometry: skyGeometry)
        skyNode.name = "sky"
        rootNode.addChildNode(skyNode)
    }
    
    private func createSkyGradient() -> UIImage {
        let size = CGSize(width: 1, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let colors = [
                UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0).cgColor,
                UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0).cgColor
            ]
            
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0, 1]
            )!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint.zero,
                end: CGPoint(x: 0, y: size.height),
                options: []
            )
        }
    }
    
    private func setupFog() {
        fogStartDistance = 500
        fogEndDistance = 2000
        fogColor = UIColor(red: 0.7, green: 0.8, blue: 0.9, alpha: 1.0)
    }
    
    // MARK: - Player Bird Setup
    
    func setupPlayerBird(type: BirdType) {
        // Remove existing bird if any
        playerBird?.removeFromParentNode()
        
        // Create new bird node
        let bird = Bird3DNode(birdType: type)
        bird.position = SCNVector3(0, 50, 0)
        bird.name = "playerBird"
        
        rootNode.addChildNode(bird)
        playerBird = bird
    }
    
    // MARK: - Biome Updates
    
    func updateBiome(_ biome: Biome) {
        guard biome != currentBiome else { return }
        currentBiome = biome
        
        // Update terrain colors based on biome
        terrain.updateBiomeColors(biome)
        
        // Update sky and fog colors based on biome
        updateEnvironmentForBiome(biome)
    }
    
    private func updateEnvironmentForBiome(_ biome: Biome) {
        let (skyColor, fogColor) = biome.environmentColors
        
        // Update fog
        self.fogColor = fogColor
        
        // Update sky (recreate sky sphere with new gradient)
        if let skyNode = rootNode.childNode(withName: "sky", recursively: false) {
            if let material = skyNode.geometry?.firstMaterial {
                material.diffuse.contents = createBiomeSkyGradient(topColor: skyColor, bottomColor: fogColor)
            }
        }
        
        // Update sun light color based on biome
        if let sunNode = rootNode.childNode(withName: "sunLight", recursively: false) {
            sunNode.light?.color = biome.sunLightColor
        }
    }
    
    private func createBiomeSkyGradient(topColor: UIColor, bottomColor: UIColor) -> UIImage {
        let size = CGSize(width: 1, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let colors = [topColor.cgColor, bottomColor.cgColor]
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0, 1]
            )!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint.zero,
                end: CGPoint(x: 0, y: size.height),
                options: []
            )
        }
    }
    
    // MARK: - Time of Day Updates
    
    func updateTimeOfDay(_ time: TimeOfDay) {
        guard let sunNode = rootNode.childNode(withName: "sunLight", recursively: false) else { return }
        
        switch time {
        case .dawn:
            sunNode.light?.intensity = 600
            sunNode.light?.color = UIColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 1.0)
            sunNode.eulerAngles = SCNVector3(-Float.pi / 8, Float.pi / 3, 0)
        case .day:
            sunNode.light?.intensity = 1000
            sunNode.light?.color = UIColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1.0)
            sunNode.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 6, 0)
        case .dusk:
            sunNode.light?.intensity = 500
            sunNode.light?.color = UIColor(red: 1.0, green: 0.6, blue: 0.4, alpha: 1.0)
            sunNode.eulerAngles = SCNVector3(-Float.pi / 8, -Float.pi / 3, 0)
        case .night:
            sunNode.light?.intensity = 100
            sunNode.light?.color = UIColor(red: 0.5, green: 0.6, blue: 0.8, alpha: 1.0)
            sunNode.eulerAngles = SCNVector3(Float.pi / 8, 0, 0)
        }
    }
    
    // MARK: - Prey Management
    
    func updatePrey(_ nearbyPrey: [Prey], huntingTarget: Prey?) {
        // Remove prey that are no longer nearby
        let currentPreyIds = Set(nearbyPrey.map { $0.id })
        for (id, node) in preyNodes where !currentPreyIds.contains(id) {
            node.removeFromParentNode()
            preyNodes.removeValue(forKey: id)
        }
        
        // Add or update prey nodes
        for prey in nearbyPrey {
            if let existingNode = preyNodes[prey.id] {
                // Update position
                let targetPos = SCNVector3(
                    Float(prey.position.x - (openWorldManager?.playerState.position.x ?? 0)),
                    Float(prey.position.z),
                    Float(prey.position.y - (openWorldManager?.playerState.position.y ?? 0))
                )
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.3
                existingNode.position = targetPos
                SCNTransaction.commit()
                
                // Update scale if target
                let isTarget = huntingTarget?.id == prey.id
                existingNode.scale = isTarget ? SCNVector3(1.5, 1.5, 1.5) : SCNVector3(1, 1, 1)
            } else {
                // Create new prey node
                let preyNode = createPreyNode(prey, isTarget: huntingTarget?.id == prey.id)
                preyNodes[prey.id] = preyNode
                rootNode.addChildNode(preyNode)
            }
        }
    }
    
    private func createPreyNode(_ prey: Prey, isTarget: Bool) -> SCNNode {
        let node = SCNNode()
        
        // Create simple geometry based on prey type
        let geometry: SCNGeometry
        let color: UIColor
        
        switch prey.type {
        case .worm, .caterpillar:
            geometry = SCNCapsule(capRadius: 0.3, height: 2)
            color = UIColor.brown
        case .beetle, .grasshopper:
            geometry = SCNBox(width: 1, height: 0.5, length: 1.5, chamferRadius: 0.1)
            color = UIColor.darkGray
        case .dragonfly:
            geometry = SCNCapsule(capRadius: 0.2, height: 3)
            color = UIColor.cyan
        case .fish:
            geometry = SCNCapsule(capRadius: 0.5, height: 2)
            color = UIColor.gray
        case .frog:
            geometry = SCNSphere(radius: 1)
            color = UIColor.green
        case .mouse:
            geometry = SCNCapsule(capRadius: 0.5, height: 1.5)
            color = UIColor.lightGray
        case .rabbit:
            geometry = SCNCapsule(capRadius: 0.8, height: 2)
            color = UIColor.white
        case .snake:
            geometry = SCNCapsule(capRadius: 0.3, height: 4)
            color = UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)
        }
        
        let material = SCNMaterial()
        material.diffuse.contents = color
        geometry.materials = [material]
        
        node.geometry = geometry
        node.position = SCNVector3(
            Float(prey.position.x - (openWorldManager?.playerState.position.x ?? 0)),
            Float(prey.position.z),
            Float(prey.position.y - (openWorldManager?.playerState.position.y ?? 0))
        )
        
        // Add label
        let labelNode = createLabelNode(text: prey.type.emoji)
        labelNode.position = SCNVector3(0, 2, 0)
        node.addChildNode(labelNode)
        
        if isTarget {
            node.scale = SCNVector3(1.5, 1.5, 1.5)
        }
        
        return node
    }
    
    // MARK: - Resource Management
    
    func updateResources(_ nearbyResources: [Resource]) {
        let currentResourceIds = Set(nearbyResources.map { $0.id })
        
        // Remove resources no longer nearby
        for (id, node) in resourceNodes where !currentResourceIds.contains(id) {
            node.removeFromParentNode()
            resourceNodes.removeValue(forKey: id)
        }
        
        // Add new resources
        for resource in nearbyResources where resourceNodes[resource.id] == nil {
            let node = createResourceNode(resource)
            resourceNodes[resource.id] = node
            rootNode.addChildNode(node)
        }
    }
    
    private func createResourceNode(_ resource: Resource) -> SCNNode {
        let node = SCNNode()
        
        let geometry: SCNGeometry
        let color: UIColor
        
        switch resource.type {
        case .twigs:
            geometry = SCNCylinder(radius: 0.1, height: 2)
            color = UIColor.brown
        case .leaves:
            geometry = SCNPlane(width: 1, height: 1)
            color = UIColor.green
        case .feathers:
            geometry = SCNCapsule(capRadius: 0.1, height: 1)
            color = UIColor.white
        case .berries:
            geometry = SCNSphere(radius: 0.3)
            color = UIColor.purple
        case .bugs:
            geometry = SCNSphere(radius: 0.2)
            color = UIColor.brown
        case .shinyObjects:
            geometry = SCNSphere(radius: 0.4)
            color = UIColor.yellow
        case .moss:
            geometry = SCNBox(width: 1, height: 0.2, length: 1, chamferRadius: 0.1)
            color = UIColor(red: 0.2, green: 0.4, blue: 0.2, alpha: 1.0)
        case .mud:
            geometry = SCNCylinder(radius: 0.5, height: 0.3)
            color = UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)
        }
        
        let material = SCNMaterial()
        material.diffuse.contents = color
        geometry.materials = [material]
        
        node.geometry = geometry
        node.position = SCNVector3(
            Float(resource.position.x - (openWorldManager?.playerState.position.x ?? 0)),
            Float(resource.position.z),
            Float(resource.position.y - (openWorldManager?.playerState.position.y ?? 0))
        )
        
        // Add floating animation for shiny objects
        if resource.type == .shinyObjects {
            let floatAction = SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 0.5, z: 0, duration: 1),
                SCNAction.moveBy(x: 0, y: -0.5, z: 0, duration: 1)
            ])
            node.runAction(SCNAction.repeatForever(floatAction))
        }
        
        return node
    }
    
    // MARK: - Player Markers
    
    func updateOtherPlayers(_ players: [WorldPlayer]) {
        let currentPlayerIds = Set(players.map { $0.id })
        
        // Remove players no longer nearby
        for (id, node) in playerMarkerNodes where !currentPlayerIds.contains(id) {
            node.removeFromParentNode()
            playerMarkerNodes.removeValue(forKey: id)
        }
        
        // Add or update player markers
        for player in players {
            if let existingNode = playerMarkerNodes[player.id] {
                // Update position
                let targetPos = SCNVector3(
                    Float(player.position.x - (openWorldManager?.playerState.position.x ?? 0)),
                    Float(player.position.z),
                    Float(player.position.y - (openWorldManager?.playerState.position.y ?? 0))
                )
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.3
                existingNode.position = targetPos
                SCNTransaction.commit()
            } else {
                let node = createPlayerMarkerNode(player)
                playerMarkerNodes[player.id] = node
                rootNode.addChildNode(node)
            }
        }
    }
    
    private func createPlayerMarkerNode(_ player: WorldPlayer) -> SCNNode {
        let node = SCNNode()
        
        // Create a simple bird shape for other players
        let bodyGeometry = SCNCapsule(capRadius: 1, height: 2)
        let material = SCNMaterial()
        material.diffuse.contents = player.isHostile ? UIColor.red : UIColor.blue
        bodyGeometry.materials = [material]
        
        node.geometry = bodyGeometry
        node.position = SCNVector3(
            Float(player.position.x - (openWorldManager?.playerState.position.x ?? 0)),
            Float(player.position.z),
            Float(player.position.y - (openWorldManager?.playerState.position.y ?? 0))
        )
        
        // Add name label
        let labelNode = createLabelNode(text: player.name)
        labelNode.position = SCNVector3(0, 3, 0)
        node.addChildNode(labelNode)
        
        return node
    }
    
    private func createLabelNode(text: String) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 0.1)
        textGeometry.font = UIFont.systemFont(ofSize: 1)
        textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        textGeometry.flatness = 0.1
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        material.lightingModel = .constant
        textGeometry.materials = [material]
        
        let node = SCNNode(geometry: textGeometry)
        node.scale = SCNVector3(0.5, 0.5, 0.5)
        
        // Add constraint to always face camera
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = [.X, .Y]
        node.constraints = [billboardConstraint]
        
        return node
    }
    
    // MARK: - Nest Visualization
    
    func updateNest(_ nest: Nest?) {
        // Remove existing nest
        rootNode.childNode(withName: "homeNest", recursively: false)?.removeFromParentNode()
        
        guard let nest = nest else { return }
        
        let nestNode = createNestNode(nest)
        nestNode.name = "homeNest"
        nestNode.position = SCNVector3(
            Float(nest.position.x - (openWorldManager?.playerState.position.x ?? 0)),
            Float(nest.position.z),
            Float(nest.position.y - (openWorldManager?.playerState.position.y ?? 0))
        )
        
        rootNode.addChildNode(nestNode)
    }
    
    private func createNestNode(_ nest: Nest) -> SCNNode {
        let nestNode = SCNNode()
        
        // Base nest structure
        let baseGeometry = SCNCylinder(radius: CGFloat(2 + nest.level), height: CGFloat(1 + nest.level / 2))
        let baseMaterial = SCNMaterial()
        baseMaterial.diffuse.contents = UIColor.brown
        baseGeometry.materials = [baseMaterial]
        
        let baseNode = SCNNode(geometry: baseGeometry)
        nestNode.addChildNode(baseNode)
        
        // Add nest components visually
        for (index, component) in nest.components.enumerated() {
            let componentNode = createNestComponentNode(component, index: index)
            nestNode.addChildNode(componentNode)
        }
        
        return nestNode
    }
    
    private func createNestComponentNode(_ component: NestComponent, index: Int) -> SCNNode {
        let node = SCNNode()
        
        let geometry: SCNGeometry
        let color: UIColor
        
        switch component.type {
        case .foundation:
            geometry = SCNCylinder(radius: 3, height: 0.5)
            color = UIColor.brown
        case .wall:
            geometry = SCNBox(width: 1, height: 2, length: 0.2, chamferRadius: 0)
            color = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        case .roof:
            geometry = SCNCone(topRadius: 0, bottomRadius: 3, height: 1.5)
            color = UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)
        case .door:
            geometry = SCNBox(width: 0.8, height: 1.5, length: 0.1, chamferRadius: 0.1)
            color = UIColor(red: 0.5, green: 0.3, blue: 0.2, alpha: 1.0)
        case .window:
            geometry = SCNBox(width: 0.5, height: 0.5, length: 0.1, chamferRadius: 0)
            color = UIColor.cyan.withAlphaComponent(0.7)
        case .storageBox:
            geometry = SCNBox(width: 1, height: 0.8, length: 0.8, chamferRadius: 0.1)
            color = UIColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 1.0)
        case .perch:
            geometry = SCNCylinder(radius: 0.1, height: 1.5)
            color = UIColor.brown
        case .decoration:
            geometry = SCNSphere(radius: 0.3)
            color = UIColor.yellow
        case .trap:
            geometry = SCNBox(width: 0.5, height: 0.3, length: 0.5, chamferRadius: 0)
            color = UIColor.gray
        }
        
        let material = SCNMaterial()
        material.diffuse.contents = color
        geometry.materials = [material]
        
        node.geometry = geometry
        
        // Position based on grid position
        let xOffset = Float(component.position.gridX - 1) * 2
        let yOffset = Float(component.position.layer) * 1.5
        let zOffset = Float(component.position.gridY - 1) * 2
        node.position = SCNVector3(xOffset, yOffset, zOffset)
        
        return node
    }
    
    // MARK: - Camera Updates
    
    func updateCamera() {
        guard let bird = playerBird else { return }
        
        // Calculate camera position behind and above the bird
        let birdPosition = bird.position
        let birdRotation = bird.eulerAngles.y
        
        // Camera offset behind the bird
        let cameraDistance: Float = 30
        let cameraHeight: Float = 15
        
        let cameraX = birdPosition.x - sin(birdRotation) * cameraDistance
        let cameraY = birdPosition.y + cameraHeight
        let cameraZ = birdPosition.z - cos(birdRotation) * cameraDistance
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.1
        
        cameraNode.position = SCNVector3(cameraX, cameraY, cameraZ)
        cameraNode.look(at: SCNVector3(birdPosition.x, birdPosition.y + 5, birdPosition.z))
        
        SCNTransaction.commit()
    }
    
    // MARK: - Movement
    
    func movePlayer(direction: WorldPosition, speed: Float) {
        guard let bird = playerBird else { return }
        
        // Update bird rotation based on movement direction
        if direction.x != 0 || direction.y != 0 {
            let targetAngle = atan2(Float(direction.x), Float(direction.y))
            bird.eulerAngles.y = targetAngle
        }
        
        // Move the bird
        let moveSpeed = speed * 2
        bird.position.x += Float(direction.x) * moveSpeed
        bird.position.z += Float(direction.y) * moveSpeed
        bird.position.y += Float(direction.z) * moveSpeed
        
        // Clamp altitude
        bird.position.y = max(5, min(500, bird.position.y))
        
        // Update camera to follow
        updateCamera()
        
        // Animate wings
        bird.animateFlying()
    }
    
    func setPlayerAltitude(_ altitude: Float) {
        guard let bird = playerBird else { return }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        bird.position.y = max(5, min(500, altitude))
        SCNTransaction.commit()
        
        updateCamera()
    }
}

// MARK: - Biome Extensions

extension Biome {
    var environmentColors: (sky: UIColor, fog: UIColor) {
        switch self {
        case .forest:
            return (UIColor(red: 0.4, green: 0.6, blue: 0.3, alpha: 1.0),
                    UIColor(red: 0.3, green: 0.4, blue: 0.3, alpha: 1.0))
        case .desert:
            return (UIColor(red: 0.9, green: 0.8, blue: 0.6, alpha: 1.0),
                    UIColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 1.0))
        case .mountain:
            return (UIColor(red: 0.6, green: 0.7, blue: 0.9, alpha: 1.0),
                    UIColor(red: 0.7, green: 0.7, blue: 0.8, alpha: 1.0))
        case .swamp:
            return (UIColor(red: 0.4, green: 0.5, blue: 0.4, alpha: 1.0),
                    UIColor(red: 0.3, green: 0.4, blue: 0.3, alpha: 1.0))
        case .beach:
            return (UIColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 1.0),
                    UIColor(red: 0.6, green: 0.7, blue: 0.8, alpha: 1.0))
        case .tundra:
            return (UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0),
                    UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0))
        case .jungle:
            return (UIColor(red: 0.3, green: 0.5, blue: 0.4, alpha: 1.0),
                    UIColor(red: 0.2, green: 0.4, blue: 0.3, alpha: 1.0))
        case .plains:
            return (UIColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 1.0),
                    UIColor(red: 0.6, green: 0.7, blue: 0.6, alpha: 1.0))
        }
    }
    
    var sunLightColor: UIColor {
        switch self {
        case .forest, .jungle:
            return UIColor(red: 0.9, green: 1.0, blue: 0.8, alpha: 1.0)
        case .desert:
            return UIColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0)
        case .mountain, .tundra:
            return UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0)
        case .swamp:
            return UIColor(red: 0.8, green: 0.9, blue: 0.7, alpha: 1.0)
        case .beach:
            return UIColor(red: 1.0, green: 1.0, blue: 0.95, alpha: 1.0)
        case .plains:
            return UIColor(red: 1.0, green: 0.98, blue: 0.9, alpha: 1.0)
        }
    }
}
