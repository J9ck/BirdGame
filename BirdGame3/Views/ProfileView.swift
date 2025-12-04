//
//  ProfileView.swift
//  BirdGame3
//
//  Player profile with stats and badge display
//

import SwiftUI
import GameKit

struct ProfileView: View {
    @EnvironmentObject var gameState: GameState
    @ObservedObject var account = AccountManager.shared
    @ObservedObject var achievements = AchievementManager.shared
    @ObservedObject var prestige = PrestigeManager.shared
    @ObservedObject var currency = CurrencyManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showBadgeSelector = false
    @State private var selectedBadgeSlot: Int?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.1, blue: 0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header
                        profileHeader
                        
                        // Stats section
                        statsSection
                        
                        // Equipped badges
                        badgesSection
                        
                        // Game Center button
                        gameCenterSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showBadgeSelector) {
            BadgeSelectorView(selectedSlot: $selectedBadgeSlot)
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Text(gameState.selectedBird.emoji)
                    .font(.system(size: 50))
                
                // Level badge
                Text("\(prestige.displayLevel)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple)
                    .cornerRadius(10)
                    .offset(y: 45)
            }
            
            // Username
            VStack(spacing: 4) {
                Text(account.currentAccount?.displayName ?? "Guest")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let friendCode = account.currentAccount?.friendCode {
                    HStack(spacing: 4) {
                        Text("Friend Code:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(friendCode)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.cyan)
                    }
                }
            }
            
            // Currency display
            HStack(spacing: 20) {
                CurrencyPill(icon: "🪙", amount: currency.coins, color: .yellow)
                CurrencyPill(icon: "🪶", amount: currency.feathers, color: .cyan)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 Statistics")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Wins", value: "\(gameState.playerStats.wins)", icon: "🏆")
                StatCard(title: "Losses", value: "\(gameState.playerStats.losses)", icon: "💀")
                StatCard(title: "Win Rate", value: "\(winRate)%", icon: "📈")
                StatCard(title: "Total Battles", value: "\(totalBattles)", icon: "⚔️")
                StatCard(title: "Current Rank", value: gameState.playerStats.rank, icon: "🎖️")
                StatCard(title: "Arcade Stage", value: "\(gameState.playerStats.highestArcadeStage)", icon: "🎮")
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
    }
    
    private var winRate: Int {
        let total = gameState.playerStats.wins + gameState.playerStats.losses
        guard total > 0 else { return 0 }
        return Int((Double(gameState.playerStats.wins) / Double(total)) * 100)
    }
    
    private var totalBattles: Int {
        gameState.playerStats.wins + gameState.playerStats.losses
    }
    
    // MARK: - Badges Section
    
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🎖️ Badges")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(achievements.unlockedCount)/\(achievements.totalCount) unlocked")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Equipped badges (up to 3)
            HStack(spacing: 16) {
                ForEach(0..<3) { index in
                    BadgeSlot(
                        badge: index < achievements.equippedBadges.count ? achievements.equippedBadges[index] : nil,
                        onTap: {
                            selectedBadgeSlot = index
                            showBadgeSelector = true
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity)
            
            // View all badges button
            Button(action: { showBadgeSelector = true }) {
                HStack {
                    Image(systemName: "square.grid.3x3")
                    Text("View All Badges")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 8)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
    }
    
    // MARK: - Game Center Section
    
    private var gameCenterSection: some View {
        VStack(spacing: 12) {
            if achievements.isGameCenterEnabled {
                HStack {
                    Image(systemName: "gamecontroller.fill")
                        .foregroundColor(.green)
                    Text("Game Center Connected")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                
                Button(action: { achievements.showGameCenterAchievements() }) {
                    HStack {
                        Image(systemName: "trophy.fill")
                        Text("View Game Center Achievements")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple.opacity(0.3))
                    .cornerRadius(12)
                }
            } else {
                HStack {
                    Image(systemName: "gamecontroller")
                        .foregroundColor(.gray)
                    Text("Game Center Not Connected")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Button(action: { achievements.authenticateGameCenter() }) {
                    Text("Connect to Game Center")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
    }
}

// MARK: - Supporting Views

struct CurrencyPill: View {
    let icon: String
    let amount: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Text(icon)
            Text("\(amount)")
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(20)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.title2)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct BadgeSlot: View {
    let badge: ProfileBadge?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(badge != nil ? badge!.rarity.color.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                if let badge = badge {
                    VStack(spacing: 4) {
                        Text(badge.icon)
                            .font(.title)
                        Text(badge.name)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "plus.circle.dashed")
                            .font(.title)
                            .foregroundColor(.gray)
                        Text("Add Badge")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

// MARK: - Badge Selector View

struct BadgeSelectorView: View {
    @Binding var selectedSlot: Int?
    @ObservedObject var achievements = AchievementManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.1)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(achievements.badges) { badge in
                            BadgeCard(badge: badge) {
                                if badge.isUnlocked {
                                    if badge.isEquipped {
                                        achievements.unequipBadge(badge)
                                    } else {
                                        achievements.equipBadge(badge)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Badge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct BadgeCard: View {
    let badge: ProfileBadge
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(badge.isUnlocked ? badge.rarity.color.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(height: 80)
                    
                    if badge.isUnlocked {
                        Text(badge.icon)
                            .font(.system(size: 40))
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                    
                    // Equipped indicator
                    if badge.isEquipped {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .background(Circle().fill(.white).padding(2))
                            }
                            Spacer()
                        }
                        .padding(6)
                    }
                }
                
                Text(badge.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(badge.isUnlocked ? .white : .gray)
                    .lineLimit(1)
                
                Text(badge.rarity.displayName)
                    .font(.caption2)
                    .foregroundColor(badge.rarity.color)
            }
            .opacity(badge.isUnlocked ? 1.0 : 0.5)
        }
        .disabled(!badge.isUnlocked)
    }
}

// MARK: - Account Profile View (for Main Menu sheet)

struct AccountProfileView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ProfileView()
    }
}

#Preview {
    ProfileView()
        .environmentObject(GameState())
}
