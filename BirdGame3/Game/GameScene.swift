//
//  GameScene.swift
//  BirdGame3
//
//  Where the epic bird battles unfold
//
//  Map Assets (Royalty-Free):
//  - Bowling Alley: See BowlingAlleyScene.swift for neon arcade map
//  - Backgrounds: https://kenney.nl/assets, https://opengameart.org
//  - See ASSETS_README.md for complete asset guide
//

import SpriteKit
import SwiftUI

/// Available battle arena maps
enum BattleArena: String, CaseIterable {
    case birdDome = "Bird Dome Arena"
    case bowlingAlley = "Bird Bowl Alley"
    case skyTemple = "Sky Temple"
    case ancientTree = "Ancient Tree"
    
    var emoji: String {
        switch self {
        case .birdDome: return "🏟️"
        case .bowlingAlley: return "🎳"
        case .skyTemple: return "⛩️"
        case .ancientTree: return "🌳"
        }
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Properties
    weak var gameDelegate: GameSceneDelegate?
    
    var playerBird: BirdCharacter!
    var opponentBird: BirdCharacter!
    var playerType: BirdType = .pigeon
    var opponentType: BirdType = .eagle
    var isTrainingMode: Bool = false
    var selectedArena: BattleArena = .birdDome
    
    private var lastUpdateTime: TimeInterval = 0
    private var battleStartTime: TimeInterval = 0
    private var totalDamageDealt: Double = 0
    private var totalDamageReceived: Double = 0
    
    // AI properties
    private var aiThinkTimer: TimeInterval = 0
    private var aiActionCooldown: TimeInterval = 0
    private var aiStunned: Bool = false
    private var aiStunTimer: TimeInterval = 0
    
    // Player input
    private var touchStartLocation: CGPoint?
    private var isPlayerBlocking: Bool = false
    
    // UI Elements
    private var playerHealthBar: SKShapeNode!
    private var opponentHealthBar: SKShapeNode!
    private var playerHealthFill: SKShapeNode!
    private var opponentHealthFill: SKShapeNode!
    private var playerAbilityNode: SKShapeNode!
    private var opponentAbilityNode: SKShapeNode!
    private var playerNameLabel: SKLabelNode!
    private var opponentNameLabel: SKLabelNode!
    private var countdownLabel: SKLabelNode!
    private var trashTalkLabel: SKLabelNode!
    
    private var battleStarted: Bool = false
    
    // Physics categories
    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let player: UInt32 = 0b1
        static let opponent: UInt32 = 0b10
        static let attack: UInt32 = 0b100
    }
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        setupScene()
        setupBirds()
        setupUI()
        startBattleCountdown()
    }
    
    private func setupScene() {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -5)
        
        // Setup arena-specific background
        switch selectedArena {
        case .birdDome:
            setupBirdDomeArena()
        case .bowlingAlley:
            setupBowlingAlleyArena()
        case .skyTemple:
            setupSkyTempleArena()
        case .ancientTree:
            setupAncientTreeArena()
        }
        
        // Add ground (common to all arenas)
        let groundColor = selectedArena == .bowlingAlley 
            ? SKColor(red: 0.87, green: 0.72, blue: 0.53, alpha: 1.0)  // Wood floor
            : SKColor(red: 0.2, green: 0.3, blue: 0.2, alpha: 1.0)    // Grass
        let ground = SKSpriteNode(color: groundColor, size: CGSize(width: size.width, height: 100))
        ground.position = CGPoint(x: size.width / 2, y: 50)
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.friction = 0.8
        addChild(ground)
        
        // Add some background elements
        addBackgroundElements()
    }
    
    private func setupBirdDomeArena() {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
    }
    
    private func setupBowlingAlleyArena() {
        // Neon arcade vibes
        backgroundColor = SKColor(red: 0.18, green: 0.11, blue: 0.31, alpha: 1.0)
        
        // Add neon glow effects
        let neonPink = SKColor(red: 1.0, green: 0.08, blue: 0.58, alpha: 0.3)
        let neonBlue = SKColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 0.3)
        
        let leftGlow = SKShapeNode(rectOf: CGSize(width: size.width / 3, height: size.height))
        leftGlow.fillColor = neonPink
        leftGlow.strokeColor = .clear
        leftGlow.position = CGPoint(x: size.width / 6, y: size.height / 2)
        leftGlow.zPosition = -20
        addChild(leftGlow)
        
        let rightGlow = SKShapeNode(rectOf: CGSize(width: size.width / 3, height: size.height))
        rightGlow.fillColor = neonBlue
        rightGlow.strokeColor = .clear
        rightGlow.position = CGPoint(x: size.width * 5/6, y: size.height / 2)
        rightGlow.zPosition = -20
        addChild(rightGlow)
        
        // Add bowling pins in background
        addBowlingPinsBackground()
        
        // Play bowling alley music
        MusicManager.shared.playMusic(.bowlingAlley)
    }
    
    private func setupSkyTempleArena() {
        // Ethereal sky colors
        backgroundColor = SKColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0)
        
        // Add floating clouds
        for _ in 0..<8 {
            let cloud = SKShapeNode(ellipseOf: CGSize(width: CGFloat.random(in: 100...200), height: CGFloat.random(in: 40...80)))
            cloud.fillColor = .white
            cloud.strokeColor = .clear
            cloud.alpha = 0.7
            cloud.position = CGPoint(x: CGFloat.random(in: -100...size.width + 100), y: CGFloat.random(in: 0...size.height))
            cloud.zPosition = -15
            addChild(cloud)
        }
    }
    
    private func setupAncientTreeArena() {
        // Forest green tones
        backgroundColor = SKColor(red: 0.15, green: 0.25, blue: 0.15, alpha: 1.0)
        
        // Add tree trunk in center background
        let trunk = SKShapeNode(rectOf: CGSize(width: 80, height: size.height))
        trunk.fillColor = SKColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 0.5)
        trunk.strokeColor = .clear
        trunk.position = CGPoint(x: size.width / 2, y: size.height / 2)
        trunk.zPosition = -15
        addChild(trunk)
    }
    
    private func addBowlingPinsBackground() {
        // Decorative bowling pins
        let pinPositions: [CGPoint] = [
            CGPoint(x: size.width * 0.15, y: size.height * 0.7),
            CGPoint(x: size.width * 0.85, y: size.height * 0.7),
            CGPoint(x: size.width * 0.1, y: size.height * 0.5),
            CGPoint(x: size.width * 0.9, y: size.height * 0.5)
        ]
        
        for pos in pinPositions {
            let pin = SKShapeNode(ellipseOf: CGSize(width: 15, height: 30))
            pin.fillColor = .white
            pin.strokeColor = .lightGray
            pin.position = pos
            pin.zPosition = -10
            pin.alpha = 0.4
            addChild(pin)
        }
    }
    
    private func addBackgroundElements() {
        // Sky gradient effect
        for i in 0..<5 {
            let cloud = SKShapeNode(rectOf: CGSize(width: CGFloat.random(in: 60...120), height: CGFloat.random(in: 20...40)), cornerRadius: 15)
            cloud.fillColor = SKColor.white.withAlphaComponent(0.1)
            cloud.strokeColor = .clear
            cloud.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height - CGFloat(i * 50) - 100)
            addChild(cloud)
            
            // Animate clouds
            let moveRight = SKAction.moveBy(x: 100, y: 0, duration: Double.random(in: 10...20))
            let moveLeft = SKAction.moveBy(x: -100, y: 0, duration: Double.random(in: 10...20))
            let cloudMove = SKAction.sequence([moveRight, moveLeft])
            cloud.run(SKAction.repeatForever(cloudMove))
        }
        
        // Arena name (dynamic based on selected arena)
        let arenaLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        arenaLabel.text = "\(selectedArena.emoji) \(selectedArena.rawValue.uppercased()) \(selectedArena.emoji)"
        arenaLabel.fontSize = 14
        arenaLabel.fontColor = .white.withAlphaComponent(0.5)
        arenaLabel.position = CGPoint(x: size.width / 2, y: size.height - 30)
        addChild(arenaLabel)
    }
    
    private func setupBirds() {
        // Create player bird on the left
        playerBird = BirdCharacter(type: playerType, isPlayer: true)
        playerBird.position = CGPoint(x: size.width * 0.25, y: 150)
        playerBird.physicsBody?.categoryBitMask = PhysicsCategory.player
        addChild(playerBird)
        
        // Create opponent bird on the right
        opponentBird = BirdCharacter(type: opponentType, isPlayer: false)
        opponentBird.position = CGPoint(x: size.width * 0.75, y: 150)
        opponentBird.xScale = -1 // Face left
        opponentBird.physicsBody?.categoryBitMask = PhysicsCategory.opponent
        addChild(opponentBird)
    }
    
    private func setupUI() {
        // Player health bar background
        let healthBarWidth: CGFloat = 150
        let healthBarHeight: CGFloat = 20
        
        playerHealthBar = SKShapeNode(rectOf: CGSize(width: healthBarWidth, height: healthBarHeight), cornerRadius: 5)
        playerHealthBar.fillColor = SKColor.darkGray
        playerHealthBar.strokeColor = SKColor.white
        playerHealthBar.lineWidth = 2
        playerHealthBar.position = CGPoint(x: 100, y: size.height - 80)
        addChild(playerHealthBar)
        
        playerHealthFill = SKShapeNode(rectOf: CGSize(width: healthBarWidth - 4, height: healthBarHeight - 4), cornerRadius: 3)
        playerHealthFill.fillColor = SKColor.green
        playerHealthFill.strokeColor = .clear
        playerHealthFill.position = playerHealthBar.position
        addChild(playerHealthFill)
        
        playerNameLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        playerNameLabel.text = "\(playerType.emoji) \(playerType.displayName) (YOU)"
        playerNameLabel.fontSize = 16
        playerNameLabel.fontColor = .white
        playerNameLabel.position = CGPoint(x: 100, y: size.height - 55)
        addChild(playerNameLabel)
        
        // Player ability indicator
        playerAbilityNode = SKShapeNode(circleOfRadius: 15)
        playerAbilityNode.fillColor = SKColor.yellow
        playerAbilityNode.strokeColor = SKColor.orange
        playerAbilityNode.lineWidth = 2
        playerAbilityNode.position = CGPoint(x: 190, y: size.height - 80)
        addChild(playerAbilityNode)
        
        let playerAbilityLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        playerAbilityLabel.text = "Q"
        playerAbilityLabel.fontSize = 14
        playerAbilityLabel.fontColor = .black
        playerAbilityLabel.verticalAlignmentMode = .center
        playerAbilityLabel.position = playerAbilityNode.position
        addChild(playerAbilityLabel)
        
        // Opponent health bar
        opponentHealthBar = SKShapeNode(rectOf: CGSize(width: healthBarWidth, height: healthBarHeight), cornerRadius: 5)
        opponentHealthBar.fillColor = SKColor.darkGray
        opponentHealthBar.strokeColor = SKColor.white
        opponentHealthBar.lineWidth = 2
        opponentHealthBar.position = CGPoint(x: size.width - 100, y: size.height - 80)
        addChild(opponentHealthBar)
        
        opponentHealthFill = SKShapeNode(rectOf: CGSize(width: healthBarWidth - 4, height: healthBarHeight - 4), cornerRadius: 3)
        opponentHealthFill.fillColor = SKColor.red
        opponentHealthFill.strokeColor = .clear
        opponentHealthFill.position = opponentHealthBar.position
        addChild(opponentHealthFill)
        
        opponentNameLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        opponentNameLabel.text = "\(opponentType.emoji) \(opponentType.displayName) (CPU)"
        opponentNameLabel.fontSize = 16
        opponentNameLabel.fontColor = .white
        opponentNameLabel.position = CGPoint(x: size.width - 100, y: size.height - 55)
        addChild(opponentNameLabel)
        
        // Opponent ability indicator
        opponentAbilityNode = SKShapeNode(circleOfRadius: 15)
        opponentAbilityNode.fillColor = SKColor.yellow
        opponentAbilityNode.strokeColor = SKColor.orange
        opponentAbilityNode.lineWidth = 2
        opponentAbilityNode.position = CGPoint(x: size.width - 190, y: size.height - 80)
        addChild(opponentAbilityNode)
        
        // Countdown label
        countdownLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        countdownLabel.fontSize = 72
        countdownLabel.fontColor = .white
        countdownLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(countdownLabel)
        
        // Trash talk label
        trashTalkLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        trashTalkLabel.fontSize = 18
        trashTalkLabel.fontColor = SKColor.yellow
        trashTalkLabel.position = CGPoint(x: size.width / 2, y: size.height - 120)
        trashTalkLabel.alpha = 0
        addChild(trashTalkLabel)
    }
    
    private func startBattleCountdown() {
        countdownLabel.text = "3"
        countdownLabel.setScale(0.5)
        
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.3)
        let wait = SKAction.wait(forDuration: 0.7)
        
        let countdown = SKAction.sequence([
            scaleUp, wait,
            SKAction.run { [weak self] in self?.countdownLabel.text = "2"; self?.countdownLabel.setScale(0.5) },
            scaleUp, wait,
            SKAction.run { [weak self] in self?.countdownLabel.text = "1"; self?.countdownLabel.setScale(0.5) },
            scaleUp, wait,
            SKAction.run { [weak self] in 
                self?.countdownLabel.text = "FIGHT!"
                self?.countdownLabel.fontColor = .red
                self?.countdownLabel.setScale(0.5)
            },
            scaleUp,
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.run { [weak self] in
                self?.battleStarted = true
                self?.battleStartTime = CACurrentMediaTime()
                self?.showRandomTrashTalk()
            }
        ])
        
        countdownLabel.run(countdown)
    }
    
    // MARK: - Update Loop
    
    override func update(_ currentTime: TimeInterval) {
        guard battleStarted else { return }
        
        let deltaTime = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Update bird positions based on physics
        playerBird.update(deltaTime: deltaTime)
        opponentBird.update(deltaTime: deltaTime)
        
        // Update AI
        if !isTrainingMode {
            updateAI(deltaTime: deltaTime)
        }
        
        // Update UI
        updateHealthBars()
        updateAbilityIndicators()
        
        // Check win condition
        checkBattleEnd()
    }
    
    private func updateAI(deltaTime: TimeInterval) {
        // Handle stun
        if aiStunned {
            aiStunTimer -= deltaTime
            if aiStunTimer <= 0 {
                aiStunned = false
            }
            return
        }
        
        aiThinkTimer += deltaTime
        aiActionCooldown -= deltaTime
        
        // AI makes decisions every 0.3-0.8 seconds
        let thinkInterval = Double.random(in: 0.3...0.8)
        if aiThinkTimer >= thinkInterval && aiActionCooldown <= 0 {
            aiThinkTimer = 0
            performAIAction()
        }
    }
    
    private func performAIAction() {
        let distance = abs(playerBird.position.x - opponentBird.position.x)
        let decision = Int.random(in: 0...100)
        
        // Move towards player if far away
        if distance > 200 {
            moveOpponent(towards: playerBird.position)
            aiActionCooldown = 0.2
        }
        // In attack range
        else if distance < 150 {
            if decision < 50 {
                // Attack
                opponentAttack()
                aiActionCooldown = 0.5
            } else if decision < 70 && opponentBird.isAbilityReady {
                // Use ability
                opponentUseAbility()
                aiActionCooldown = 1.0
            } else if decision < 85 {
                // Block
                opponentBird.startBlocking()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.opponentBird.stopBlocking()
                }
                aiActionCooldown = 0.6
            } else {
                // Move/reposition
                let moveDirection: CGFloat = Bool.random() ? -50 : 50
                opponentBird.move(by: CGVector(dx: moveDirection, dy: 0))
                aiActionCooldown = 0.3
            }
        }
        // Medium range - approach
        else {
            if decision < 70 {
                moveOpponent(towards: playerBird.position)
            } else {
                opponentAttack()
            }
            aiActionCooldown = 0.3
        }
    }
    
    private func moveOpponent(towards position: CGPoint) {
        let direction: CGFloat = position.x < opponentBird.position.x ? -1 : 1
        let moveSpeed: CGFloat = CGFloat(opponentBird.birdType.baseStats.speed) * 3
        opponentBird.move(by: CGVector(dx: direction * moveSpeed, dy: 0))
    }
    
    private func opponentAttack() {
        let damage = opponentBird.performAttack()
        let distance = abs(playerBird.position.x - opponentBird.position.x)
        
        if distance < 120 { // Attack range
            let actualDamage = playerBird.receiveDamage(damage)
            totalDamageReceived += actualDamage
            showDamageNumber(actualDamage, at: playerBird.position, isPlayer: true)
        }
    }
    
    private func opponentUseAbility() {
        let damage = opponentBird.useAbility()
        let distance = abs(playerBird.position.x - opponentBird.position.x)
        
        // Different abilities have different ranges/effects
        switch opponentBird.birdType {
        case .hummingbird:
            // Multi-hit
            if distance < 100 {
                for i in 0..<5 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) { [weak self] in
                        guard let self = self else { return }
                        let hitDamage = self.playerBird.receiveDamage(damage)
                        self.totalDamageReceived += hitDamage
                        self.showDamageNumber(hitDamage, at: self.playerBird.position, isPlayer: true)
                    }
                }
            }
        case .crow:
            // Stun player briefly (reverse the effect - AI stuns player, not the other way)
            if distance < 150 {
                playerBird.receiveDamage(damage)
                // Visual stun effect on player
                let flash = SKAction.sequence([
                    SKAction.colorize(with: .yellow, colorBlendFactor: 0.7, duration: 0.1),
                    SKAction.colorize(withColorBlendFactor: 0, duration: 0.1)
                ])
                playerBird.run(SKAction.repeat(flash, count: 3))
            }
        default:
            if distance < 150 {
                let actualDamage = playerBird.receiveDamage(damage)
                totalDamageReceived += actualDamage
                showDamageNumber(actualDamage, at: playerBird.position, isPlayer: true)
            }
        }
        
        showAbilityText(opponentBird.birdType.abilityName, isPlayer: false)
    }
    
    private func updateHealthBars() {
        // Resize health fill based on current health
        let playerHealthPercent = playerBird.currentHealth / playerBird.maxHealth
        let opponentHealthPercent = opponentBird.currentHealth / opponentBird.maxHealth
        
        playerHealthFill.xScale = CGFloat(max(0, playerHealthPercent))
        opponentHealthFill.xScale = CGFloat(max(0, opponentHealthPercent))
        
        // Change color based on health
        if playerHealthPercent < 0.3 {
            playerHealthFill.fillColor = .red
        } else if playerHealthPercent < 0.6 {
            playerHealthFill.fillColor = .yellow
        } else {
            playerHealthFill.fillColor = .green
        }
        
        if opponentHealthPercent < 0.3 {
            opponentHealthFill.fillColor = .green // Reversed for opponent - low is good for us
        } else if opponentHealthPercent < 0.6 {
            opponentHealthFill.fillColor = .yellow
        } else {
            opponentHealthFill.fillColor = .red
        }
    }
    
    private func updateAbilityIndicators() {
        playerAbilityNode.fillColor = playerBird.isAbilityReady ? .yellow : .gray
        opponentAbilityNode.fillColor = opponentBird.isAbilityReady ? .yellow : .gray
    }
    
    private func checkBattleEnd() {
        if playerBird.currentHealth <= 0 {
            battleEnded(playerWon: false)
        } else if opponentBird.currentHealth <= 0 {
            battleEnded(playerWon: true)
        }
    }
    
    private func battleEnded(playerWon: Bool) {
        battleStarted = false
        
        // Show end message
        let resultLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        resultLabel.text = playerWon ? "🎉 VICTORY! 🎉" : "💀 DEFEAT 💀"
        resultLabel.fontSize = 48
        resultLabel.fontColor = playerWon ? .green : .red
        resultLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        resultLabel.setScale(0)
        addChild(resultLabel)
        
        let appear = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        resultLabel.run(appear)
        
        // Notify delegate after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            let duration = CACurrentMediaTime() - self.battleStartTime
            self.gameDelegate?.battleDidEnd(
                playerWon: playerWon,
                duration: duration,
                damageDealt: self.totalDamageDealt,
                damageReceived: self.totalDamageReceived
            )
        }
    }
    
    // MARK: - Visual Effects
    
    private func showDamageNumber(_ damage: Double, at position: CGPoint, isPlayer: Bool) {
        let damageLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        damageLabel.text = "-\(Int(damage))"
        damageLabel.fontSize = 24
        damageLabel.fontColor = isPlayer ? .red : .green
        damageLabel.position = CGPoint(x: position.x + CGFloat.random(in: -20...20), y: position.y + 50)
        addChild(damageLabel)
        
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let group = SKAction.group([moveUp, fadeOut])
        let remove = SKAction.removeFromParent()
        
        damageLabel.run(SKAction.sequence([group, remove]))
    }
    
    private func showAbilityText(_ abilityName: String, isPlayer: Bool) {
        let abilityLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        abilityLabel.text = "✨ \(abilityName.uppercased()) ✨"
        abilityLabel.fontSize = 20
        abilityLabel.fontColor = .yellow
        abilityLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 100)
        abilityLabel.setScale(0)
        addChild(abilityLabel)
        
        let appear = SKAction.scale(to: 1.0, duration: 0.2)
        let wait = SKAction.wait(forDuration: 0.5)
        let disappear = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        
        abilityLabel.run(SKAction.sequence([appear, wait, disappear, remove]))
    }
    
    private func showRandomTrashTalk() {
        let message = TrashTalkGenerator.getRandomMessage()
        trashTalkLabel.text = message
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let wait = SKAction.wait(forDuration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let nextMessage = SKAction.run { [weak self] in
            guard let self = self, self.battleStarted else { return }
            self.showRandomTrashTalk()
        }
        
        trashTalkLabel.run(SKAction.sequence([fadeIn, wait, fadeOut, nextMessage]))
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard battleStarted, let touch = touches.first else { return }
        let location = touch.location(in: self)
        touchStartLocation = location
        
        // Check if tap is on right side (block)
        if location.x > size.width * 0.7 {
            playerBird.startBlocking()
            isPlayerBlocking = true
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard battleStarted, let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Swipe detection for movement
        if let startLocation = touchStartLocation {
            let deltaX = location.x - startLocation.x
            if abs(deltaX) > 20 {
                playerBird.move(by: CGVector(dx: deltaX * 0.5, dy: 0))
                touchStartLocation = location
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard battleStarted, let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if isPlayerBlocking {
            playerBird.stopBlocking()
            isPlayerBlocking = false
            return
        }
        
        // Tap detection for attacks
        if let startLocation = touchStartLocation {
            let deltaX = abs(location.x - startLocation.x)
            let deltaY = abs(location.y - startLocation.y)
            
            // Quick tap = attack
            if deltaX < 30 && deltaY < 30 {
                // Double tap for ability
                if location.y > size.height * 0.6 {
                    playerUseAbility()
                } else {
                    playerAttack()
                }
            }
        }
        
        touchStartLocation = nil
    }
    
    // MARK: - Player Actions
    
    func playerAttack() {
        let damage = playerBird.performAttack()
        let distance = abs(playerBird.position.x - opponentBird.position.x)
        
        if distance < 120 { // Attack range
            let actualDamage = opponentBird.receiveDamage(damage)
            totalDamageDealt += actualDamage
            showDamageNumber(actualDamage, at: opponentBird.position, isPlayer: false)
        }
    }
    
    func playerUseAbility() {
        guard playerBird.isAbilityReady else { return }
        
        let damage = playerBird.useAbility()
        let distance = abs(playerBird.position.x - opponentBird.position.x)
        
        switch playerBird.birdType {
        case .hummingbird:
            // Multi-hit
            if distance < 100 {
                for i in 0..<5 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) { [weak self] in
                        guard let self = self else { return }
                        let hitDamage = self.opponentBird.receiveDamage(damage)
                        self.totalDamageDealt += hitDamage
                        self.showDamageNumber(hitDamage, at: self.opponentBird.position, isPlayer: false)
                    }
                }
            }
        case .crow:
            // Stun opponent
            if distance < 150 {
                opponentBird.receiveDamage(damage)
                aiStunned = true
                aiStunTimer = 1.5
                // Visual stun effect
                let flash = SKAction.sequence([
                    SKAction.colorize(with: .yellow, colorBlendFactor: 0.7, duration: 0.1),
                    SKAction.colorize(withColorBlendFactor: 0, duration: 0.1)
                ])
                opponentBird.run(SKAction.repeat(flash, count: 5))
            }
        default:
            if distance < 150 {
                let actualDamage = opponentBird.receiveDamage(damage)
                totalDamageDealt += actualDamage
                showDamageNumber(actualDamage, at: opponentBird.position, isPlayer: false)
            }
        }
        
        showAbilityText(playerBird.birdType.abilityName, isPlayer: true)
    }
    
    func movePlayer(direction: CGFloat) {
        let moveSpeed: CGFloat = CGFloat(playerBird.birdType.baseStats.speed) * 5
        playerBird.move(by: CGVector(dx: direction * moveSpeed, dy: 0))
    }
    
    func playerBlock(_ blocking: Bool) {
        if blocking {
            playerBird.startBlocking()
        } else {
            playerBird.stopBlocking()
        }
    }
}

// MARK: - Protocol

protocol GameSceneDelegate: AnyObject {
    func battleDidEnd(playerWon: Bool, duration: TimeInterval, damageDealt: Double, damageReceived: Double)
}
