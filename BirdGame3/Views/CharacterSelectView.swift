//
//  CharacterSelectView.swift
//  BirdGame3
//
//  Choose your feathered warrior wisely
//

import SwiftUI

struct CharacterSelectView: View {
    @EnvironmentObject var gameState: GameState
    @State private var selectedIndex: Int = 0
    @State private var showStats = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.15, blue: 0.2),
                    Color(red: 0.15, green: 0.1, blue: 0.25)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("SELECT YOUR BIRD")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Text(gameModeSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                // Character carousel
                TabView(selection: $selectedIndex) {
                    ForEach(Array(BirdType.allCases.enumerated()), id: \.element.id) { index, bird in
                        CharacterCard(bird: bird, isSelected: gameState.selectedBird == bird)
                            .tag(index)
                            .onTapGesture {
                                withAnimation {
                                    gameState.selectedBird = bird
                                }
                            }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 400)
                .onChange(of: selectedIndex) { _, newValue in
                    gameState.selectedBird = BirdType.allCases[newValue]
                }
                
                // Opponent preview (if not training)
                if gameState.gameMode != .training {
                    VStack(spacing: 8) {
                        Text("VS")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        HStack {
                            Text(gameState.opponentBird.emoji)
                                .font(.system(size: 40))
                            
                            VStack(alignment: .leading) {
                                Text(gameState.opponentBird.displayName)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("CPU Opponent")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 20) {
                    Button(action: {
                        gameState.returnToMenu()
                    }) {
                        Text("← BACK")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 100, height: 50)
                            .background(Color.gray.opacity(0.5))
                            .cornerRadius(10)
                    }
                    .accessibilityLabel("Go back to main menu")
                    
                    Button(action: {
                        gameState.startBattle()
                    }) {
                        HStack {
                            Text("⚔️ FIGHT!")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(width: 180, height: 50)
                        .background(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                        .shadow(color: .red.opacity(0.5), radius: 8)
                    }
                    .accessibilityLabel("Start battle with \(gameState.selectedBird.displayName)")
                    .accessibilityHint("Double tap to begin the fight")
                }
                .padding(.bottom, 30)
            }
        }
    }
    
    private var gameModeSubtitle: String {
        switch gameState.gameMode {
        case .quickMatch:
            return "Quick Match - Random Opponent"
        case .arcade:
            return "Arcade Mode - Level \(gameState.arcadeLevel)"
        case .training:
            return "Training Mode - Practice Makes Perfect"
        }
    }
}

// MARK: - Character Card

struct CharacterCard: View {
    let bird: BirdType
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Bird emoji with glow
            ZStack {
                // Glow effect
                if isSelected {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.yellow.opacity(0.5), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                }
                
                Text(bird.emoji)
                    .font(.system(size: 80))
                    .accessibilityHidden(true)
            }
            
            // Name
            Text(bird.displayName)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Flavor text
            Text(bird.flavorText)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Stats
            VStack(spacing: 8) {
                StatBar(label: "❤️ HP", value: bird.baseStats.maxHealth, maxValue: 150, color: .red)
                StatBar(label: "⚔️ ATK", value: bird.baseStats.attack, maxValue: 20, color: .orange)
                StatBar(label: "🛡️ DEF", value: bird.baseStats.defense, maxValue: 15, color: .blue)
                StatBar(label: "⚡ SPD", value: bird.baseStats.speed, maxValue: 20, color: .green)
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
            
            // Ability
            VStack(spacing: 4) {
                Text("✨ \(bird.abilityName)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                
                Text(bird.abilityDescription)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            // Meme stats
            VStack(spacing: 2) {
                Text("📊 SECRET STATS 📊")
                    .font(.caption2)
                    .foregroundColor(.purple)
                
                HStack(spacing: 10) {
                    MemeStatBadge(label: "Feather Density", value: "\(bird.baseStats.featherDensity)")
                    MemeStatBadge(label: "Coo Power", value: bird.baseStats.cooPower)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 3)
                )
        )
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(bird.displayName), \(bird.flavorText). Health \(Int(bird.baseStats.maxHealth)), Attack \(Int(bird.baseStats.attack)), Defense \(Int(bird.baseStats.defense)), Speed \(Int(bird.baseStats.speed)). Special ability: \(bird.abilityName)")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

// MARK: - Stat Bar

struct StatBar: View {
    let label: String
    let value: Double
    let maxValue: Double
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.white)
                .frame(width: 60, alignment: .leading)
            
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

// MARK: - Meme Stat Badge

struct MemeStatBadge: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.purple)
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    CharacterSelectView()
        .environmentObject(GameState())
}
