//
//  ResultsView.swift
//  BirdGame3
//
//  The glorious aftermath of bird combat
//

import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var gameState: GameState
    @State private var showStats = false
    @State private var confettiOpacity: Double = 0
    @State private var showRewards = false
    @State private var showLevelUp = false
    
    private let victoryMessages = [
        "PIGEON MAINS RISE UP! 🐦",
        "GG EZ NO RE",
        "That bird got absolutely COOKED 🔥",
        "The prophecy has been fulfilled",
        "Your opponent has left the chat",
        "Built different fr fr",
        "Skill diff tbh",
        "Get pecked on 🐦💨",
        "They weren't ready for the bird meta",
        "Report opponent for feeding"
    ]
    
    private let defeatMessages = [
        "gg go next",
        "Lag diff 100%",
        "My little brother was playing",
        "Controller died mid-match",
        "Just warming up tbh",
        "Nerf that bird pls devs",
        "I wasn't even trying",
        "You're sweating in a bird game??",
        "Mom made me stop playing",
        "That was just practice"
    ]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: gameState.playerWon ?
                    [Color.green.opacity(0.3), Color.blue.opacity(0.3)] :
                    [Color.red.opacity(0.3), Color.purple.opacity(0.3)]
                ),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Confetti for victory
            if gameState.playerWon {
                ConfettiView()
                    .opacity(confettiOpacity)
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    // Result header
                    VStack(spacing: 10) {
                        Text(gameState.playerWon ? "🎉 VICTORY! 🎉" : "💀 DEFEAT 💀")
                            .font(.system(size: 36, weight: .heavy))
                            .foregroundColor(gameState.playerWon ? .green : .red)
                        
                        Text(gameState.playerWon ?
                             (victoryMessages.randomElement() ?? "You won!") :
                             (defeatMessages.randomElement() ?? "Better luck next time!"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 30)
                    
                    // Battle summary
                    VStack(spacing: 16) {
                        HStack(spacing: 40) {
                            // Player
                            VStack {
                                Text(gameState.selectedBird.emoji)
                                    .font(.system(size: 50))
                                Text(gameState.selectedBird.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Text(gameState.playerWon ? "WINNER" : "")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .fontWeight(.bold)
                            }
                            
                            Text("VS")
                                .font(.title)
                                .foregroundColor(.gray)
                            
                            // Opponent
                            VStack {
                                Text(gameState.opponentBird.emoji)
                                    .font(.system(size: 50))
                                Text(gameState.opponentBird.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Text(!gameState.playerWon ? "WINNER" : "")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(16)
                    
                    // Rewards section
                    if let reward = gameState.lastBattleReward {
                        RewardsCardView(reward: reward)
                            .opacity(showRewards ? 1 : 0)
                            .offset(y: showRewards ? 0 : 20)
                    }
                    
                    // Level up section
                    if !gameState.levelUpRewards.isEmpty {
                        LevelUpCardView(rewards: gameState.levelUpRewards)
                            .opacity(showLevelUp ? 1 : 0)
                            .offset(y: showLevelUp ? 0 : 20)
                    }
                    
                    // Stats
                    VStack(spacing: 12) {
                        Text("📊 MATCH STATS 📊")
                            .font(.headline)
                            .foregroundColor(.yellow)
                        
                        HStack(spacing: 30) {
                            ResultStatBox(label: "Duration", value: formatTime(gameState.lastMatchDuration))
                            ResultStatBox(label: "Damage Dealt", value: "\(Int(gameState.lastMatchDamageDealt))")
                            ResultStatBox(label: "Damage Taken", value: "\(Int(gameState.lastMatchDamageReceived))")
                        }
                        
                        // Fake bonus stats
                        Divider()
                            .background(Color.gray)
                        
                        HStack(spacing: 20) {
                            MemeResultStat(label: "Style Points", value: "\(Int.random(in: 1000...9999))")
                            MemeResultStat(label: "Pecks Per Minute", value: "\(Int.random(in: 50...200))")
                            MemeResultStat(label: "Feathers Lost", value: "\(Int.random(in: 3...47))")
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(16)
                    
                    // Rank update
                    VStack(spacing: 8) {
                        Text("Current Rank")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(gameState.playerStats.rank)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                        
                        // Level progress
                        HStack {
                            Text(PrestigeManager.shared.displayLevel)
                                .font(.caption)
                                .foregroundColor(.purple)
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [.purple, .pink],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * PrestigeManager.shared.levelProgress, height: 6)
                                }
                            }
                            .frame(height: 6)
                            .frame(width: 100)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(12)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            gameState.playAgain()
                        }) {
                            HStack {
                                Text("🔄 PLAY AGAIN")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            gameState.navigateTo(.characterSelect)
                        }) {
                            Text("🐦 CHANGE CHARACTER")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.5))
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            gameState.returnToMenu()
                        }) {
                            Text("🏠 MAIN MENU")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            animateAppearance()
        }
    }
    
    private func animateAppearance() {
        if gameState.playerWon {
            withAnimation(.easeIn(duration: 0.5)) {
                confettiOpacity = 1
            }
        }
        
        // Staggered animations for rewards
        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            showRewards = true
        }
        
        withAnimation(.easeOut(duration: 0.4).delay(0.6)) {
            showLevelUp = true
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Rewards Card View

struct RewardsCardView: View {
    let reward: BattleReward
    
    var body: some View {
        VStack(spacing: 12) {
            Text("💰 REWARDS 💰")
                .font(.headline)
                .foregroundColor(.yellow)
            
            HStack(spacing: 30) {
                // Coins earned
                VStack(spacing: 4) {
                    Text("🪙")
                        .font(.title)
                    Text("+\(reward.coins)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                    Text("Coins")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Feathers earned (if any)
                if reward.feathers > 0 {
                    VStack(spacing: 4) {
                        Text("🪶")
                            .font(.title)
                        Text("+\(reward.feathers)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.cyan)
                        Text("Feathers")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Bonus breakdown
            if reward.hasBonus {
                VStack(spacing: 4) {
                    ForEach(reward.bonuses, id: \.self) { bonus in
                        Text("✨ \(bonus)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Level Up Card View

struct LevelUpCardView: View {
    let rewards: [LevelUpReward]
    
    var body: some View {
        VStack(spacing: 12) {
            Text("⬆️ LEVEL UP! ⬆️")
                .font(.headline)
                .foregroundColor(.purple)
            
            ForEach(rewards, id: \.level) { reward in
                VStack(spacing: 8) {
                    Text("Level \(reward.level)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 16) {
                        Text("🪙 +\(reward.coins)")
                            .font(.subheadline)
                            .foregroundColor(.yellow)
                        
                        if reward.feathers > 0 {
                            Text("🪶 +\(reward.feathers)")
                                .font(.subheadline)
                                .foregroundColor(.cyan)
                        }
                    }
                    
                    if reward.hasSkin, let skinId = reward.skinUnlock {
                        HStack {
                            Text("🎨 Skin Unlocked!")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Result Stat Box

struct ResultStatBox: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Meme Result Stat

struct MemeResultStat: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .foregroundColor(.purple)
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<30) { index in
                ConfettiPiece(
                    emoji: ["🎉", "🐦", "✨", "🏆", "🪶", "⭐"][index % 6],
                    startX: CGFloat.random(in: 0...geometry.size.width),
                    animate: animate
                )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct ConfettiPiece: View {
    let emoji: String
    let startX: CGFloat
    let animate: Bool
    
    @State private var yOffset: CGFloat = -50
    @State private var rotation: Double = 0
    
    var body: some View {
        Text(emoji)
            .font(.system(size: CGFloat.random(in: 15...30)))
            .position(x: startX, y: yOffset)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: Double.random(in: 2...4))) {
                    yOffset = UIScreen.main.bounds.height + 50
                    rotation = Double.random(in: 360...720)
                }
            }
    }
}

#Preview {
    ResultsView()
        .environmentObject({
            let state = GameState()
            state.playerWon = true
            state.lastMatchDuration = 45
            state.lastMatchDamageDealt = 150
            state.lastMatchDamageReceived = 80
            return state
        }())
}
