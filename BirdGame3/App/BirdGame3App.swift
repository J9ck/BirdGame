//
//  BirdGame3App.swift
//  BirdGame3
//
//  The iconic Bird Game 3 - where pigeons rise up and hummingbirds are still OP
//

import SwiftUI
import SceneKit

@main
struct BirdGame3App: App {
    @StateObject private var gameState = GameState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameState)
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var gameState: GameState
    @ObservedObject var account = AccountManager.shared
    @State private var showTutorial: Bool = false
    @State private var showLogin: Bool = false
    
    var body: some View {
        ZStack {
            NavigationCompat {
                switch gameState.currentScreen {
                case .mainMenu:
                    MainMenuView()
                case .login:
                    LoginView()
                case .lobby:
                    LobbyView()
                case .characterSelect:
                    CharacterSelectView()
                case .game:
                    GameView()
                case .results:
                    ResultsView()
                case .shop:
                    ShopView()
                case .settings:
                    SettingsView()
                case .openWorld:
                    OpenWorldView()
                case .nestBuilder:
                    NestBuilderView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: gameState.currentScreen)
            
            // Tutorial overlay for first-time users
            if showTutorial {
                TutorialView(showTutorial: $showTutorial)
                    .transition(.opacity)
            }
        }
        .onAppear {
            checkFirstLaunch()
        }
    }
    
    private func checkFirstLaunch() {
        let tutorialCompleted = UserDefaults.standard.bool(forKey: "birdgame3_tutorialCompleted")
        if !tutorialCompleted {
            // Show tutorial with slight delay for smooth transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showTutorial = true
                }
            }
        }
    }
}

// MARK: - Open World View (Like "The Wolf" MMORPG)

struct OpenWorldView: View {
    @EnvironmentObject var gameState: GameState
    @ObservedObject var openWorld = OpenWorldManager.shared
    @ObservedObject var voiceChat = LiveVoiceChatManager.shared
    @ObservedObject var flock = FlockManager.shared
    
    @State private var showInventory = false
    @State private var showMap = false
    @State private var showPreyList = false
    @State private var huntMessage = ""
    @State private var showHuntMessage = false
    @State private var joystickOffset: CGSize = .zero
    @State private var isMoving = false
    @State private var altitudeSliderValue: Double = 50
    
    // 3D Scene reference
    @State private var scene3D: OpenWorld3DScene?
    
    var body: some View {
        ZStack {
            // 3D Scene View as the main background
            OpenWorld3DViewRepresentable(
                scene: scene3D,
                birdType: gameState.selectedBird,
                openWorldManager: openWorld,
                joystickOffset: joystickOffset,
                altitude: Float(altitudeSliderValue)
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top HUD
                topHUD
                
                Spacer()
                
                // Bottom controls
                bottomControls
            }
            
            // Minimap in top-right
            minimap
                .position(x: UIScreen.main.bounds.width - 70, y: 140)
            
            // Altitude slider on the right side
            altitudeControl
                .position(x: UIScreen.main.bounds.width - 40, y: UIScreen.main.bounds.height / 2)
            
            // Hunt message overlay
            if showHuntMessage {
                huntMessageOverlay
            }
            
            // Prey list sheet
            if showPreyList {
                preyListView
            }
            
            // Map overlay
            if showMap {
                worldMapView
            }
            
            // Inventory overlay
            if showInventory {
                inventoryView
            }
            
            // Voice chat overlay
            VoiceChatOverlay()
        }
        .onAppear {
            setupScene()
        }
    }
    
    private func setupScene() {
        scene3D = OpenWorld3DScene(birdType: gameState.selectedBird, manager: openWorld)
    }
    
    // MARK: - Altitude Control
    
    private var altitudeControl: some View {
        VStack(spacing: 8) {
            Text("🔼")
                .font(.title2)
            
            // Vertical slider for altitude
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8)
                    
                    // Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: 8, height: geometry.size.height * CGFloat(altitudeSliderValue / 500))
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newValue = 500 - (Double(value.location.y / geometry.size.height) * 500)
                            altitudeSliderValue = max(5, min(500, newValue))
                        }
                )
            }
            .frame(width: 30, height: 150)
            
            Text("🔽")
                .font(.title2)
            
            Text("\(Int(altitudeSliderValue))m")
                .font(.caption2)
                .foregroundColor(.white)
        }
        .padding(8)
        .background(Color.black.opacity(0.5))
        .cornerRadius(12)
    }
    
    // MARK: - Biome Background
    
    private var biomeBackground: some View {
        let colors: [Color] = {
            switch openWorld.playerState.currentBiome {
            case .forest: return [Color(red: 0.1, green: 0.3, blue: 0.1), Color(red: 0.05, green: 0.15, blue: 0.05)]
            case .desert: return [Color(red: 0.6, green: 0.5, blue: 0.3), Color(red: 0.4, green: 0.3, blue: 0.2)]
            case .mountain: return [Color(red: 0.4, green: 0.4, blue: 0.5), Color(red: 0.2, green: 0.2, blue: 0.3)]
            case .swamp: return [Color(red: 0.2, green: 0.3, blue: 0.2), Color(red: 0.1, green: 0.2, blue: 0.15)]
            case .beach: return [Color(red: 0.3, green: 0.5, blue: 0.7), Color(red: 0.6, green: 0.5, blue: 0.4)]
            case .tundra: return [Color(red: 0.7, green: 0.8, blue: 0.9), Color(red: 0.5, green: 0.6, blue: 0.7)]
            case .jungle: return [Color(red: 0.1, green: 0.4, blue: 0.2), Color(red: 0.05, green: 0.2, blue: 0.1)]
            case .plains: return [Color(red: 0.3, green: 0.5, blue: 0.3), Color(red: 0.2, green: 0.3, blue: 0.2)]
            }
        }()
        
        let timeOverlay: Color = {
            switch openWorld.timeOfDay {
            case .dawn: return Color.orange.opacity(0.2)
            case .day: return Color.clear
            case .dusk: return Color.purple.opacity(0.2)
            case .night: return Color.black.opacity(0.4)
            }
        }()
        
        return ZStack {
            LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            timeOverlay.ignoresSafeArea()
        }
    }
    
    // MARK: - Top HUD
    
    private var topHUD: some View {
        VStack(spacing: 8) {
            HStack {
                // Back button
                Button(action: { gameState.navigateTo(.mainMenu) }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                
                // Status bars (compact)
                VStack(spacing: 4) {
                    CompactStatusBar(icon: "❤️", value: openWorld.playerState.health, maxValue: 100, color: .red)
                    CompactStatusBar(icon: "🍖", value: openWorld.playerState.hunger, maxValue: 100, color: .orange)
                    CompactStatusBar(icon: "⚡", value: openWorld.playerState.energy, maxValue: 100, color: .yellow)
                }
                .frame(width: 120)
                
                Spacer()
                
                // Location & Weather info
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Text(openWorld.playerState.currentBiome.emoji)
                        Text(openWorld.playerState.currentBiome.displayName)
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    HStack(spacing: 8) {
                        Text(openWorld.currentWeather.emoji)
                        Text(openWorld.timeOfDay.emoji)
                    }
                    .font(.caption2)
                    
                    // Territory info
                    if let territory = openWorld.currentTerritory {
                        HStack(spacing: 4) {
                            Text("📍")
                            Text(territory.name)
                                .font(.caption2)
                            if let flockName = territory.controllingFlockName {
                                Text("[\(flockName)]")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                }
                .foregroundColor(.white)
                .padding(8)
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Hunting target indicator
            if let target = openWorld.huntingTarget {
                huntingTargetBar(target: target)
            }
        }
    }
    
    private func huntingTargetBar(target: Prey) -> some View {
        HStack {
            Text("🎯 Hunting: \(target.type.emoji) \(target.type.displayName)")
                .font(.caption)
                .fontWeight(.bold)
            
            Spacer()
            
            // Target health bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: geometry.size.width * target.healthPercent)
                }
            }
            .frame(width: 80, height: 10)
            .cornerRadius(5)
            
            Text("\(Int(target.health))/\(Int(target.maxHealth))")
                .font(.caption2)
            
            Button(action: { openWorld.stopHunting() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    // MARK: - Center World View
    
    private var centerWorldView: some View {
        ZStack {
            // Prey display (like animals in The Wolf)
            ForEach(openWorld.nearbyPrey) { prey in
                PreyMarker(prey: prey, isTarget: openWorld.huntingTarget?.id == prey.id) {
                    openWorld.startHunting(prey)
                }
            }
            
            // Nearby players
            ForEach(openWorld.nearbyPlayers) { player in
                PlayerMarker(player: player)
            }
            
            // Resources
            ForEach(openWorld.nearbyResources.prefix(5)) { resource in
                ResourceMarker(resource: resource) {
                    let result = openWorld.harvestResource(resource)
                    if result.success {
                        showHuntResult("Gathered \(result.amount)x \(resource.type.emoji)")
                    }
                }
            }
            
            // Player bird indicator (center)
            VStack {
                Text(gameState.selectedBird.emoji)
                    .font(.system(size: 50))
                    .shadow(color: .black, radius: 2)
                Text("YOU")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(4)
            }
        }
        .frame(height: 300)
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 12) {
            // Action buttons row
            HStack(spacing: 16) {
                WorldActionButton(icon: "🪺", label: "Nest") {
                    gameState.navigateTo(.nestBuilder)
                }
                
                WorldActionButton(icon: "🎒", label: "Bag") {
                    showInventory = true
                }
                
                WorldActionButton(icon: "🗺️", label: "Map") {
                    showMap = true
                }
                
                WorldActionButton(icon: "🦎", label: "Hunt") {
                    showPreyList = true
                }
            }
            
            // Movement and attack controls
            HStack {
                // Virtual joystick (left side)
                virtualJoystick
                
                Spacer()
                
                // Attack button (right side)
                VStack(spacing: 12) {
                    // Attack button
                    Button(action: performAttack) {
                        VStack {
                            Text("⚔️")
                                .font(.title)
                            Text("ATTACK")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .frame(width: 70, height: 70)
                        .background(
                            Circle()
                                .fill(openWorld.huntingTarget != nil ? Color.red : Color.gray)
                        )
                        .foregroundColor(.white)
                    }
                    .disabled(openWorld.huntingTarget == nil)
                    
                    // Sprint button
                    Button(action: performSprint) {
                        VStack {
                            Text("💨")
                                .font(.title2)
                            Text("SPRINT")
                                .font(.caption2)
                        }
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(openWorld.playerState.energy > 10 ? Color.blue : Color.gray)
                        )
                        .foregroundColor(.white)
                    }
                    .disabled(openWorld.playerState.energy <= 10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Virtual Joystick
    
    private var virtualJoystick: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 120, height: 120)
            
            Circle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 50, height: 50)
                .offset(joystickOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let maxOffset: CGFloat = 35
                            let translation = value.translation
                            let distance = sqrt(pow(translation.width, 2) + pow(translation.height, 2))
                            
                            if distance <= maxOffset {
                                joystickOffset = translation
                            } else {
                                let angle = atan2(translation.height, translation.width)
                                joystickOffset = CGSize(
                                    width: cos(angle) * maxOffset,
                                    height: sin(angle) * maxOffset
                                )
                            }
                            
                            isMoving = true
                            movePlayer()
                        }
                        .onEnded { _ in
                            withAnimation(.spring()) {
                                joystickOffset = .zero
                            }
                            isMoving = false
                        }
                )
        }
    }
    
    // MARK: - Minimap
    
    private var minimap: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.6))
                .frame(width: 120, height: 120)
            
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                .frame(width: 120, height: 120)
            
            // Player dot (center)
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
            
            // Prey dots
            ForEach(openWorld.nearbyPrey.prefix(10)) { prey in
                let dx = (prey.position.x - openWorld.playerState.position.x) / 200.0
                let dy = (prey.position.y - openWorld.playerState.position.y) / 200.0
                let clampedX = max(-50, min(50, dx * 50))
                let clampedY = max(-50, min(50, dy * 50))
                
                Circle()
                    .fill(Color.orange)
                    .frame(width: 4, height: 4)
                    .offset(x: clampedX, y: clampedY)
            }
            
            // Player dots
            ForEach(openWorld.nearbyPlayers.prefix(5)) { player in
                let dx = (player.position.x - openWorld.playerState.position.x) / 200.0
                let dy = (player.position.y - openWorld.playerState.position.y) / 200.0
                let clampedX = max(-50, min(50, dx * 50))
                let clampedY = max(-50, min(50, dy * 50))
                
                Circle()
                    .fill(player.isHostile ? Color.red : Color.blue)
                    .frame(width: 5, height: 5)
                    .offset(x: clampedX, y: clampedY)
            }
            
            // Nest marker
            if let nest = openWorld.homeNest {
                let dx = (nest.position.x - openWorld.playerState.position.x) / 200.0
                let dy = (nest.position.y - openWorld.playerState.position.y) / 200.0
                let clampedX = max(-50, min(50, dx * 50))
                let clampedY = max(-50, min(50, dy * 50))
                
                Text("🪺")
                    .font(.system(size: 10))
                    .offset(x: clampedX, y: clampedY)
            }
            
            // Compass direction
            Text("N")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .offset(y: -52)
        }
    }
    
    // MARK: - Hunt Message Overlay
    
    private var huntMessageOverlay: some View {
        Text(huntMessage)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding()
            .background(Color.black.opacity(0.7))
            .cornerRadius(12)
            .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Prey List View
    
    private var preyListView: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture { showPreyList = false }
            
            VStack(spacing: 16) {
                HStack {
                    Text("🎯 Nearby Prey")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { showPreyList = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                
                if openWorld.nearbyPrey.isEmpty {
                    Text("No prey nearby. Try moving to a different area!")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(openWorld.nearbyPrey) { prey in
                                PreyListRow(prey: prey) {
                                    openWorld.startHunting(prey)
                                    showPreyList = false
                                }
                            }
                        }
                    }
                }
                
                // Hunt stats
                HStack {
                    VStack {
                        Text("\(openWorld.totalPreyHunted)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Total Hunted")
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("🔥 \(openWorld.huntingStreak)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Streak")
                            .font(.caption)
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
            .frame(maxWidth: 350)
            .background(Color(white: 0.15))
            .cornerRadius(20)
        }
    }
    
    // MARK: - World Map View
    
    private var worldMapView: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture { showMap = false }
            
            VStack(spacing: 16) {
                HStack {
                    Text("🗺️ World Map")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { showMap = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                
                // Territory map
                ZStack {
                    Circle()
                        .fill(Color(white: 0.2))
                        .frame(width: 280, height: 280)
                    
                    // Territory regions
                    ForEach(openWorld.territories) { territory in
                        let angle = atan2(territory.centerPosition.y, territory.centerPosition.x)
                        let distance: CGFloat = 100
                        let x = cos(angle) * distance
                        let y = sin(angle) * distance
                        
                        VStack(spacing: 2) {
                            Text(territory.biome.emoji)
                                .font(.title2)
                            Text(territory.name)
                                .font(.caption2)
                                .lineLimit(1)
                            if let flockName = territory.controllingFlockName {
                                Text(flockName)
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(4)
                        .background(territory.isNeutral ? Color.gray.opacity(0.5) : Color.red.opacity(0.5))
                        .cornerRadius(8)
                        .offset(x: x, y: y)
                    }
                    
                    // Player position
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
                
                // Current position
                Text("Position: X:\(Int(openWorld.playerState.position.x)) Y:\(Int(openWorld.playerState.position.y))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: 350)
            .background(Color(white: 0.1))
            .cornerRadius(20)
        }
    }
    
    // MARK: - Inventory View
    
    private var inventoryView: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture { showInventory = false }
            
            VStack(spacing: 16) {
                HStack {
                    Text("🎒 Inventory")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(openWorld.playerState.inventoryCount)/\(openWorld.playerState.maxInventory)")
                        .foregroundColor(.gray)
                    
                    Button(action: { showInventory = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                
                if openWorld.playerState.inventory.isEmpty {
                    Text("Your inventory is empty!")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(Array(openWorld.playerState.inventory.keys), id: \.self) { resource in
                            VStack {
                                Text(resource.emoji)
                                    .font(.title)
                                Text("\(openWorld.playerState.inventory[resource] ?? 0)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                Text(resource.displayName)
                                    .font(.caption2)
                            }
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: 350)
            .background(Color(white: 0.15))
            .cornerRadius(20)
        }
    }
    
    // MARK: - Actions
    
    private func movePlayer() {
        let moveX = Double(joystickOffset.width) / 35.0 * 5.0
        let moveY = Double(joystickOffset.height) / 35.0 * 5.0
        
        openWorld.move(
            direction: WorldPosition(x: moveX, y: moveY, z: 0),
            speed: 1.0
        )
    }
    
    private func performAttack() {
        let attackPower = gameState.selectedBird.baseStats.attack
        let result = openWorld.attackPrey(attackPower: Double(attackPower))
        showHuntResult(result.message)
    }
    
    private func performSprint() {
        guard openWorld.playerState.energy > 10 else { return }
        
        let moveX = Double(joystickOffset.width) / 35.0 * 15.0
        let moveY = Double(joystickOffset.height) / 35.0 * 15.0
        
        openWorld.move(
            direction: WorldPosition(x: moveX, y: moveY, z: 0),
            speed: 3.0
        )
    }
    
    private func showHuntResult(_ message: String) {
        huntMessage = message
        withAnimation {
            showHuntMessage = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showHuntMessage = false
            }
        }
    }
}

// MARK: - Supporting Views

struct CompactStatusBar: View {
    let icon: String
    let value: Double
    let maxValue: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(icon)
                .font(.caption2)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(value / maxValue))
                }
            }
            .frame(height: 6)
            .cornerRadius(3)
        }
    }
}

struct PreyMarker: View {
    let prey: Prey
    let isTarget: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(prey.type.emoji)
                    .font(.system(size: isTarget ? 35 : 25))
                
                if isTarget {
                    // Health bar for target
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray)
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: geometry.size.width * prey.healthPercent)
                        }
                    }
                    .frame(width: 40, height: 4)
                    .cornerRadius(2)
                }
            }
        }
        .offset(x: offsetX, y: offsetY)
        .opacity(prey.isAlerted ? 0.7 : 1.0)
        .scaleEffect(isTarget ? 1.2 : 1.0)
        .animation(.easeInOut, value: isTarget)
    }
    
    // Calculate offset based on actual world position relative to player
    private var offsetX: CGFloat {
        CGFloat((prey.position.x.truncatingRemainder(dividingBy: 200)) - 100).clamped(to: -140...140)
    }
    
    private var offsetY: CGFloat {
        CGFloat((prey.position.y.truncatingRemainder(dividingBy: 100)) - 50).clamped(to: -70...70)
    }
}

struct PlayerMarker: View {
    let player: WorldPlayer
    
    var body: some View {
        VStack(spacing: 2) {
            Text(player.birdType.emoji)
                .font(.system(size: 20))
            
            Text(player.name)
                .font(.caption2)
                .foregroundColor(player.isHostile ? .red : .cyan)
                .lineLimit(1)
        }
        .offset(x: offsetX, y: offsetY)
    }
    
    // Calculate offset based on actual world position
    private var offsetX: CGFloat {
        CGFloat((player.position.x.truncatingRemainder(dividingBy: 240)) - 120).clamped(to: -140...140)
    }
    
    private var offsetY: CGFloat {
        CGFloat((player.position.y.truncatingRemainder(dividingBy: 120)) - 60).clamped(to: -70...70)
    }
}

struct ResourceMarker: View {
    let resource: Resource
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(resource.type.emoji)
                    .font(.system(size: 20))
                
                if resource.canHarvest {
                    Text("x\(resource.amount)")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .offset(x: offsetX, y: offsetY)
        .opacity(resource.canHarvest ? 1.0 : 0.5)
    }
    
    // Calculate offset based on actual world position
    private var offsetX: CGFloat {
        CGFloat((resource.position.x.truncatingRemainder(dividingBy: 280)) - 140).clamped(to: -140...140)
    }
    
    private var offsetY: CGFloat {
        CGFloat((resource.position.y.truncatingRemainder(dividingBy: 140)) - 70).clamped(to: -70...70)
    }
}

struct PreyListRow: View {
    let prey: Prey
    let onHunt: () -> Void
    
    var body: some View {
        HStack {
            Text(prey.type.emoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(prey.type.displayName)
                    .font(.headline)
                
                HStack {
                    Text("HP: \(Int(prey.health))")
                        .font(.caption)
                    Text("•")
                    Text("Food: +\(Int(prey.type.hungerRestore))")
                        .font(.caption)
                    Text("•")
                    Text("XP: +\(prey.type.xpReward)")
                        .font(.caption)
                }
                .foregroundColor(.gray)
                
                // Difficulty stars
                HStack(spacing: 2) {
                    ForEach(0..<5) { i in
                        Text("⭐")
                            .font(.caption2)
                            .opacity(i < prey.type.difficultyTier ? 1.0 : 0.3)
                    }
                }
            }
            
            Spacer()
            
            Button(action: onHunt) {
                Text("🎯 HUNT")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(8)
            }
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StatusBar: View {
    let label: String
    let value: Double
    let maxValue: Double
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.white)
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(value / maxValue), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            Text("\(Int(value))")
                .font(.caption)
                .foregroundColor(.white)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct WorldActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(icon)
                    .font(.title)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(width: 70, height: 70)
            .background(Color.black.opacity(0.4))
            .cornerRadius(16)
        }
    }
}

// MARK: - CGFloat Extension for clamping

extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

struct NestBuilderView: View {
    @EnvironmentObject var gameState: GameState
    @ObservedObject var openWorld = OpenWorldManager.shared
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.15)
                .ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Button(action: { gameState.navigateTo(.openWorld) }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Text("🪺 Nest Builder")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding()
                
                if let nest = openWorld.homeNest {
                    // Nest info
                    VStack(spacing: 16) {
                        Text("Level \(nest.level) Nest")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        // Health bar
                        HStack {
                            Text("Health")
                                .foregroundColor(.gray)
                            ProgressView(value: nest.health, total: nest.maxHealth)
                                .tint(.green)
                        }
                        
                        // Storage
                        Text("Storage: \(nest.totalStoredItems)/\(nest.storageCapacity)")
                            .foregroundColor(.white)
                        
                        // Components
                        Text("\(nest.components.count) components built")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
                    .padding()
                    
                    // Build options
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(NestComponentType.allCases, id: \.self) { type in
                            BuildOptionCard(type: type) {
                                _ = openWorld.addNestComponent(type)
                            }
                        }
                    }
                    .padding()
                } else {
                    // Create nest button
                    VStack(spacing: 20) {
                        Text("🪺")
                            .font(.system(size: 80))
                        
                        Text("You don't have a nest yet!")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Button(action: { _ = openWorld.createNest() }) {
                            Text("Build Nest Here")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
}

struct BuildOptionCard: View {
    let type: NestComponentType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(type.emoji)
                    .font(.title)
                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                // Cost
                HStack(spacing: 4) {
                    ForEach(Array(type.requiredResources.keys), id: \.self) { resource in
                        Text("\(resource.emoji)\(type.requiredResources[resource]!)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Navigation Compatibility Wrapper

/// A wrapper that uses NavigationStack on iOS 16+ and falls back to NavigationView on earlier versions.
struct NavigationCompat<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
        }
    }
}

// MARK: - SceneKit View Representable for 3D Open World

/// SwiftUI wrapper for the SceneKit 3D open world scene
struct OpenWorld3DViewRepresentable: UIViewRepresentable {
    let scene: OpenWorld3DScene?
    let birdType: BirdType
    let openWorldManager: OpenWorldManager
    let joystickOffset: CGSize
    let altitude: Float
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .black
        scnView.allowsCameraControl = false
        scnView.showsStatistics = false
        scnView.antialiasingMode = .multisampling2X
        
        // Create scene if not provided
        let worldScene = scene ?? OpenWorld3DScene(birdType: birdType, manager: openWorldManager)
        scnView.scene = worldScene
        
        // Set up delegate for continuous updates
        scnView.delegate = context.coordinator
        scnView.isPlaying = true
        
        context.coordinator.scene = worldScene
        context.coordinator.openWorldManager = openWorldManager
        
        return scnView
    }
    
    func updateUIView(_ scnView: SCNView, context: Context) {
        guard let worldScene = scnView.scene as? OpenWorld3DScene else { return }
        
        // Update movement based on joystick
        if joystickOffset != .zero {
            let direction = WorldPosition(
                x: Double(joystickOffset.width) / 35.0,
                y: Double(joystickOffset.height) / 35.0,
                z: 0
            )
            worldScene.movePlayer(direction: direction, speed: 2.0)
            openWorldManager.move(direction: direction, speed: 1.0)
        }
        
        // Update altitude
        worldScene.setPlayerAltitude(altitude)
        
        // Update biome visuals
        worldScene.updateBiome(openWorldManager.playerState.currentBiome)
        
        // Update time of day
        worldScene.updateTimeOfDay(openWorldManager.timeOfDay)
        
        // Update prey, resources, and players
        worldScene.updatePrey(openWorldManager.nearbyPrey, huntingTarget: openWorldManager.huntingTarget)
        worldScene.updateResources(openWorldManager.nearbyResources)
        worldScene.updateOtherPlayers(openWorldManager.nearbyPlayers)
        worldScene.updateNest(openWorldManager.homeNest)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, SCNSceneRendererDelegate {
        var scene: OpenWorld3DScene?
        weak var openWorldManager: OpenWorldManager?
        
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            // Called every frame - can be used for continuous updates
            scene?.updateCamera()
        }
    }
}
