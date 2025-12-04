//
//  MainMenuView.swift
//  BirdGame3
//
//  Welcome to the most epic bird combat game ever created
//

import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var gameState: GameState
    @State private var showingLoadingTips = false
    @State private var currentTip = ""
    @State private var titleScale: CGFloat = 1.0
    @State private var pigeonRotation: Double = 0
    
    private let loadingTips = [
        "Pro tip: Just spam pecks",
        "Hummingbird has been nerfed 47 times and is still OP",
        "Remember: Blocking is for cowards (but also smart)",
        "Pelican mains are built different",
        "If you lose, it's definitely lag",
        "Eagle mains are just pigeon mains in denial",
        "Crow players are legally required to be mysterious",
        "Did you know? Pigeons can't actually fly. They just fall with style.",
        "Loading actual bird facts... ERROR: No real facts found",
        "The devs are still trying to nerf hummingbird. They can't.",
        "Fun fact: This game was balanced by a goldfish",
        "Your rank means nothing. It's all about the pecks.",
        "Server hamster is running at maximum speed 🐹"
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.15, blue: 0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Floating birds in background
            ForEach(0..<5) { index in
                Text(["🐦", "🦅", "🦆", "🦜", "🕊️"][index])
                    .font(.system(size: 30))
                    .opacity(0.3)
                    .position(
                        x: CGFloat.random(in: 50...350),
                        y: CGFloat.random(in: 100...700)
                    )
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 3...5))
                            .repeatForever(autoreverses: true),
                        value: index
                    )
            }
            
            VStack(spacing: 20) {
                // Title
                VStack(spacing: 8) {
                    Text("🐦 BIRD GAME 3 🐦")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(titleScale)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                titleScale = 1.05
                            }
                        }
                    
                    Text("The Legendary Bird Combat Experience")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("v3.47.2 (hummingbird nerf edition)")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.6))
                }
                .padding(.top, 40)
                
                // Spinning pigeon mascot
                Text("🐦")
                    .font(.system(size: 80))
                    .rotationEffect(.degrees(pigeonRotation))
                    .onAppear {
                        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                            pigeonRotation = 360
                        }
                    }
                    .padding()
                
                // Fake online players
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("\(gameState.fakeOnlinePlayers.formatted()) players online")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.3))
                .cornerRadius(20)
                
                Spacer()
                
                // Menu buttons
                VStack(spacing: 16) {
                    MenuButton(title: "⚔️ QUICK MATCH", subtitle: "Fight a random opponent") {
                        showLoadingTip {
                            gameState.startQuickMatch()
                        }
                    }
                    
                    MenuButton(title: "🏆 ARCADE MODE", subtitle: "Climb the ranks!") {
                        showLoadingTip {
                            gameState.startArcade()
                        }
                    }
                    
                    MenuButton(title: "🎯 TRAINING", subtitle: "Git gud scrub") {
                        showLoadingTip {
                            gameState.startTraining()
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Fake stats footer
                VStack(spacing: 4) {
                    Text("Your Rank: \(gameState.playerStats.rank)")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    HStack(spacing: 20) {
                        StatBadge(label: "Wins", value: "\(gameState.playerStats.wins)")
                        StatBadge(label: "Losses", value: "\(gameState.playerStats.losses)")
                        StatBadge(label: "Ping", value: "\(gameState.fakeServerPing)ms")
                    }
                }
                .padding(.bottom, 30)
            }
            
            // Loading tip overlay
            if showingLoadingTips {
                LoadingTipOverlay(tip: currentTip)
            }
        }
    }
    
    private func showLoadingTip(completion: @escaping () -> Void) {
        currentTip = loadingTips.randomElement() ?? "Loading..."
        showingLoadingTips = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showingLoadingTips = false
            completion()
        }
    }
}

// MARK: - Menu Button

struct MenuButton: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .purple.opacity(0.5), radius: 8, x: 0, y: 4)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Loading Tip Overlay

struct LoadingTipOverlay: View {
    let tip: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("LOADING...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("💡 \(tip)")
                    .font(.subheadline)
                    .foregroundColor(.yellow)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

#Preview {
    MainMenuView()
        .environmentObject(GameState())
}
