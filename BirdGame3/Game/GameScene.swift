//
//  GameScene-BirdBattle.swift
//  BirdGame3
//
//  Full GameScene implementation for bird battles (cleaned, fixed, and ready to compile).
//
//  Notes:
//  - Arena setup helpers are declared internal so calls from setupScene() compile.
//  - Ability handling captures receiveDamage() return values and updates totals.
//  - Crow ability stun logic and hummingbird multi-hit logic are separated correctly.
//  - Replace or integrate with your existing BirdCharacter, BirdType, TrashTalkGenerator, etc.
//

import SpriteKit
import SwiftUI
import UIKit

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
    
    // MARK: - Delegate
    weak var gameDelegate: GameSceneDelegate?
    
    // MARK: - Scene entities / types (expected elsewhere in project)
    var playerBird: BirdCharacter!
    var opponentBird: BirdCharacter!
    var playerType: BirdType = .pigeon
    var opponentType: BirdType = .eagle
    var isTrainingMode: Bool = false
    var selectedArena: BattleArena = .birdDome
    
    // MARK: - State / metrics
    private var lastUpdateTime: TimeInterval = 0
    private var battleStartTime: TimeInterval = 0
    private var totalDamageDealt: Double = 0
    private var totalDamageReceived: Double = 0
    private var battleStarted: Bool = false
    
    // MARK: - AI helpers
    private var aiThinkTimer: TimeInterval = 0
    private var aiActionCooldown: TimeInterval = 0
    private var aiStunned: Bool = false
    private var aiStunTimer: TimeInterval = 0
    
    // MARK: - Player input
    private var touchStartLocation: CGPoint?
    private var isPlayerBlocking: Bool = false
    
    // MARK: - UI
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
    
    // MARK: - Physics categories
    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let player: UInt32 = 0b1
        static let opponent: UInt32 = 0b10
        static let attack: UInt32 = 0b100
    }
    
    // MARK: - Lifecycle
    
    override func didMove(to view: SKView) {
        setupScene()
        setupBirds()
        setupUI()
        startBattleCountdown()
    }
    
    // MARK: - Scene setup
    
    private func setupScene() {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -5)
        
        // Arena-specific background
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
        
        // Ground
        let groundColor = selectedArena == .bowlingAlley
            ? SKColor(red: 0.87, green: 0.72, blue: 0.53, alpha: 1.0) // wood
            : SKColor(red: 0.2, green: 0.3, blue: 0.2, alpha: 1.0)   // grass
        let ground = SKSpriteNode(color: groundColor, size: CGSize(width: size.width, height: 100))
        ground.position = CGPoint(x: size.width / 2, y: 50)
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.friction = 0.8
        addChild(ground)
        
        addBackgroundElements()
    }
    
    private func addBackgroundImage() {
        let backgroundName = "arena_background"
        if let _ = UIImage(named: backgroundName) {
            let backgroundSprite = SKSpriteNode(imageNamed: backgroundName)
            backgroundSprite.position = CGPoint(x: size.width / 2, y: size.height / 2)
            backgroundSprite.size = size
            backgroundSprite.zPosition = -10
            addChild(backgroundSprite)
        }
    }
    
    private func addBackgroundElements() {
        // Soft clouds / decorative nodes
        for i in 0..<5 {
            let cloud = SKShapeNode(rectOf: CGSize(width: CGFloat.random(in: 60...120),
                                                   height: CGFloat.random(in: 20...40)),
                                    cornerRadius: 15)
            cloud.fillColor = SKColor.white.withAlphaComponent(0.06)
            cloud.strokeColor = .clear
            cloud.position = CGPoint(x: CGFloat.random(in: 0...size.width),
                                     y: size.height - CGFloat(i * 50) - 100)
            cloud.zPosition = -95
            addChild(cloud)
            
            let moveRight = SKAction.moveBy(x: 100, y: 0, duration: Double.random(in: 10...20))
            let moveLeft = SKAction.moveBy(x: -100, y: 0, duration: Double.random(in: 10...20))
            let cloudMove = SKAction.sequence([moveRight, moveLeft])
            cloud.run(SKAction.repeatForever(cloudMove))
        }
        
        let arenaLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        arenaLabel.text = "\(selectedArena.emoji) \(selectedArena.rawValue.uppercased()) \(selectedArena.emoji)"
        arenaLabel.fontSize = 14
        arenaLabel.fontColor = .white.withAlphaComponent(0.5)
        arenaLabel.position = CGPoint(x: size.width / 2, y: size.height - 30)
        addChild(arenaLabel)
    }
    
    // MARK: - Entities
    
    private func setupBirds() {
        playerBird = BirdCharacter(type: playerType, isPlayer: true)
        playerBird.position = CGPoint(x: size.width * 0.25, y: 150)
        playerBird.physicsBody?.categoryBitMask = PhysicsCategory.player
        addChild(playerBird)
        
        opponentBird = BirdCharacter(type: opponentType, isPlayer: false)
        opponentBird.position = CGPoint(x: size.width * 0.75, y: 150)
        opponentBird.xScale = -1
        opponentBird.physicsBody?.categoryBitMask = PhysicsCategory.opponent
        addChild(opponentBird)
    }
    
    // MARK: - UI
    
    private func setupUI() {
        let healthBarWidth: CGFloat = 150
        let healthBarHeight: CGFloat = 20
        
        playerHealthBar = SKShapeNode(rectOf: CGSize(width: healthBarWidth, height: healthBarHeight), cornerRadius: 5)
        playerHealthBar.fillColor = .darkGray
        playerHealthBar.strokeColor = .white
        playerHealthBar.lineWidth = 2
        playerHealthBar.position = CGPoint(x: 100, y: size.height - 80)
        addChild(playerHealthBar)
        
        playerHealthFill = SKShapeNode(rectOf: CGSize(width: healthBarWidth - 4, height: healthBarHeight - 4), cornerRadius: 3)
        playerHealthFill.fillColor = .green
        playerHealthFill.strokeColor = .clear
        playerHealthFill.position = playerHealthBar.position
        addChild(playerHealthFill)
        
        playerNameLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        playerNameLabel.text = "\(playerType.emoji) \(playerType.displayName) (YOU)"
        playerNameLabel.fontSize = 16
        playerNameLabel.fontColor = .white
        playerNameLabel.position = CGPoint(x: 100, y: size.height - 55)
        addChild(playerNameLabel)
        
        playerAbilityNode = SKShapeNode(circleOfRadius: 15)
        playerAbilityNode.fillColor = .yellow
        playerAbilityNode.strokeColor = .orange
        playerAbilityNode.lineWidth = 2
        playerAbilityNode.position = CGPoint(x: 190, y: size.height - 80)
        addChild(playerAbilityNode)
        
        opponentHealthBar = SKShapeNode(rectOf: CGSize(width: healthBarWidth, height: healthBarHeight), cornerRadius: 5)
        opponentHealthBar.fillColor = .darkGray
        opponentHealthBar.strokeColor = .white
        opponentHealthBar.lineWidth = 2
        opponentHealthBar.position = CGPoint(x: size.width - 100, y: size.height - 80)
        addChild(opponentHealthBar)
        
        opponentHealthFill = SKShapeNode(rectOf: CGSize(width: healthBarWidth - 4, height: healthBarHeight - 4), cornerRadius: 3)
        opponentHealthFill.fillColor = .red
        opponentHealthFill.strokeColor = .clear
        opponentHealthFill.position = opponentHealthBar.position
        addChild(opponentHealthFill)
        
        opponentNameLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        opponentNameLabel.text = "\(opponentType.emoji) \(opponentType.displayName) (CPU)"
        opponentNameLabel.fontSize = 16
        opponentNameLabel.fontColor = .white
        opponentNameLabel.position = CGPoint(x: size.width - 100, y: size.height - 55)
        addChild(opponentNameLabel)
        
        opponentAbilityNode = SKShapeNode(circleOfRadius: 15)
        opponentAbilityNode.fillColor = .yellow
        opponentAbilityNode.strokeColor = .orange
        opponentAbilityNode.lineWidth = 2
        opponentAbilityNode.position = CGPoint(x: size.width - 190, y: size.height - 80)
        addChild(opponentAbilityNode)
        
        countdownLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        countdownLabel.fontSize = 72
        countdownLabel.fontColor = .white
        countdownLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(countdownLabel)
        
        trashTalkLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        trashTalkLabel.fontSize = 18
        trashTalkLabel.fontColor = .yellow
        trashTalkLabel.position = CGPoint(x: size.width / 2, y: size.height - 120)
        trashTalkLabel.alpha = 0
        addChild(trashTalkLabel)
    }
    
    // MARK: - Countdown
    
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
        
        playerBird.update(deltaTime: deltaTime)
        opponentBird.update(deltaTime: deltaTime)
        
        if !isTrainingMode {
            updateAI(deltaTime: deltaTime)
        }
        
        updateHealthBars()
        updateAbilityIndicators()
        checkBattleEnd()
    }
    
    private func updateAI(deltaTime: TimeInterval) {
        if aiStunned {
            aiStunTimer -= deltaTime
            if aiStunTimer <= 0 { aiStunned = false }
            return
        }
        
        aiThinkTimer += deltaTime
        aiActionCooldown -= deltaTime
        
        let thinkInterval = Double.random(in: 0.3...0.8)
        if aiThinkTimer >= thinkInterval && aiActionCooldown <= 0 {
            aiThinkTimer = 0
            performAIAction()
        }
    }
    
    private func performAIAction() {
        let distance = abs(playerBird.position.x - opponentBird.position.x)
        let decision = Int.random(in: 0...100)
        
        if distance > 200 {
            moveOpponent(towards: playerBird.position)
            aiActionCooldown = 0.2
        } else if distance < 150 {
            if decision < 50 {
                opponentAttack()
                aiActionCooldown = 0.5
            } else if decision < 70 && opponentBird.isAbilityReady {
                opponentUseAbility()
                aiActionCooldown = 1.0
            } else if decision < 85 {
                opponentBird.startBlocking()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.opponentBird.stopBlocking()
                }
                aiActionCooldown = 0.6
            } else {
                let moveDirection: CGFloat = Bool.random() ? -50 : 50
                opponentBird.move(by: CGVector(dx: moveDirection, dy: 0))
                aiActionCooldown = 0.3
            }
        } else {
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
    
    // MARK: - Attacks & Abilities (fixed to use returned damage)
    
    private func opponentAttack() {
        let damage = opponentBird.performAttack()
        let distance = abs(playerBird.position.x - opponentBird.position.x)
        if distance < 120 {
            let actualDamage = playerBird.receiveDamage(damage)
            totalDamageReceived += actualDamage
            showDamageNumber(actualDamage, at: playerBird.position, isPlayer: true)
        }
    }
    
    private func opponentUseAbility() {
        let damage = opponentBird.useAbility()
        let distance = abs(playerBird.position.x - opponentBird.position.x)
        
        switch opponentBird.birdType {
        case .hummingbird:
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
            if distance < 150 {
                let actualDamage = playerBird.receiveDamage(damage)
                totalDamageReceived += actualDamage
                showDamageNumber(actualDamage, at: playerBird.position, isPlayer: true)
                
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
    
    func playerAttack() {
        let damage = playerBird.performAttack()
        let distance = abs(playerBird.position.x - opponentBird.position.x)
        if distance < 120 {
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
            if distance < 150 {
                let actualDamage = opponentBird.receiveDamage(damage)
                totalDamageDealt += actualDamage
                showDamageNumber(actualDamage, at: opponentBird.position, isPlayer: false)
                
                aiStunned = true
                aiStunTimer = 1.5
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
    
    // MARK: - UI updates
    
    private func updateHealthBars() {
        let playerHealthPercent = playerBird.currentHealth / playerBird.maxHealth
        let opponentHealthPercent = opponentBird.currentHealth / opponentBird.maxHealth
        
        playerHealthFill.xScale = CGFloat(max(0, playerHealthPercent))
        opponentHealthFill.xScale = CGFloat(max(0, opponentHealthPercent))
        
        if playerHealthPercent < 0.3 {
            playerHealthFill.fillColor = .red
        } else if playerHealthPercent < 0.6 {
            playerHealthFill.fillColor = .yellow
        } else {
            playerHealthFill.fillColor = .green
        }
        
        if opponentHealthPercent < 0.3 {
            opponentHealthFill.fillColor = .green
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
        
        let resultLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        resultLabel.text = playerWon ? "🎉 VICTORY! 🎉" : "💀 DEFEAT 💀"
        resultLabel.fontSize = 48
        resultLabel.fontColor = playerWon ? .green : .red
        resultLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        resultLabel.setScale(0)
        addChild(resultLabel)
        
        let appear = SKAction.sequence([SKAction.scale(to: 1.2, duration: 0.3), SKAction.scale(to: 1.0, duration: 0.1)])
        resultLabel.run(appear)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            let duration = CACurrentMediaTime() - self.battleStartTime
            self.gameDelegate?.battleDidEnd(playerWon: playerWon, duration: duration, damageDealt: self.totalDamageDealt, damageReceived: self.totalDamageReceived)
        }
    }
    
    // MARK: - Visual helpers
    
    private func showDamageNumber(_ damage: Double, at position: CGPoint, isPlayer: Bool) {
        let damageLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        damageLabel.text = "-\(Int(damage))"
        damageLabel.fontSize = 24
        damageLabel.fontColor = isPlayer ? .red : .green
        damageLabel.position = CGPoint(x: position.x + CGFloat.random(in: -20...20), y: position.y + 50)
        addChild(damageLabel)
        
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        damageLabel.run(SKAction.sequence([SKAction.group([moveUp, fadeOut]), SKAction.removeFromParent()]))
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
        abilityLabel.run(SKAction.sequence([appear, wait, disappear, SKAction.removeFromParent()]))
    }
    
    private func showRandomTrashTalk() {
        let message = TrashTalkGenerator.getRandomMessage()
        trashTalkLabel.text = message
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let wait = SKAction.wait(forDuration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let next = SKAction.run { [weak self] in
            guard let self = self, self.battleStarted else { return }
            self.showRandomTrashTalk()
        }
        trashTalkLabel.run(SKAction.sequence([fadeIn, wait, fadeOut, next]))
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard battleStarted, let touch = touches.first else { return }
        let location = touch.location(in: self)
        touchStartLocation = location
        
        if location.x > size.width * 0.7 {
            playerBird.startBlocking()
            isPlayerBlocking = true
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard battleStarted, let touch = touches.first else { return }
        let location = touch.location(in: self)
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
        
        if let startLocation = touchStartLocation {
            let deltaX = abs(location.x - startLocation.x)
            let deltaY = abs(location.y - startLocation.y)
            if deltaX < 30 && deltaY < 30 {
                if location.y > size.height * 0.6 {
                    playerUseAbility()
                } else {
                    playerAttack()
                }
            }
        }
        
        touchStartLocation = nil
    }
    
    // MARK: - Public control wrappers (for GameView/GameController)
    /// Move the player horizontally by a normalized amount.
    /// Positive moves right, negative moves left. Values are scaled by bird speed.
    func movePlayer(byHorizontalAmount amount: CGFloat) {
        let moveSpeed: CGFloat = CGFloat(playerBird.birdType.baseStats.speed) * amount
        playerBird.move(by: CGVector(dx: moveSpeed, dy: 0))
    }

    /// Start/stop player blocking state.
    func setPlayerBlocking(_ blocking: Bool) {
        if blocking {
            playerBird.startBlocking()
        } else {
            playerBird.stopBlocking()
        }
    }
    
    // MARK: - Arena setup helpers
    
    func setupBirdDomeArena() {
        removeArenaBackgroundIfAny()
        let bg = SKSpriteNode(color: UIColor.systemTeal.withAlphaComponent(0.9), size: size)
        bg.name = "arenaBackground"
        bg.zPosition = -100
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(bg)
        
        let spotlight = SKShapeNode(circleOfRadius: max(size.width, size.height) * 0.8)
        spotlight.fillColor = UIColor.white.withAlphaComponent(0.05)
        spotlight.strokeColor = .clear
        spotlight.zPosition = -90
        spotlight.position = bg.position
        spotlight.name = "arenaSpotlight"
        addChild(spotlight)
    }
    
    func setupBowlingAlleyArena() {
        removeArenaBackgroundIfAny()
        let bg = SKSpriteNode(color: .black, size: size)
        bg.name = "arenaBackground"
        bg.zPosition = -100
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(bg)
        
        let stripe = SKSpriteNode(color: UIColor.systemPink, size: CGSize(width: size.width, height: 24))
        stripe.position = CGPoint(x: size.width / 2, y: size.height * 0.75)
        stripe.alpha = 0.85
        stripe.zPosition = -90
        stripe.name = "arenaNeonStripe"
        addChild(stripe)
        
        let floor = SKSpriteNode(color: UIColor(white: 0.07, alpha: 1.0), size: CGSize(width: size.width, height: size.height * 0.25))
        floor.position = CGPoint(x: size.width / 2, y: size.height * 0.15)
        floor.zPosition = -80
        floor.name = "arenaFloor"
        addChild(floor)
    }
    
    func setupSkyTempleArena() {
        removeArenaBackgroundIfAny()
        let bg = SKSpriteNode(color: UIColor.systemBlue, size: size)
        bg.name = "arenaBackground"
        bg.zPosition = -100
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(bg)
        
        for i in 0..<3 {
            let cloud = SKShapeNode(ellipseOf: CGSize(width: size.width * 0.5, height: size.height * 0.15))
            cloud.fillColor = UIColor.white.withAlphaComponent(0.35 - CGFloat(i) * 0.08)
            cloud.strokeColor = .clear
            cloud.zPosition = -90 + CGFloat(i)
            cloud.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: CGFloat(size.height * (0.6 + Double(i) * 0.1)))
            cloud.name = "arenaCloud\(i)"
            addChild(cloud)
            
            let move = SKAction.sequence([
                SKAction.moveBy(x: CGFloat.random(in: -40...40), y: 0, duration: TimeInterval(4 + i)),
                SKAction.moveBy(x: CGFloat.random(in: -40...40), y: 0, duration: TimeInterval(4 + i))
            ])
            cloud.run(SKAction.repeatForever(move))
        }
    }
    
    func setupAncientTreeArena() {
        removeArenaBackgroundIfAny()
        let bg = SKSpriteNode(color: UIColor.systemGreen.withAlphaComponent(0.95), size: size)
        bg.name = "arenaBackground"
        bg.zPosition = -100
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(bg)
        
        let trunk = SKSpriteNode(color: UIColor.brown.withAlphaComponent(0.9),
                                 size: CGSize(width: size.width * 0.4, height: size.height * 1.1))
        trunk.position = CGPoint(x: size.width * 0.15, y: size.height / 2)
        trunk.zPosition = -90
        trunk.name = "arenaTrunk"
        addChild(trunk)
        
        let canopy = SKShapeNode(rectOf: CGSize(width: size.width * 0.9, height: size.height * 0.35), cornerRadius: 20)
        canopy.fillColor = UIColor.systemGreen.withAlphaComponent(0.6)
        canopy.strokeColor = .clear
        canopy.position = CGPoint(x: size.width / 2, y: size.height * 0.78)
        canopy.zPosition = -85
        canopy.name = "arenaCanopy"
        addChild(canopy)
    }
    
    func removeArenaBackgroundIfAny() {
        let namesToRemove = ["arenaBackground", "arenaSpotlight", "arenaNeonStripe", "arenaFloor",
                             "arenaCloud0", "arenaCloud1", "arenaCloud2", "arenaTrunk", "arenaCanopy"]
        for name in namesToRemove {
            self.childNode(withName: name)?.removeFromParent()
        }
    }
}

// MARK: - Protocol

protocol GameSceneDelegate: AnyObject {
    func battleDidEnd(playerWon: Bool, duration: TimeInterval, damageDealt: Double, damageReceived: Double)
}

