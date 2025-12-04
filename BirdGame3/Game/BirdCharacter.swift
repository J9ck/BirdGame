//
//  BirdCharacter.swift
//  BirdGame3
//
//  The visual representation of our bird warriors in battle
//

import SpriteKit

class BirdCharacter: SKNode {
    
    // MARK: - Properties
    
    let birdType: BirdType
    let isPlayer: Bool
    
    private var bodyNode: SKShapeNode!
    private var spriteNode: SKSpriteNode?
    private var eyeNode: SKShapeNode!
    private var beakNode: SKShapeNode!
    private var wingNode: SKShapeNode!
    
    /// Whether to use sprite images instead of procedural shapes
    private var useSpriteImage: Bool = true
    
    var currentHealth: Double
    var maxHealth: Double
    var attack: Double
    var defense: Double
    var speed: Double
    var isAbilityReady: Bool = true
    var abilityCooldown: Double
    var abilityDamage: Double
    
    private var abilityCooldownTimer: Double = 0
    private var isBlocking: Bool = false
    private var isAttacking: Bool = false
    
    // MARK: - Initialization
    
    init(type: BirdType, isPlayer: Bool) {
        self.birdType = type
        self.isPlayer = isPlayer
        
        let stats = type.baseStats
        self.maxHealth = stats.maxHealth
        self.currentHealth = stats.maxHealth
        self.attack = stats.attack
        self.defense = stats.defense
        self.speed = stats.speed
        self.abilityCooldown = stats.abilityCooldown
        self.abilityDamage = stats.abilityDamage
        
        super.init()
        
        setupVisuals()
        setupPhysics()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupVisuals() {
        // Try to use sprite image first - check for file existence without loading image
        let imageExists = Bundle.main.path(forResource: birdType.rawValue, ofType: "png") != nil ||
                          Bundle.main.path(forResource: "\(birdType.rawValue)@2x", ofType: "png") != nil
        
        if useSpriteImage && imageExists {
            setupSpriteVisuals()
        } else {
            setupProceduralVisuals()
        }
        
        // Add idle animation
        startIdleAnimation()
    }
    
    private func setupSpriteVisuals() {
        let bodySize = sizeForType()
        
        // Create sprite from bird image asset
        spriteNode = SKSpriteNode(imageNamed: birdType.rawValue)
        spriteNode?.size = CGSize(width: bodySize.width * 2, height: bodySize.height * 2)
        if let sprite = spriteNode {
            addChild(sprite)
        }
        
        // Create invisible body node for animations (used by animations)
        bodyNode = SKShapeNode(ellipseOf: bodySize)
        bodyNode.fillColor = .clear
        bodyNode.strokeColor = .clear
        bodyNode.alpha = 0
        addChild(bodyNode)
        
        // Create placeholder nodes for wing animations
        wingNode = SKShapeNode(ellipseOf: CGSize(width: bodySize.width * 0.5, height: bodySize.height * 0.3))
        wingNode.fillColor = .clear
        wingNode.strokeColor = .clear
        wingNode.alpha = 0
        addChild(wingNode)
    }
    
    private func setupProceduralVisuals() {
        let bodySize = sizeForType()
        let color = colorForType()
        
        // Body
        bodyNode = SKShapeNode(ellipseOf: bodySize)
        bodyNode.fillColor = color
        bodyNode.strokeColor = color.darker()
        bodyNode.lineWidth = 2
        addChild(bodyNode)
        
        // Eye
        let eyeSize = bodySize.width * 0.15
        eyeNode = SKShapeNode(circleOfRadius: eyeSize)
        eyeNode.fillColor = .white
        eyeNode.strokeColor = .black
        eyeNode.lineWidth = 1
        eyeNode.position = CGPoint(x: bodySize.width * 0.25, y: bodySize.height * 0.15)
        addChild(eyeNode)
        
        // Pupil
        let pupilNode = SKShapeNode(circleOfRadius: eyeSize * 0.5)
        pupilNode.fillColor = .black
        pupilNode.strokeColor = .clear
        pupilNode.position = CGPoint(x: 2, y: 0)
        eyeNode.addChild(pupilNode)
        
        // Beak
        let beakPath = CGMutablePath()
        beakPath.move(to: CGPoint(x: bodySize.width * 0.4, y: 0))
        beakPath.addLine(to: CGPoint(x: bodySize.width * 0.7, y: 0))
        beakPath.addLine(to: CGPoint(x: bodySize.width * 0.4, y: -bodySize.height * 0.1))
        beakPath.closeSubpath()
        
        beakNode = SKShapeNode(path: beakPath)
        beakNode.fillColor = beakColorForType()
        beakNode.strokeColor = beakColorForType().darker()
        beakNode.lineWidth = 1
        addChild(beakNode)
        
        // Wing
        wingNode = SKShapeNode(ellipseOf: CGSize(width: bodySize.width * 0.5, height: bodySize.height * 0.3))
        wingNode.fillColor = color.darker()
        wingNode.strokeColor = color.darker().darker()
        wingNode.lineWidth = 1
        wingNode.position = CGPoint(x: -bodySize.width * 0.1, y: 0)
        addChild(wingNode)
        
        // Add type-specific details
        addTypeSpecificDetails()
    }
    
    private func sizeForType() -> CGSize {
        switch birdType {
        case .pigeon:
            return CGSize(width: 50, height: 40)
        case .hummingbird:
            return CGSize(width: 30, height: 25)
        case .eagle:
            return CGSize(width: 70, height: 50)
        case .crow:
            return CGSize(width: 45, height: 35)
        case .pelican:
            return CGSize(width: 80, height: 55)
        }
    }
    
    private func colorForType() -> SKColor {
        switch birdType {
        case .pigeon:
            return SKColor(red: 0.6, green: 0.6, blue: 0.7, alpha: 1.0)
        case .hummingbird:
            return SKColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)
        case .eagle:
            return SKColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 1.0)
        case .crow:
            return SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0)
        case .pelican:
            return SKColor(red: 0.95, green: 0.95, blue: 0.9, alpha: 1.0)
        }
    }
    
    private func beakColorForType() -> SKColor {
        switch birdType {
        case .pigeon:
            return SKColor(red: 0.8, green: 0.6, blue: 0.3, alpha: 1.0)
        case .hummingbird:
            return SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        case .eagle:
            return SKColor(red: 0.9, green: 0.8, blue: 0.2, alpha: 1.0)
        case .crow:
            return SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        case .pelican:
            return SKColor(red: 0.9, green: 0.7, blue: 0.3, alpha: 1.0)
        }
    }
    
    private func addTypeSpecificDetails() {
        switch birdType {
        case .eagle:
            // Add white head feathers
            let headFeathers = SKShapeNode(ellipseOf: CGSize(width: 25, height: 20))
            headFeathers.fillColor = .white
            headFeathers.strokeColor = SKColor.white.darker()
            headFeathers.position = CGPoint(x: 20, y: 15)
            addChild(headFeathers)
            
        case .pelican:
            // Add pouch under beak
            let pouch = SKShapeNode(ellipseOf: CGSize(width: 30, height: 20))
            pouch.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 1.0)
            pouch.strokeColor = SKColor(red: 0.9, green: 0.7, blue: 0.5, alpha: 1.0)
            pouch.position = CGPoint(x: 35, y: -15)
            addChild(pouch)
            
        case .crow:
            // Add darker coloring and mysterious vibe
            bodyNode.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
            
        case .hummingbird:
            // Add vibrant chest
            let chest = SKShapeNode(ellipseOf: CGSize(width: 15, height: 12))
            chest.fillColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
            chest.strokeColor = .clear
            chest.position = CGPoint(x: 5, y: -5)
            addChild(chest)
            
        default:
            break
        }
    }
    
    private func setupPhysics() {
        let bodySize = sizeForType()
        physicsBody = SKPhysicsBody(circleOfRadius: max(bodySize.width, bodySize.height) / 2)
        physicsBody?.isDynamic = true
        physicsBody?.allowsRotation = false
        physicsBody?.friction = 0.3
        physicsBody?.restitution = 0.1
        physicsBody?.linearDamping = 0.5
    }
    
    // MARK: - Animations
    
    private func startIdleAnimation() {
        // Gentle bobbing
        let bobUp = SKAction.moveBy(x: 0, y: 5, duration: 0.5)
        let bobDown = SKAction.moveBy(x: 0, y: -5, duration: 0.5)
        bobUp.timingMode = .easeInEaseOut
        bobDown.timingMode = .easeInEaseOut
        let bob = SKAction.sequence([bobUp, bobDown])
        
        bodyNode.run(SKAction.repeatForever(bob), withKey: "idle")
        
        // Wing flutter
        let wingUp = SKAction.rotate(byAngle: 0.2, duration: 0.15)
        let wingDown = SKAction.rotate(byAngle: -0.2, duration: 0.15)
        let flutter = SKAction.sequence([wingUp, wingDown])
        let flutterWithPause = SKAction.sequence([flutter, flutter, flutter, SKAction.wait(forDuration: 1.0)])
        
        wingNode.run(SKAction.repeatForever(flutterWithPause), withKey: "wingFlutter")
    }
    
    func playAttackAnimation() {
        isAttacking = true
        
        // Quick lunge forward
        let lungeForward = SKAction.moveBy(x: xScale > 0 ? 30 : -30, y: 0, duration: 0.1)
        let lungeBack = SKAction.moveBy(x: xScale > 0 ? -30 : 30, y: 0, duration: 0.15)
        let lunge = SKAction.sequence([lungeForward, lungeBack, SKAction.run { [weak self] in
            self?.isAttacking = false
        }])
        
        run(lunge, withKey: "attack")
        
        // Beak pecking animation
        let peckOpen = SKAction.scaleX(to: 1.3, duration: 0.05)
        let peckClose = SKAction.scaleX(to: 1.0, duration: 0.1)
        beakNode.run(SKAction.sequence([peckOpen, peckClose]))
    }
    
    func playBlockAnimation() {
        // Tuck in
        let tuck = SKAction.scaleX(to: 0.8, duration: 0.1)
        let glow = SKAction.colorize(with: .blue, colorBlendFactor: 0.3, duration: 0.1)
        
        bodyNode.run(tuck, withKey: "block")
        bodyNode.run(glow, withKey: "blockGlow")
    }
    
    func stopBlockAnimation() {
        let untuck = SKAction.scaleX(to: 1.0, duration: 0.1)
        let unglow = SKAction.colorize(withColorBlendFactor: 0, duration: 0.1)
        
        bodyNode.run(untuck, withKey: "unblock")
        bodyNode.run(unglow, withKey: "unblockGlow")
    }
    
    func playAbilityAnimation() {
        // Glow effect
        let glowUp = SKAction.colorize(with: .yellow, colorBlendFactor: 0.7, duration: 0.2)
        let glowDown = SKAction.colorize(withColorBlendFactor: 0, duration: 0.3)
        let glow = SKAction.sequence([glowUp, glowDown])
        
        bodyNode.run(glow, withKey: "ability")
        
        // Type-specific ability animations
        switch birdType {
        case .hummingbird:
            // Rapid movement
            let shake = SKAction.sequence([
                SKAction.moveBy(x: 5, y: 0, duration: 0.02),
                SKAction.moveBy(x: -10, y: 0, duration: 0.02),
                SKAction.moveBy(x: 5, y: 0, duration: 0.02)
            ])
            run(SKAction.repeat(shake, count: 10))
            
        case .eagle:
            // Dive attack
            let rise = SKAction.moveBy(x: 0, y: 50, duration: 0.2)
            let dive = SKAction.moveBy(x: xScale > 0 ? 50 : -50, y: -50, duration: 0.15)
            run(SKAction.sequence([rise, dive]))
            
        case .crow:
            // Throw shiny object
            let shiny = SKShapeNode(circleOfRadius: 8)
            shiny.fillColor = .yellow
            shiny.strokeColor = .orange
            shiny.position = position
            parent?.addChild(shiny)
            
            let moveToOpponent = SKAction.moveBy(x: xScale > 0 ? 200 : -200, y: 0, duration: 0.3)
            let sparkle = SKAction.sequence([
                SKAction.scale(to: 1.5, duration: 0.1),
                SKAction.scale(to: 0.5, duration: 0.1)
            ])
            let group = SKAction.group([moveToOpponent, SKAction.repeat(sparkle, count: 3)])
            shiny.run(SKAction.sequence([group, SKAction.removeFromParent()]))
            
        case .pelican:
            // Fish slap
            let fish = SKShapeNode(ellipseOf: CGSize(width: 30, height: 10))
            fish.fillColor = .gray
            fish.strokeColor = .darkGray
            fish.position = CGPoint(x: position.x + (xScale > 0 ? 40 : -40), y: position.y)
            parent?.addChild(fish)
            
            let swing = SKAction.rotate(byAngle: .pi, duration: 0.2)
            let move = SKAction.moveBy(x: xScale > 0 ? 60 : -60, y: 0, duration: 0.2)
            let group = SKAction.group([swing, move])
            fish.run(SKAction.sequence([group, SKAction.removeFromParent()]))
            
        case .pigeon:
            // Speed boost visual
            for _ in 0..<5 {
                let feather = SKShapeNode(ellipseOf: CGSize(width: 8, height: 4))
                feather.fillColor = colorForType()
                feather.position = position
                parent?.addChild(feather)
                
                let drift = SKAction.moveBy(x: CGFloat.random(in: -30...30), y: CGFloat.random(in: -20...20), duration: 0.5)
                let fade = SKAction.fadeOut(withDuration: 0.5)
                let group = SKAction.group([drift, fade])
                feather.run(SKAction.sequence([group, SKAction.removeFromParent()]))
            }
        }
    }
    
    func playHitAnimation() {
        let flash = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.7, duration: 0.05),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.1)
        ])
        bodyNode.run(flash)
        
        // Knockback
        let knockback = SKAction.moveBy(x: xScale > 0 ? -10 : 10, y: 5, duration: 0.1)
        let recover = SKAction.moveBy(x: xScale > 0 ? 10 : -10, y: -5, duration: 0.1)
        run(SKAction.sequence([knockback, recover]))
    }
    
    // MARK: - Combat Actions
    
    func performAttack() -> Double {
        playAttackAnimation()
        return attack
    }
    
    func useAbility() -> Double {
        guard isAbilityReady else { return 0 }
        
        playAbilityAnimation()
        isAbilityReady = false
        abilityCooldownTimer = abilityCooldown
        
        return abilityDamage
    }
    
    func receiveDamage(_ amount: Double) -> Double {
        let actualDamage: Double
        if isBlocking {
            actualDamage = amount * 0.3
        } else {
            actualDamage = max(0, amount - defense * 0.2)
        }
        
        currentHealth = max(0, currentHealth - actualDamage)
        playHitAnimation()
        
        return actualDamage
    }
    
    func startBlocking() {
        isBlocking = true
        playBlockAnimation()
    }
    
    func stopBlocking() {
        isBlocking = false
        stopBlockAnimation()
    }
    
    func move(by vector: CGVector) {
        // Clamp movement to screen bounds
        guard let scene = scene else { return }
        
        let newX = position.x + vector.dx
        let clampedX = max(50, min(scene.size.width - 50, newX))
        position.x = clampedX
    }
    
    // MARK: - Update
    
    func update(deltaTime: TimeInterval) {
        // Update ability cooldown
        if !isAbilityReady {
            abilityCooldownTimer -= deltaTime
            if abilityCooldownTimer <= 0 {
                isAbilityReady = true
                abilityCooldownTimer = 0
            }
        }
    }
}

// MARK: - SKColor Extension

extension SKColor {
    func darker() -> SKColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return SKColor(red: max(0, red - 0.1),
                       green: max(0, green - 0.1),
                       blue: max(0, blue - 0.1),
                       alpha: alpha)
    }
}
