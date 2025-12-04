//
//  ChairBNBEasterEgg.swift
//  BirdGame3
//
//  The legendary CHairBNB easter egg location - a cozy bird rental spot!
//  Hidden at coordinates (-2500, 3141, 75)
//

import SpriteKit
import SwiftUI

// MARK: - ChairBNB Scene Node

class ChairBNBNode: SKNode {
    
    // MARK: - Properties
    
    private var mainHouse: SKNode!
    private var signNode: SKNode!
    private var furnitureNodes: [SKNode] = []
    private var reviewBoard: SKNode!
    private var welcomeMat: SKNode!
    private var ratingStars: SKNode!
    
    // Colors
    private let houseColor = SKColor(red: 0.96, green: 0.87, blue: 0.7, alpha: 1.0) // Warm beige
    private let roofColor = SKColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0) // Brown
    private let chairColor = SKColor(red: 0.4, green: 0.26, blue: 0.13, alpha: 1.0) // Dark wood
    private let sprayPaintColor = SKColor(red: 1.0, green: 0.0, blue: 0.3, alpha: 1.0) // Neon pink spray
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupChairBNB()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupChairBNB() {
        setupMainHouse()
        setupSignage()
        setupFurniture()
        setupWelcomeMat()
        setupReviewBoard()
        setupRatingDisplay()
        setupAmbientEffects()
    }
    
    // MARK: - Main House
    
    private func setupMainHouse() {
        mainHouse = SKNode()
        mainHouse.position = CGPoint(x: 0, y: 0)
        
        // House body (nest-like structure)
        let houseBody = SKShapeNode(rectOf: CGSize(width: 120, height: 80), cornerRadius: 10)
        houseBody.fillColor = houseColor
        houseBody.strokeColor = houseColor.darker()
        houseBody.lineWidth = 3
        mainHouse.addChild(houseBody)
        
        // Nest texture overlay (twigs pattern)
        addNestTexture(to: houseBody)
        
        // Roof
        let roofPath = CGMutablePath()
        roofPath.move(to: CGPoint(x: -70, y: 40))
        roofPath.addLine(to: CGPoint(x: 0, y: 80))
        roofPath.addLine(to: CGPoint(x: 70, y: 40))
        roofPath.closeSubpath()
        
        let roof = SKShapeNode(path: roofPath)
        roof.fillColor = roofColor
        roof.strokeColor = roofColor.darker()
        roof.lineWidth = 2
        mainHouse.addChild(roof)
        
        // Door
        let door = SKShapeNode(rectOf: CGSize(width: 25, height: 40), cornerRadius: 5)
        door.fillColor = SKColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0)
        door.strokeColor = SKColor(red: 0.2, green: 0.15, blue: 0.05, alpha: 1.0)
        door.lineWidth = 2
        door.position = CGPoint(x: 0, y: -20)
        mainHouse.addChild(door)
        
        // Door handle
        let handle = SKShapeNode(circleOfRadius: 3)
        handle.fillColor = .yellow
        handle.position = CGPoint(x: 8, y: -20)
        mainHouse.addChild(handle)
        
        // Windows
        let leftWindow = createWindow()
        leftWindow.position = CGPoint(x: -35, y: 10)
        mainHouse.addChild(leftWindow)
        
        let rightWindow = createWindow()
        rightWindow.position = CGPoint(x: 35, y: 10)
        mainHouse.addChild(rightWindow)
        
        // Chimney
        let chimney = SKShapeNode(rectOf: CGSize(width: 15, height: 25))
        chimney.fillColor = SKColor(red: 0.6, green: 0.3, blue: 0.2, alpha: 1.0)
        chimney.strokeColor = SKColor(red: 0.5, green: 0.25, blue: 0.15, alpha: 1.0)
        chimney.position = CGPoint(x: 30, y: 70)
        mainHouse.addChild(chimney)
        
        // Smoke from chimney
        addChimneySmoke(at: CGPoint(x: 30, y: 85))
        
        addChild(mainHouse)
    }
    
    private func addNestTexture(to node: SKShapeNode) {
        // Add twig-like lines to simulate nest texture
        for _ in 0..<15 {
            let twig = SKShapeNode()
            let path = CGMutablePath()
            let startX = CGFloat.random(in: -50...50)
            let startY = CGFloat.random(in: -30...30)
            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: startX + CGFloat.random(in: -20...20), y: startY + CGFloat.random(in: -5...5)))
            twig.path = path
            twig.strokeColor = houseColor.darker()
            twig.lineWidth = 1
            twig.alpha = 0.5
            node.addChild(twig)
        }
    }
    
    private func createWindow() -> SKNode {
        let window = SKNode()
        
        // Window frame
        let frame = SKShapeNode(rectOf: CGSize(width: 20, height: 20), cornerRadius: 2)
        frame.fillColor = SKColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0) // Light blue glass
        frame.strokeColor = houseColor.darker()
        frame.lineWidth = 2
        window.addChild(frame)
        
        // Window cross
        let verticalBar = SKShapeNode(rectOf: CGSize(width: 2, height: 20))
        verticalBar.fillColor = houseColor.darker()
        verticalBar.strokeColor = .clear
        window.addChild(verticalBar)
        
        let horizontalBar = SKShapeNode(rectOf: CGSize(width: 20, height: 2))
        horizontalBar.fillColor = houseColor.darker()
        horizontalBar.strokeColor = .clear
        window.addChild(horizontalBar)
        
        // Window shine
        let shine = SKShapeNode(rectOf: CGSize(width: 5, height: 8))
        shine.fillColor = .white
        shine.strokeColor = .clear
        shine.alpha = 0.5
        shine.position = CGPoint(x: -4, y: 3)
        window.addChild(shine)
        
        return window
    }
    
    private func addChimneySmoke(at position: CGPoint) {
        // Simple smoke puffs
        let smokeAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            let smoke = SKShapeNode(circleOfRadius: 5)
            smoke.fillColor = .lightGray
            smoke.strokeColor = .clear
            smoke.alpha = 0.6
            smoke.position = position
            self.mainHouse.addChild(smoke)
            
            let rise = SKAction.moveBy(x: CGFloat.random(in: -10...10), y: 30, duration: 2.0)
            let fade = SKAction.fadeOut(withDuration: 2.0)
            let grow = SKAction.scale(to: 2.0, duration: 2.0)
            let group = SKAction.group([rise, fade, grow])
            let remove = SKAction.removeFromParent()
            
            smoke.run(SKAction.sequence([group, remove]))
        }
        
        let wait = SKAction.wait(forDuration: 1.5)
        let smokeSequence = SKAction.sequence([smokeAction, wait])
        mainHouse.run(SKAction.repeatForever(smokeSequence))
    }
    
    // MARK: - Signage
    
    private func setupSignage() {
        signNode = SKNode()
        signNode.position = CGPoint(x: 80, y: 30)
        
        // Sign post
        let post = SKShapeNode(rectOf: CGSize(width: 5, height: 60))
        post.fillColor = chairColor
        post.strokeColor = chairColor.darker()
        post.position = CGPoint(x: 0, y: -30)
        signNode.addChild(post)
        
        // Sign board
        let signBoard = SKShapeNode(rectOf: CGSize(width: 80, height: 35), cornerRadius: 5)
        signBoard.fillColor = .white
        signBoard.strokeColor = SKColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        signBoard.lineWidth = 2
        signBoard.position = CGPoint(x: 0, y: 15)
        signNode.addChild(signBoard)
        
        // "airBNB" text (original)
        let airbnbText = SKLabelNode(fontNamed: "AvenirNext-Bold")
        airbnbText.text = "airBNB"
        airbnbText.fontSize = 14
        airbnbText.fontColor = SKColor(red: 1.0, green: 0.39, blue: 0.51, alpha: 1.0) // Airbnb pink
        airbnbText.position = CGPoint(x: 8, y: 12)
        signNode.addChild(airbnbText)
        
        // Spray painted "CH" in front
        let chText = SKLabelNode(fontNamed: "Marker Felt")
        chText.text = "CH"
        chText.fontSize = 18
        chText.fontColor = sprayPaintColor
        chText.position = CGPoint(x: -22, y: 10)
        chText.zRotation = 0.1 // Slightly tilted for spray paint effect
        signNode.addChild(chText)
        
        // Spray paint drips
        addSprayPaintDrips(at: CGPoint(x: -25, y: 5))
        
        // "Welcome!" subtitle
        let welcomeText = SKLabelNode(fontNamed: "AvenirNext-Medium")
        welcomeText.text = "🐦 Bird-Friendly Stay! 🐦"
        welcomeText.fontSize = 8
        welcomeText.fontColor = .darkGray
        welcomeText.position = CGPoint(x: 0, y: 0)
        signNode.addChild(welcomeText)
        
        addChild(signNode)
    }
    
    private func addSprayPaintDrips(at position: CGPoint) {
        for i in 0..<3 {
            let drip = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: position.x + CGFloat(i) * 5, y: position.y))
            path.addLine(to: CGPoint(x: position.x + CGFloat(i) * 5, y: position.y - CGFloat.random(in: 5...15)))
            drip.path = path
            drip.strokeColor = sprayPaintColor.withAlphaComponent(0.7)
            drip.lineWidth = 2
            signNode.addChild(drip)
        }
    }
    
    // MARK: - Furniture
    
    private func setupFurniture() {
        // Oversized comfy chair (comedic effect)
        let bigChair = createComfyChair(scale: 1.5)
        bigChair.position = CGPoint(x: -80, y: -30)
        addChild(bigChair)
        furnitureNodes.append(bigChair)
        
        // Small bird-sized chair
        let smallChair = createComfyChair(scale: 0.5)
        smallChair.position = CGPoint(x: -50, y: -45)
        addChild(smallChair)
        furnitureNodes.append(smallChair)
        
        // Tiny table with seeds
        let table = createBirdTable()
        table.position = CGPoint(x: -65, y: -50)
        addChild(table)
        furnitureNodes.append(table)
        
        // Bird bath (luxury amenity)
        let birdBath = createBirdBath()
        birdBath.position = CGPoint(x: 100, y: -40)
        addChild(birdBath)
        furnitureNodes.append(birdBath)
    }
    
    private func createComfyChair(scale: CGFloat) -> SKNode {
        let chair = SKNode()
        chair.setScale(scale)
        
        // Chair seat
        let seat = SKShapeNode(rectOf: CGSize(width: 30, height: 8), cornerRadius: 3)
        seat.fillColor = SKColor(red: 0.6, green: 0.3, blue: 0.3, alpha: 1.0) // Burgundy
        seat.strokeColor = seat.fillColor.darker()
        seat.lineWidth = 1
        chair.addChild(seat)
        
        // Chair back
        let back = SKShapeNode(rectOf: CGSize(width: 30, height: 25), cornerRadius: 5)
        back.fillColor = SKColor(red: 0.6, green: 0.3, blue: 0.3, alpha: 1.0)
        back.strokeColor = back.fillColor.darker()
        back.lineWidth = 1
        back.position = CGPoint(x: 0, y: 15)
        chair.addChild(back)
        
        // Chair legs
        for x in [-10, 10] {
            let leg = SKShapeNode(rectOf: CGSize(width: 4, height: 12))
            leg.fillColor = chairColor
            leg.strokeColor = chairColor.darker()
            leg.position = CGPoint(x: CGFloat(x), y: -8)
            chair.addChild(leg)
        }
        
        // Cushion
        let cushion = SKShapeNode(ellipseOf: CGSize(width: 20, height: 6))
        cushion.fillColor = SKColor(red: 0.8, green: 0.6, blue: 0.6, alpha: 1.0)
        cushion.strokeColor = .clear
        cushion.position = CGPoint(x: 0, y: 2)
        chair.addChild(cushion)
        
        return chair
    }
    
    private func createBirdTable() -> SKNode {
        let table = SKNode()
        
        // Table top
        let top = SKShapeNode(ellipseOf: CGSize(width: 25, height: 20))
        top.fillColor = chairColor
        top.strokeColor = chairColor.darker()
        top.lineWidth = 1
        table.addChild(top)
        
        // Table leg
        let leg = SKShapeNode(rectOf: CGSize(width: 5, height: 15))
        leg.fillColor = chairColor
        leg.strokeColor = chairColor.darker()
        leg.position = CGPoint(x: 0, y: -10)
        table.addChild(leg)
        
        // Seeds on table
        for _ in 0..<5 {
            let seed = SKShapeNode(ellipseOf: CGSize(width: 3, height: 2))
            seed.fillColor = SKColor(red: 0.8, green: 0.7, blue: 0.4, alpha: 1.0)
            seed.strokeColor = .clear
            seed.position = CGPoint(x: CGFloat.random(in: -8...8), y: CGFloat.random(in: -5...5))
            table.addChild(seed)
        }
        
        return table
    }
    
    private func createBirdBath() -> SKNode {
        let bath = SKNode()
        
        // Base
        let base = SKShapeNode(rectOf: CGSize(width: 15, height: 25))
        base.fillColor = .gray
        base.strokeColor = .darkGray
        base.position = CGPoint(x: 0, y: -15)
        bath.addChild(base)
        
        // Bowl
        let bowl = SKShapeNode(ellipseOf: CGSize(width: 35, height: 12))
        bowl.fillColor = .gray
        bowl.strokeColor = .darkGray
        bath.addChild(bowl)
        
        // Water
        let water = SKShapeNode(ellipseOf: CGSize(width: 28, height: 8))
        water.fillColor = SKColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 0.8)
        water.strokeColor = .clear
        water.position = CGPoint(x: 0, y: -1)
        bath.addChild(water)
        
        // Water shimmer
        let shimmer = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.6, duration: 1.0),
            SKAction.fadeAlpha(to: 0.9, duration: 1.0)
        ])
        water.run(SKAction.repeatForever(shimmer))
        
        return bath
    }
    
    // MARK: - Welcome Mat
    
    private func setupWelcomeMat() {
        welcomeMat = SKNode()
        welcomeMat.position = CGPoint(x: 0, y: -55)
        
        // Mat
        let mat = SKShapeNode(rectOf: CGSize(width: 40, height: 20), cornerRadius: 3)
        mat.fillColor = SKColor(red: 0.4, green: 0.5, blue: 0.3, alpha: 1.0) // Green mat
        mat.strokeColor = mat.fillColor.darker()
        mat.lineWidth = 1
        welcomeMat.addChild(mat)
        
        // "WELCOME" text
        let text = SKLabelNode(fontNamed: "AvenirNext-Bold")
        text.text = "WELCOME"
        text.fontSize = 6
        text.fontColor = SKColor(red: 0.9, green: 0.9, blue: 0.7, alpha: 1.0)
        welcomeMat.addChild(text)
        
        addChild(welcomeMat)
    }
    
    // MARK: - Review Board
    
    private func setupReviewBoard() {
        reviewBoard = SKNode()
        reviewBoard.position = CGPoint(x: -100, y: 50)
        
        // Board background
        let board = SKShapeNode(rectOf: CGSize(width: 70, height: 90), cornerRadius: 5)
        board.fillColor = SKColor(red: 0.85, green: 0.75, blue: 0.6, alpha: 1.0) // Cork board
        board.strokeColor = chairColor
        board.lineWidth = 3
        reviewBoard.addChild(board)
        
        // Title
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "Reviews"
        title.fontSize = 10
        title.fontColor = .darkGray
        title.position = CGPoint(x: 0, y: 35)
        reviewBoard.addChild(title)
        
        // Funny bird reviews
        let reviews = [
            "⭐⭐⭐⭐⭐ Great perches! -Pigeon42",
            "⭐⭐⭐⭐ Seeds were fresh -EagleEye",
            "⭐⭐⭐⭐⭐ Would nest again! -CrowLord"
        ]
        
        for (index, review) in reviews.enumerated() {
            let reviewLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
            reviewLabel.text = review
            reviewLabel.fontSize = 5
            reviewLabel.fontColor = .darkGray
            reviewLabel.position = CGPoint(x: 0, y: 20 - CGFloat(index) * 18)
            reviewLabel.preferredMaxLayoutWidth = 60
            reviewLabel.numberOfLines = 2
            reviewBoard.addChild(reviewLabel)
        }
        
        addChild(reviewBoard)
    }
    
    // MARK: - Rating Display
    
    private func setupRatingDisplay() {
        ratingStars = SKNode()
        ratingStars.position = CGPoint(x: 80, y: -20)
        
        // "5 STARS!" badge
        let badge = SKShapeNode(circleOfRadius: 20)
        badge.fillColor = .yellow
        badge.strokeColor = .orange
        badge.lineWidth = 2
        ratingStars.addChild(badge)
        
        // Stars
        let starsLabel = SKLabelNode()
        starsLabel.text = "⭐⭐⭐⭐⭐"
        starsLabel.fontSize = 6
        starsLabel.position = CGPoint(x: 0, y: 5)
        ratingStars.addChild(starsLabel)
        
        // "5.0" text
        let ratingText = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        ratingText.text = "5.0"
        ratingText.fontSize = 10
        ratingText.fontColor = .darkGray
        ratingText.position = CGPoint(x: 0, y: -8)
        ratingStars.addChild(ratingText)
        
        // Sparkle effect
        let sparkle = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        ratingStars.run(SKAction.repeatForever(sparkle))
        
        addChild(ratingStars)
    }
    
    // MARK: - Ambient Effects
    
    private func setupAmbientEffects() {
        // Floating feathers
        let featherAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            let feather = SKLabelNode()
            feather.text = "🪶"
            feather.fontSize = 10
            feather.position = CGPoint(
                x: CGFloat.random(in: -100...100),
                y: 100
            )
            feather.alpha = 0.7
            self.addChild(feather)
            
            let drift = SKAction.moveBy(
                x: CGFloat.random(in: -30...30),
                y: -180,
                duration: 5.0
            )
            let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 5.0)
            let fade = SKAction.fadeOut(withDuration: 5.0)
            let group = SKAction.group([drift, rotate, fade])
            let remove = SKAction.removeFromParent()
            
            feather.run(SKAction.sequence([group, remove]))
        }
        
        let wait = SKAction.wait(forDuration: 3.0)
        let featherSequence = SKAction.sequence([featherAction, wait])
        run(SKAction.repeatForever(featherSequence))
        
        // Ambient bird sounds (visual only - chirp bubbles)
        addChirpBubbles()
    }
    
    private func addChirpBubbles() {
        let chirpAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            let bubble = SKNode()
            bubble.position = CGPoint(
                x: CGFloat.random(in: -60...60),
                y: CGFloat.random(in: -20...40)
            )
            
            // Speech bubble
            let bg = SKShapeNode(ellipseOf: CGSize(width: 30, height: 15))
            bg.fillColor = .white
            bg.strokeColor = .lightGray
            bg.alpha = 0.9
            bubble.addChild(bg)
            
            // Chirp text
            let chirps = ["♪", "♫", "chirp!", "tweet!", "coo~"]
            let text = SKLabelNode(fontNamed: "AvenirNext-Medium")
            text.text = chirps.randomElement()
            text.fontSize = 8
            text.fontColor = .darkGray
            bubble.addChild(text)
            
            self.addChild(bubble)
            
            let rise = SKAction.moveBy(x: 0, y: 20, duration: 1.5)
            let fade = SKAction.fadeOut(withDuration: 1.5)
            let group = SKAction.group([rise, fade])
            let remove = SKAction.removeFromParent()
            
            bubble.run(SKAction.sequence([group, remove]))
        }
        
        let wait = SKAction.wait(forDuration: 4.0)
        let chirpSequence = SKAction.sequence([chirpAction, wait])
        run(SKAction.repeatForever(chirpSequence))
    }
}

// MARK: - ChairBNB SwiftUI View (for Open World integration)

struct ChairBNBView: View {
    @State private var discovered = false
    @State private var showingRewards = false
    @State private var scene: SKScene?  // Store scene to avoid recreating on every body evaluation
    
    var body: some View {
        ZStack {
            // Placeholder for SpriteKit integration
            if let scene = scene {
                SpriteView(scene: scene)
                    .frame(width: 300, height: 250)
                    .cornerRadius(16)
            } else {
                Color.gray
                    .frame(width: 300, height: 250)
                    .cornerRadius(16)
            }
            
            if showingRewards {
                VStack(spacing: 16) {
                    Text("🎉 Easter Egg Found! 🎉")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Welcome to CHairBNB!")
                        .font(.headline)
                        .foregroundColor(.yellow)
                    
                    VStack(spacing: 8) {
                        Text("🪑 Unlocked: CHairBNB Guest badge")
                        Text("🏠 Unlocked: CHairBNB Host icon")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    
                    Button("Continue") {
                        showingRewards = false
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(30)
                .background(Color.black.opacity(0.85))
                .cornerRadius(20)
            }
        }
        .onAppear {
            // Create scene once on appear
            if scene == nil {
                scene = createChairBNBScene()
            }
            if !discovered {
                discovered = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showingRewards = true
                }
            }
        }
    }
    
    private func createChairBNBScene() -> SKScene {
        let newScene = SKScene(size: CGSize(width: 300, height: 250))
        newScene.backgroundColor = SKColor(red: 0.6, green: 0.8, blue: 0.6, alpha: 1.0) // Grassy green
        
        let chairBNB = ChairBNBNode()
        chairBNB.position = CGPoint(x: 150, y: 125)
        chairBNB.setScale(0.8)
        newScene.addChild(chairBNB)
        
        return newScene
    }
}

#Preview {
    ChairBNBView()
        .frame(width: 350, height: 300)
        .background(Color.black)
}
