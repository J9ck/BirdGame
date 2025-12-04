//
//  BowlingAlleyScene.swift
//  BirdGame3
//
//  A fun, vivid bowling alley map with neon details and arcade vibes!
//  Easter egg location for Crow players - "Strike!"
//

import SpriteKit
import SwiftUI

class BowlingAlleyScene: SKScene {
    
    // MARK: - Properties
    
    private var neonSigns: [SKNode] = []
    private var bowlingPins: [SKSpriteNode] = []
    private var discoBall: SKSpriteNode!
    private var arcadeMachines: [SKSpriteNode] = []
    private var lane: SKSpriteNode!
    
    // Environment state
    private var pinsKnockedDown: Int = 0
    private var showingStrikeText: Bool = false
    
    // Colors for neon effects
    private let neonPink = SKColor(red: 1.0, green: 0.08, blue: 0.58, alpha: 1.0)
    private let neonBlue = SKColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 1.0)
    private let neonGreen = SKColor(red: 0.22, green: 1.0, blue: 0.08, alpha: 1.0)
    private let woodBrown = SKColor(red: 0.87, green: 0.72, blue: 0.53, alpha: 1.0)
    private let darkPurple = SKColor(red: 0.18, green: 0.11, blue: 0.31, alpha: 1.0)
    
    // MARK: - Scene Setup
    
    override func didMove(to view: SKView) {
        setupBackground()
        setupBowlingLanes()
        setupBowlingPins()
        setupNeonSigns()
        setupDiscoBall()
        setupArcadeMachines()
        setupAmbientLighting()
        startNeonAnimations()
    }
    
    // MARK: - Background Setup
    
    private func setupBackground() {
        // Dark purple ambient background
        backgroundColor = darkPurple
        
        // Floor - polished bowling alley wood
        let floor = SKSpriteNode(color: woodBrown, size: CGSize(width: size.width, height: size.height * 0.4))
        floor.position = CGPoint(x: size.width / 2, y: size.height * 0.2)
        floor.zPosition = -10
        addChild(floor)
        
        // Add wood grain effect
        addWoodGrainEffect(to: floor)
        
        // Back wall
        let backWall = SKSpriteNode(color: SKColor(red: 0.15, green: 0.1, blue: 0.2, alpha: 1.0), size: CGSize(width: size.width, height: size.height * 0.6))
        backWall.position = CGPoint(x: size.width / 2, y: size.height * 0.7)
        backWall.zPosition = -15
        addChild(backWall)
    }
    
    private func addWoodGrainEffect(to node: SKSpriteNode) {
        // Add subtle wood grain lines
        for i in 0..<20 {
            let line = SKShapeNode(rectOf: CGSize(width: node.size.width, height: 2))
            line.fillColor = woodBrown.darker()
            line.strokeColor = .clear
            line.alpha = 0.3
            line.position = CGPoint(x: 0, y: CGFloat(i) * 15 - node.size.height / 2 + 10)
            node.addChild(line)
        }
    }
    
    // MARK: - Bowling Lane Setup
    
    private func setupBowlingLanes() {
        // Main bowling lane
        let laneWidth: CGFloat = size.width * 0.3
        let laneHeight: CGFloat = size.height * 0.6
        
        lane = SKSpriteNode(color: SKColor(red: 0.96, green: 0.87, blue: 0.7, alpha: 1.0), size: CGSize(width: laneWidth, height: laneHeight))
        lane.position = CGPoint(x: size.width / 2, y: size.height * 0.35)
        lane.zPosition = -5
        addChild(lane)
        
        // Lane markings
        addLaneMarkings(to: lane)
        
        // Gutters (darker edges)
        let gutterWidth: CGFloat = 20
        
        let leftGutter = SKSpriteNode(color: SKColor.darkGray, size: CGSize(width: gutterWidth, height: laneHeight))
        leftGutter.position = CGPoint(x: lane.position.x - laneWidth / 2 - gutterWidth / 2, y: lane.position.y)
        leftGutter.zPosition = -4
        addChild(leftGutter)
        
        let rightGutter = SKSpriteNode(color: SKColor.darkGray, size: CGSize(width: gutterWidth, height: laneHeight))
        rightGutter.position = CGPoint(x: lane.position.x + laneWidth / 2 + gutterWidth / 2, y: lane.position.y)
        rightGutter.zPosition = -4
        addChild(rightGutter)
        
        // Oil slick (environmental hazard)
        addOilSlick()
    }
    
    private func addLaneMarkings(to lane: SKSpriteNode) {
        // Arrow markers
        for i in 0..<7 {
            let arrow = createArrowMarker()
            arrow.position = CGPoint(x: CGFloat(i - 3) * 15, y: -lane.size.height / 4)
            lane.addChild(arrow)
        }
        
        // Foul line
        let foulLine = SKShapeNode(rectOf: CGSize(width: lane.size.width, height: 3))
        foulLine.fillColor = .red
        foulLine.strokeColor = .clear
        foulLine.position = CGPoint(x: 0, y: -lane.size.height / 2 + 20)
        lane.addChild(foulLine)
    }
    
    private func createArrowMarker() -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 10))
        path.addLine(to: CGPoint(x: -5, y: 0))
        path.addLine(to: CGPoint(x: 5, y: 0))
        path.closeSubpath()
        
        let arrow = SKShapeNode(path: path)
        arrow.fillColor = .darkGray
        arrow.strokeColor = .clear
        return arrow
    }
    
    private func addOilSlick() {
        // Shiny rainbow oil slick (environmental hazard)
        let oilSlick = SKShapeNode(ellipseOf: CGSize(width: 80, height: 30))
        oilSlick.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 0.5)
        oilSlick.strokeColor = .clear
        oilSlick.position = CGPoint(x: size.width / 2, y: size.height * 0.3)
        oilSlick.zPosition = -3
        oilSlick.name = "oilSlick"
        addChild(oilSlick)
        
        // Rainbow shimmer effect
        let shimmerColors: [SKColor] = [.red, .orange, .yellow, .green, .blue, .purple]
        let colorSequence = SKAction.sequence(shimmerColors.map { color in
            SKAction.colorize(with: color, colorBlendFactor: 0.3, duration: 0.3)
        })
        oilSlick.run(SKAction.repeatForever(colorSequence))
    }
    
    // MARK: - Bowling Pins Setup
    
    private func setupBowlingPins() {
        // Standard 10-pin triangle formation
        let pinPositions: [(x: CGFloat, y: CGFloat)] = [
            // Back row (4 pins)
            (-45, 0), (-15, 0), (15, 0), (45, 0),
            // Middle row (3 pins)
            (-30, -20), (0, -20), (30, -20),
            // Front row (2 pins)
            (-15, -40), (15, -40),
            // Point (1 pin)
            (0, -60)
        ]
        
        let basePosition = CGPoint(x: size.width / 2, y: size.height * 0.55)
        
        for (index, pos) in pinPositions.enumerated() {
            let pin = createBowlingPin()
            pin.position = CGPoint(x: basePosition.x + pos.x, y: basePosition.y + pos.y)
            pin.name = "pin_\(index)"
            pin.zPosition = 5
            addChild(pin)
            bowlingPins.append(pin)
        }
    }
    
    private func createBowlingPin() -> SKSpriteNode {
        // Create a bowling pin shape using multiple nodes
        let pinNode = SKSpriteNode()
        
        // Pin body (white with red stripes)
        let body = SKShapeNode(ellipseOf: CGSize(width: 12, height: 25))
        body.fillColor = .white
        body.strokeColor = SKColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        body.lineWidth = 1
        pinNode.addChild(body)
        
        // Red stripe
        let stripe1 = SKShapeNode(rectOf: CGSize(width: 12, height: 2))
        stripe1.fillColor = .red
        stripe1.strokeColor = .clear
        stripe1.position = CGPoint(x: 0, y: 5)
        pinNode.addChild(stripe1)
        
        let stripe2 = SKShapeNode(rectOf: CGSize(width: 12, height: 2))
        stripe2.fillColor = .red
        stripe2.strokeColor = .clear
        stripe2.position = CGPoint(x: 0, y: 8)
        pinNode.addChild(stripe2)
        
        // Pin neck (narrower top)
        let neck = SKShapeNode(ellipseOf: CGSize(width: 6, height: 8))
        neck.fillColor = .white
        neck.strokeColor = .clear
        neck.position = CGPoint(x: 0, y: 14)
        pinNode.addChild(neck)
        
        // Physics body for pin
        pinNode.physicsBody = SKPhysicsBody(circleOfRadius: 8)
        pinNode.physicsBody?.isDynamic = true
        pinNode.physicsBody?.friction = 0.5
        pinNode.physicsBody?.restitution = 0.3
        pinNode.physicsBody?.mass = 0.5
        pinNode.physicsBody?.categoryBitMask = 0b1000 // Pin category
        
        return pinNode
    }
    
    // MARK: - Neon Signs Setup
    
    private func setupNeonSigns() {
        // "STRIKE!" sign
        let strikeSign = createNeonSign(text: "STRIKE!", color: neonPink, fontSize: 36)
        strikeSign.position = CGPoint(x: size.width * 0.25, y: size.height * 0.85)
        strikeSign.alpha = 0.8
        addChild(strikeSign)
        neonSigns.append(strikeSign)
        
        // "BIRD BOWL" sign
        let birdBowlSign = createNeonSign(text: "🐦 BIRD BOWL 🎳", color: neonBlue, fontSize: 28)
        birdBowlSign.position = CGPoint(x: size.width / 2, y: size.height * 0.92)
        addChild(birdBowlSign)
        neonSigns.append(birdBowlSign)
        
        // "GAME ON!" sign
        let gameOnSign = createNeonSign(text: "GAME ON!", color: neonGreen, fontSize: 32)
        gameOnSign.position = CGPoint(x: size.width * 0.75, y: size.height * 0.85)
        gameOnSign.alpha = 0.8
        addChild(gameOnSign)
        neonSigns.append(gameOnSign)
        
        // Score display
        let scoreDisplay = createScoreDisplay()
        scoreDisplay.position = CGPoint(x: size.width / 2, y: size.height * 0.78)
        addChild(scoreDisplay)
    }
    
    private func createNeonSign(text: String, color: SKColor, fontSize: CGFloat) -> SKNode {
        let container = SKNode()
        
        // Glow effect (larger, blurred text behind)
        let glow = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        glow.text = text
        glow.fontSize = fontSize + 2
        glow.fontColor = color.withAlphaComponent(0.5)
        glow.zPosition = 0
        container.addChild(glow)
        
        // Main text
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = fontSize
        label.fontColor = color
        label.zPosition = 1
        container.addChild(label)
        
        // Add glow node effect
        let glowNode = SKEffectNode()
        glowNode.shouldRasterize = true
        glowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 8])
        
        let glowLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        glowLabel.text = text
        glowLabel.fontSize = fontSize
        glowLabel.fontColor = color
        glowNode.addChild(glowLabel)
        glowNode.alpha = 0.6
        glowNode.zPosition = -1
        container.addChild(glowNode)
        
        return container
    }
    
    private func createScoreDisplay() -> SKNode {
        let display = SKNode()
        
        // Background panel
        let panel = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 8)
        panel.fillColor = SKColor.black.withAlphaComponent(0.8)
        panel.strokeColor = neonBlue
        panel.lineWidth = 2
        display.addChild(panel)
        
        // Meme-worthy score text
        let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "SCORE: OVER 9000"
        scoreLabel.fontSize = 16
        scoreLabel.fontColor = neonGreen
        scoreLabel.position = CGPoint(x: 0, y: 8)
        display.addChild(scoreLabel)
        
        // Player name
        let nameLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        nameLabel.text = "xX_PigeonMaster_Xx"
        nameLabel.fontSize = 12
        nameLabel.fontColor = .white
        nameLabel.position = CGPoint(x: 0, y: -12)
        display.addChild(nameLabel)
        
        return display
    }
    
    // MARK: - Disco Ball Setup
    
    private func setupDiscoBall() {
        // Disco ball
        discoBall = SKSpriteNode(color: .gray, size: CGSize(width: 40, height: 40))
        discoBall.position = CGPoint(x: size.width / 2, y: size.height * 0.95)
        discoBall.zPosition = 20
        
        // Add sparkle effect
        let sparkleTexture = createSparkleTexture()
        discoBall.texture = sparkleTexture
        
        addChild(discoBall)
        
        // Rotating animation
        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 10)
        discoBall.run(SKAction.repeatForever(rotate))
        
        // Light rays from disco ball
        addDiscoLightRays()
    }
    
    private func createSparkleTexture() -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40))
        let image = renderer.image { ctx in
            // Base circle
            ctx.cgContext.setFillColor(UIColor.lightGray.cgColor)
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: 40, height: 40))
            
            // Sparkle dots
            ctx.cgContext.setFillColor(UIColor.white.cgColor)
            for _ in 0..<20 {
                let x = CGFloat.random(in: 5...35)
                let y = CGFloat.random(in: 5...35)
                ctx.cgContext.fillEllipse(in: CGRect(x: x, y: y, width: 3, height: 3))
            }
        }
        return SKTexture(image: image)
    }
    
    private func addDiscoLightRays() {
        let colors: [SKColor] = [neonPink, neonBlue, neonGreen, .yellow, .orange, .purple]
        
        for (index, color) in colors.enumerated() {
            let ray = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -size.height * 0.5))
            ray.path = path
            ray.strokeColor = color.withAlphaComponent(0.3)
            ray.lineWidth = 20
            ray.position = discoBall.position
            ray.zPosition = -1
            ray.zRotation = CGFloat(index) * .pi / 3
            addChild(ray)
            
            // Rotating animation
            let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 15)
            ray.run(SKAction.repeatForever(rotate))
        }
    }
    
    // MARK: - Arcade Machines Setup
    
    private func setupArcadeMachines() {
        // Left side arcade machines
        for i in 0..<2 {
            let machine = createArcadeMachine()
            machine.position = CGPoint(x: 60, y: size.height * 0.5 + CGFloat(i) * 100)
            addChild(machine)
            arcadeMachines.append(machine)
        }
        
        // Right side arcade machines
        for i in 0..<2 {
            let machine = createArcadeMachine()
            machine.position = CGPoint(x: size.width - 60, y: size.height * 0.5 + CGFloat(i) * 100)
            addChild(machine)
            arcadeMachines.append(machine)
        }
    }
    
    private func createArcadeMachine() -> SKSpriteNode {
        let machine = SKSpriteNode()
        
        // Cabinet body
        let cabinet = SKShapeNode(rectOf: CGSize(width: 50, height: 80), cornerRadius: 5)
        cabinet.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0)
        cabinet.strokeColor = SKColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1.0)
        cabinet.lineWidth = 2
        machine.addChild(cabinet)
        
        // Screen
        let screen = SKShapeNode(rectOf: CGSize(width: 40, height: 35), cornerRadius: 3)
        screen.fillColor = .black
        screen.strokeColor = neonBlue
        screen.lineWidth = 1
        screen.position = CGPoint(x: 0, y: 15)
        machine.addChild(screen)
        
        // Screen content (random game preview)
        let gameEmojis = ["🎮", "👾", "🕹️", "🐦", "🎯"]
        let emoji = SKLabelNode()
        emoji.text = gameEmojis.randomElement()
        emoji.fontSize = 20
        emoji.position = CGPoint(x: 0, y: 10)
        machine.addChild(emoji)
        
        // Blinking screen effect
        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ])
        screen.run(SKAction.repeatForever(blink))
        
        return machine
    }
    
    // MARK: - Ambient Lighting
    
    private func setupAmbientLighting() {
        // Ambient glow around the scene edges
        let ambientColors: [SKColor] = [neonPink.withAlphaComponent(0.1), neonBlue.withAlphaComponent(0.1)]
        
        for (index, color) in ambientColors.enumerated() {
            let glow = SKShapeNode(rectOf: CGSize(width: size.width / 2, height: size.height))
            glow.fillColor = color
            glow.strokeColor = .clear
            glow.position = CGPoint(x: index == 0 ? size.width * 0.25 : size.width * 0.75, y: size.height / 2)
            glow.zPosition = -20
            glow.alpha = 0.5
            addChild(glow)
        }
    }
    
    // MARK: - Neon Animations
    
    private func startNeonAnimations() {
        // Flickering effect for neon signs
        for sign in neonSigns {
            let flicker = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.6, duration: 0.1),
                SKAction.fadeAlpha(to: 1.0, duration: 0.1),
                SKAction.wait(forDuration: Double.random(in: 2...5))
            ])
            sign.run(SKAction.repeatForever(flicker))
        }
    }
    
    // MARK: - Pin Knockdown
    
    func knockDownPin(at index: Int) {
        guard index < bowlingPins.count else { return }
        
        let pin = bowlingPins[index]
        
        // Knockdown animation
        let fall = SKAction.sequence([
            SKAction.rotate(byAngle: .pi / 2, duration: 0.2),
            SKAction.moveBy(x: CGFloat.random(in: -20...20), y: -10, duration: 0.1),
            SKAction.fadeAlpha(to: 0.5, duration: 0.3)
        ])
        
        pin.run(fall)
        pinsKnockedDown += 1
        
        // Check for strike
        if pinsKnockedDown == 10 {
            showStrikeAnimation()
        }
    }
    
    func knockDownAllPins() {
        for i in 0..<bowlingPins.count {
            let delay = SKAction.wait(forDuration: Double(i) * 0.05)
            let knockDown = SKAction.run { [weak self] in
                self?.knockDownPin(at: i)
            }
            run(SKAction.sequence([delay, knockDown]))
        }
    }
    
    private func showStrikeAnimation() {
        guard !showingStrikeText else { return }
        showingStrikeText = true
        
        // Big "STRIKE!" text
        let strikeLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        strikeLabel.text = "🎳 STRIKE! 🎳"
        strikeLabel.fontSize = 60
        strikeLabel.fontColor = neonPink
        strikeLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        strikeLabel.setScale(0)
        strikeLabel.zPosition = 100
        addChild(strikeLabel)
        
        // Animation
        let appear = SKAction.scale(to: 1.2, duration: 0.3)
        let bounce = SKAction.sequence([
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.scale(to: 1.1, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        let wait = SKAction.wait(forDuration: 2.0)
        let disappear = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        
        strikeLabel.run(SKAction.sequence([appear, bounce, wait, disappear, remove])) { [weak self] in
            self?.showingStrikeText = false
        }
        
        // Play haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Sound effect (deferred to avoid circular dependency)
        DispatchQueue.main.async {
            SoundManager.shared.playSound(.achievementUnlock)
        }
    }
    
    // MARK: - Reset Pins
    
    func resetPins() {
        pinsKnockedDown = 0
        
        for (index, pin) in bowlingPins.enumerated() {
            let reset = SKAction.sequence([
                SKAction.fadeAlpha(to: 1.0, duration: 0.2),
                SKAction.rotate(toAngle: 0, duration: 0.2)
            ])
            pin.run(reset)
        }
    }
}
