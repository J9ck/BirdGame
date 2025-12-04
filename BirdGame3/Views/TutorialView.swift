//
//  TutorialView.swift
//  BirdGame3
//
//  Onboarding tutorial for first-time players
//

import SwiftUI

struct TutorialView: View {
    @EnvironmentObject var gameState: GameState
    @State private var currentPage = 0
    @Binding var showTutorial: Bool
    
    private let tutorialPages: [TutorialPage] = [
        TutorialPage(
            title: "Welcome to Bird Game 3! 🐦",
            subtitle: "The most legendary bird combat experience",
            emoji: "🎮",
            description: "There is no Bird Game 1 or 2. Only 3. Accept this truth and become a bird warrior.",
            tips: [
                "Choose your feathered fighter wisely",
                "Each bird has unique abilities",
                "The pigeon is NOT weak (trust)"
            ]
        ),
        TutorialPage(
            title: "Master the Controls 🕹️",
            subtitle: "Wolf-style combat at your fingertips",
            emoji: "👆",
            description: "Use the virtual joystick on the left to move your bird around the arena.",
            tips: [
                "Joystick controls 360° movement",
                "Tap ATTACK to peck your opponent",
                "Hold BLOCK to reduce damage",
                "SPRINT for quick bursts of speed"
            ]
        ),
        TutorialPage(
            title: "Special Abilities ✨",
            subtitle: "Unleash your bird's true power",
            emoji: "⚡",
            description: "Every bird has a unique special ability. Use it wisely - it has a cooldown!",
            tips: [
                "Tap the ability button when ready",
                "Watch for the cooldown timer",
                "Abilities can turn the tide of battle",
                "Practice timing in Training mode"
            ]
        ),
        TutorialPage(
            title: "Earn Rewards 💰",
            subtitle: "Get paid to peck",
            emoji: "🏆",
            description: "Win battles to earn coins and feathers. Use them to unlock epic skins!",
            tips: [
                "🪙 Coins: Win battles, complete challenges",
                "🪶 Feathers: Premium currency for rare items",
                "Level up for bonus rewards",
                "Prestige for permanent bonuses"
            ]
        ),
        TutorialPage(
            title: "Ready to Fight? ⚔️",
            subtitle: "The arena awaits",
            emoji: "🔥",
            description: "You're all set! Choose Quick Match for random opponents or Arcade Mode to climb the ranks.",
            tips: [
                "Quick Match: Fight random opponents",
                "Arcade Mode: Progressive difficulty",
                "Training: Practice without pressure",
                "Good luck, bird warrior! 🐦"
            ]
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.2, green: 0.1, blue: 0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: completeTutorial) {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
                
                // Tutorial content
                TabView(selection: $currentPage) {
                    ForEach(Array(tutorialPages.enumerated()), id: \.offset) { index, page in
                        TutorialPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                
                // Navigation buttons
                HStack(spacing: 20) {
                    // Previous button
                    Button(action: previousPage) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(currentPage > 0 ? .white : .gray)
                            .frame(width: 50, height: 50)
                            .background(currentPage > 0 ? Color.blue.opacity(0.5) : Color.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .disabled(currentPage == 0)
                    
                    Spacer()
                    
                    // Page indicator text
                    Text("\(currentPage + 1) / \(tutorialPages.count)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // Next/Done button
                    Button(action: nextOrComplete) {
                        Group {
                            if currentPage < tutorialPages.count - 1 {
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                            } else {
                                Text("Let's Go!")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(minWidth: 50, minHeight: 50)
                        .padding(.horizontal, currentPage < tutorialPages.count - 1 ? 0 : 20)
                        .background(
                            currentPage < tutorialPages.count - 1 ?
                            AnyShapeStyle(Color.blue.opacity(0.5)) :
                            AnyShapeStyle(LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing))
                        )
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
        }
    }
    
    private func previousPage() {
        withAnimation {
            currentPage = max(0, currentPage - 1)
        }
    }
    
    private func nextOrComplete() {
        if currentPage < tutorialPages.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            completeTutorial()
        }
    }
    
    private func completeTutorial() {
        UserDefaults.standard.set(true, forKey: "birdgame3_tutorialCompleted")
        showTutorial = false
    }
}

// MARK: - Tutorial Page Model

struct TutorialPage {
    let title: String
    let subtitle: String
    let emoji: String
    let description: String
    let tips: [String]
}

// MARK: - Tutorial Page View

struct TutorialPageView: View {
    let page: TutorialPage
    
    var body: some View {
        VStack(spacing: 20) {
            // Emoji
            Text(page.emoji)
                .font(.system(size: 80))
                .padding(.top, 20)
            
            // Title
            Text(page.title)
                .font(.title)
                .fontWeight(.heavy)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Subtitle
            Text(page.subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // Description
            Text(page.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            // Tips
            VStack(alignment: .leading, spacing: 12) {
                ForEach(page.tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 10) {
                        Text("•")
                            .foregroundColor(.yellow)
                            .fontWeight(.bold)
                        Text(tip)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(16)
            .padding(.horizontal, 30)
            
            Spacer()
        }
    }
}

#Preview {
    TutorialView(showTutorial: .constant(true))
        .environmentObject(GameState())
}
