//
//  Bird3DNode.swift
//  BirdGame3
//
//  3D bird controller for SceneKit open world
//

import SceneKit

// MARK: - Bird 3D Node

/// A 3D node representing a bird in the open world scene
class Bird3DNode: SCNNode {
    
    // MARK: - Properties
    
    /// The type of bird this node represents
    let birdType: BirdType
    
    /// Wing nodes for animation
    private var leftWing: SCNNode?
    private var rightWing: SCNNode?
    
    /// Tail node
    private var tail: SCNNode?
    
    /// Is the bird currently flying (wings animating)
    private var isFlying = false
    
    /// Wing animation action key
    private let wingAnimationKey = "wingFlap"
    
    // MARK: - Initialization
    
    init(birdType: BirdType) {
        self.birdType = birdType
        super.init()
        setupBirdModel()
    }
    
    required init?(coder: NSCoder) {
        self.birdType = .pigeon
        super.init(coder: coder)
        setupBirdModel()
    }
    
    // MARK: - Setup
    
    private func setupBirdModel() {
        // Create body
        let bodyNode = createBody()
        addChildNode(bodyNode)
        
        // Create head
        let headNode = createHead()
        addChildNode(headNode)
        
        // Create wings
        let (left, right) = createWings()
        leftWing = left
        rightWing = right
        addChildNode(left)
        addChildNode(right)
        
        // Create tail
        let tailNode = createTail()
        tail = tailNode
        addChildNode(tailNode)
        
        // Scale based on bird type
        let scale = birdType.modelScale
        self.scale = SCNVector3(scale, scale, scale)
    }
    
    private func createBody() -> SCNNode {
        let bodyGeometry = SCNCapsule(capRadius: 0.5, height: 1.5)
        let material = SCNMaterial()
        material.diffuse.contents = birdType.bodyColor
        material.specular.contents = UIColor.white
        material.shininess = 0.3
        bodyGeometry.materials = [material]
        
        let bodyNode = SCNNode(geometry: bodyGeometry)
        bodyNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        bodyNode.name = "body"
        
        return bodyNode
    }
    
    private func createHead() -> SCNNode {
        let headGeometry = SCNSphere(radius: 0.4)
        let material = SCNMaterial()
        material.diffuse.contents = birdType.headColor
        headGeometry.materials = [material]
        
        let headNode = SCNNode(geometry: headGeometry)
        headNode.position = SCNVector3(0, 0.3, 0.8)
        headNode.name = "head"
        
        // Add beak
        let beakNode = createBeak()
        headNode.addChildNode(beakNode)
        
        // Add eyes
        let (leftEye, rightEye) = createEyes()
        headNode.addChildNode(leftEye)
        headNode.addChildNode(rightEye)
        
        return headNode
    }
    
    private func createBeak() -> SCNNode {
        let beakGeometry = SCNCone(topRadius: 0, bottomRadius: 0.1, height: 0.4)
        let material = SCNMaterial()
        material.diffuse.contents = birdType.beakColor
        beakGeometry.materials = [material]
        
        let beakNode = SCNNode(geometry: beakGeometry)
        beakNode.position = SCNVector3(0, 0, 0.35)
        beakNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        beakNode.name = "beak"
        
        return beakNode
    }
    
    private func createEyes() -> (SCNNode, SCNNode) {
        let eyeGeometry = SCNSphere(radius: 0.08)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.black
        eyeGeometry.materials = [material]
        
        let leftEye = SCNNode(geometry: eyeGeometry)
        leftEye.position = SCNVector3(-0.2, 0.15, 0.25)
        
        let rightEye = SCNNode(geometry: eyeGeometry)
        rightEye.position = SCNVector3(0.2, 0.15, 0.25)
        
        return (leftEye, rightEye)
    }
    
    private func createWings() -> (SCNNode, SCNNode) {
        // Wing geometry - flattened box
        let wingGeometry = SCNBox(width: 0.1, height: 0.8, length: 0.6, chamferRadius: 0.05)
        let material = SCNMaterial()
        material.diffuse.contents = birdType.wingColor
        wingGeometry.materials = [material]
        
        // Left wing
        let leftWing = SCNNode(geometry: wingGeometry)
        leftWing.position = SCNVector3(-0.5, 0.2, 0)
        leftWing.pivot = SCNMatrix4MakeTranslation(0, 0.4, 0)
        leftWing.name = "leftWing"
        
        // Right wing
        let rightWing = SCNNode(geometry: wingGeometry)
        rightWing.position = SCNVector3(0.5, 0.2, 0)
        rightWing.pivot = SCNMatrix4MakeTranslation(0, -0.4, 0)
        rightWing.name = "rightWing"
        
        return (leftWing, rightWing)
    }
    
    private func createTail() -> SCNNode {
        let tailGeometry = SCNBox(width: 0.3, height: 0.05, length: 0.5, chamferRadius: 0.02)
        let material = SCNMaterial()
        material.diffuse.contents = birdType.tailColor
        tailGeometry.materials = [material]
        
        let tailNode = SCNNode(geometry: tailGeometry)
        tailNode.position = SCNVector3(0, 0, -0.9)
        tailNode.name = "tail"
        
        // Fan-like tail feathers
        for i in -1...1 {
            let featherGeometry = SCNBox(width: 0.08, height: 0.02, length: 0.4, chamferRadius: 0.01)
            featherGeometry.materials = [material]
            
            let featherNode = SCNNode(geometry: featherGeometry)
            featherNode.position = SCNVector3(Float(i) * 0.1, 0, -0.2)
            featherNode.eulerAngles = SCNVector3(0, Float(i) * 0.2, 0)
            tailNode.addChildNode(featherNode)
        }
        
        return tailNode
    }
    
    // MARK: - Animation
    
    /// Start wing flapping animation for flying
    func animateFlying() {
        guard !isFlying else { return }
        isFlying = true
        
        // Wing flap animation
        let flapUp = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(Float.pi / 4), duration: 0.15)
        let flapDown = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(-Float.pi / 4), duration: 0.15)
        let flapSequence = SCNAction.sequence([flapUp, flapDown])
        let flapForever = SCNAction.repeatForever(flapSequence)
        
        leftWing?.runAction(flapForever, forKey: wingAnimationKey)
        
        // Mirror for right wing
        let flapUpR = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(-Float.pi / 4), duration: 0.15)
        let flapDownR = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(Float.pi / 4), duration: 0.15)
        let flapSequenceR = SCNAction.sequence([flapUpR, flapDownR])
        let flapForeverR = SCNAction.repeatForever(flapSequenceR)
        
        rightWing?.runAction(flapForeverR, forKey: wingAnimationKey)
    }
    
    /// Stop wing animation (gliding)
    func stopFlying() {
        guard isFlying else { return }
        isFlying = false
        
        leftWing?.removeAction(forKey: wingAnimationKey)
        rightWing?.removeAction(forKey: wingAnimationKey)
        
        // Reset wing positions
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        leftWing?.eulerAngles = SCNVector3.zero
        rightWing?.eulerAngles = SCNVector3.zero
        SCNTransaction.commit()
    }
    
    /// Dive animation
    func animateDive() {
        let diveRotation = SCNAction.rotateBy(x: CGFloat(-Float.pi / 4), y: 0, z: 0, duration: 0.3)
        let holdDive = SCNAction.wait(duration: 0.5)
        let recover = SCNAction.rotateBy(x: CGFloat(Float.pi / 4), y: 0, z: 0, duration: 0.3)
        
        let diveSequence = SCNAction.sequence([diveRotation, holdDive, recover])
        runAction(diveSequence)
        
        // Fold wings during dive - apply to both wings
        let foldWings = SCNAction.run { [weak self] _ in
            self?.leftWing?.eulerAngles = SCNVector3(0, 0, Float.pi / 6)
            self?.rightWing?.eulerAngles = SCNVector3(0, 0, -Float.pi / 6)
        }
        let unfoldWings = SCNAction.run { [weak self] _ in
            self?.animateFlying()
        }
        
        let wingSequence = SCNAction.sequence([foldWings, SCNAction.wait(duration: 0.8), unfoldWings])
        leftWing?.runAction(wingSequence)
        rightWing?.runAction(wingSequence)
    }
    
    /// Attack animation
    func animateAttack() {
        // Quick forward lunge
        let lungeForward = SCNAction.moveBy(x: 0, y: 0, z: 2, duration: 0.1)
        let lungeBack = SCNAction.moveBy(x: 0, y: 0, z: -2, duration: 0.2)
        let lungeSequence = SCNAction.sequence([lungeForward, lungeBack])
        runAction(lungeSequence)
        
        // Beak peck animation
        if let head = childNode(withName: "head", recursively: true) {
            let peckDown = SCNAction.rotateBy(x: CGFloat(Float.pi / 6), y: 0, z: 0, duration: 0.05)
            let peckUp = SCNAction.rotateBy(x: CGFloat(-Float.pi / 6), y: 0, z: 0, duration: 0.1)
            let peckSequence = SCNAction.sequence([peckDown, peckUp])
            head.runAction(peckSequence)
        }
    }
    
    /// Idle hovering animation
    func animateIdle() {
        // Gentle bob up and down
        let bobUp = SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: 1.0)
        let bobDown = SCNAction.moveBy(x: 0, y: -0.3, z: 0, duration: 1.0)
        bobUp.timingMode = .easeInEaseOut
        bobDown.timingMode = .easeInEaseOut
        
        let bobSequence = SCNAction.sequence([bobUp, bobDown])
        let bobForever = SCNAction.repeatForever(bobSequence)
        runAction(bobForever, forKey: "idleBob")
    }
    
    func stopIdle() {
        removeAction(forKey: "idleBob")
    }
}

// MARK: - Bird Type Extensions

extension BirdType {
    var modelScale: Float {
        switch self {
        case .pigeon: return 1.0
        case .hummingbird: return 0.5
        case .eagle: return 1.8
        case .crow: return 1.1
        case .pelican: return 1.5
        case .owl: return 1.3
        }
    }
    
    var bodyColor: UIColor {
        switch self {
        case .pigeon: return UIColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)
        case .hummingbird: return UIColor(red: 0.2, green: 0.7, blue: 0.4, alpha: 1.0)
        case .eagle: return UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)
        case .crow: return UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        case .pelican: return UIColor(red: 0.95, green: 0.95, blue: 0.9, alpha: 1.0)
        case .owl: return UIColor(red: 0.55, green: 0.4, blue: 0.25, alpha: 1.0)
        }
    }
    
    var headColor: UIColor {
        switch self {
        case .pigeon: return UIColor(red: 0.4, green: 0.5, blue: 0.4, alpha: 1.0)
        case .hummingbird: return UIColor(red: 0.8, green: 0.2, blue: 0.3, alpha: 1.0)
        case .eagle: return UIColor(red: 1.0, green: 1.0, blue: 0.95, alpha: 1.0)
        case .crow: return UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        case .pelican: return UIColor(red: 0.95, green: 0.95, blue: 0.9, alpha: 1.0)
        case .owl: return UIColor(red: 0.6, green: 0.45, blue: 0.3, alpha: 1.0)
        }
    }
    
    var wingColor: UIColor {
        switch self {
        case .pigeon: return UIColor(red: 0.45, green: 0.45, blue: 0.5, alpha: 1.0)
        case .hummingbird: return UIColor(red: 0.1, green: 0.6, blue: 0.3, alpha: 1.0)
        case .eagle: return UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0)
        case .crow: return UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        case .pelican: return UIColor(red: 0.9, green: 0.9, blue: 0.85, alpha: 1.0)
        case .owl: return UIColor(red: 0.5, green: 0.35, blue: 0.2, alpha: 1.0)
        }
    }
    
    var tailColor: UIColor {
        switch self {
        case .pigeon: return UIColor(red: 0.4, green: 0.4, blue: 0.45, alpha: 1.0)
        case .hummingbird: return UIColor(red: 0.1, green: 0.5, blue: 0.3, alpha: 1.0)
        case .eagle: return UIColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0)
        case .crow: return UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        case .pelican: return UIColor(red: 0.85, green: 0.85, blue: 0.8, alpha: 1.0)
        case .owl: return UIColor(red: 0.45, green: 0.3, blue: 0.15, alpha: 1.0)
        }
    }
    
    var beakColor: UIColor {
        switch self {
        case .pigeon: return UIColor(red: 0.3, green: 0.3, blue: 0.25, alpha: 1.0)
        case .hummingbird: return UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        case .eagle: return UIColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 1.0)
        case .crow: return UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        case .pelican: return UIColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1.0)
        case .owl: return UIColor(red: 0.3, green: 0.25, blue: 0.2, alpha: 1.0)
        }
    }
}

// MARK: - SCNVector3 Zero Extension

extension SCNVector3 {
    static var zero: SCNVector3 {
        return SCNVector3(0, 0, 0)
    }
}
