//
//  BirdGame3App.swift
//  BirdGame3
//
//  The iconic Bird Game 3 - where pigeons rise up and hummingbirds are still OP
//

import SwiftUI

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
            NavigationStack {
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

// MARK: - Placeholder Views for new screens

struct OpenWorldView: View {
    @EnvironmentObject var gameState: GameState
    @ObservedObject var openWorld = OpenWorldManager.shared
    @ObservedObject var voiceChat = LiveVoiceChatManager.shared
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.4, blue: 0.6),
                    Color(red: 0.1, green: 0.2, blue: 0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                // Top HUD
                HStack {
                    // Back button
                    Button(action: { gameState.navigateTo(.mainMenu) }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Biome & Weather
                    VStack(spacing: 4) {
                        HStack {
                            Text(openWorld.playerState.currentBiome.emoji)
                            Text(openWorld.playerState.currentBiome.displayName)
                                .font(.headline)
                        }
                        HStack {
                            Text(openWorld.currentWeather.emoji)
                            Text(openWorld.timeOfDay.emoji)
                        }
                        .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    // Inventory
                    Button(action: {}) {
                        VStack {
                            Image(systemName: "bag.fill")
                            Text("\(openWorld.playerState.inventoryCount)/\(openWorld.playerState.maxInventory)")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(12)
                    }
                }
                .padding()
                
                Spacer()
                
                // Status bars
                VStack(spacing: 8) {
                    StatusBar(label: "❤️ Health", value: openWorld.playerState.health, maxValue: 100, color: .red)
                    StatusBar(label: "🍖 Hunger", value: openWorld.playerState.hunger, maxValue: 100, color: .orange)
                    StatusBar(label: "⚡ Energy", value: openWorld.playerState.energy, maxValue: 100, color: .yellow)
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(16)
                .padding()
                
                // World info
                Text("🌍 Open World - \(openWorld.nearbyPlayers.count) players nearby")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding()
                
                // Action buttons
                HStack(spacing: 20) {
                    WorldActionButton(icon: "🪺", label: "Nest") {
                        gameState.navigateTo(.nestBuilder)
                    }
                    
                    WorldActionButton(icon: "🔍", label: "Scan") {
                        // Scan for resources
                    }
                    
                    WorldActionButton(icon: "🗺️", label: "Map") {
                        // Open map
                    }
                }
                .padding(.bottom, 30)
            }
            
            // Voice chat overlay
            VoiceChatOverlay()
        }
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
