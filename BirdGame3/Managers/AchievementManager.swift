//
//  AchievementManager.swift
//  BirdGame3
//
//  Profile badges and Game Center achievements integration
//

import Foundation
import SwiftUI
import GameKit

// MARK: - Profile Badge

struct ProfileBadge: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let rarity: BadgeRarity
    var isUnlocked: Bool
    var unlockedDate: Date?
    var isEquipped: Bool
    
    static func == (lhs: ProfileBadge, rhs: ProfileBadge) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Badge Rarity

enum BadgeRarity: String, Codable, CaseIterable {
    case common
    case rare
    case epic
    case legendary
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

// MARK: - Game Center Achievement IDs

enum GameCenterAchievement: String, CaseIterable {
    case firstWin = "com.birdgame3.first_win"
    case wins10 = "com.birdgame3.wins_10"
    case wins100 = "com.birdgame3.wins_100"
    case firstNest = "com.birdgame3.first_nest"
    case firstFriend = "com.birdgame3.first_friend"
    case level25 = "com.birdgame3.level_25"
    case level50 = "com.birdgame3.level_50"
    case prestige1 = "com.birdgame3.prestige_1"
    case allBirds = "com.birdgame3.all_birds"
    case perfectMatch = "com.birdgame3.perfect_match"
    
    var displayName: String {
        switch self {
        case .firstWin: return "First Victory"
        case .wins10: return "Skilled Fighter"
        case .wins100: return "Battle Master"
        case .firstNest: return "Home Builder"
        case .firstFriend: return "Social Bird"
        case .level25: return "Experienced"
        case .level50: return "Maxed Out"
        case .prestige1: return "Prestige"
        case .allBirds: return "Bird Collector"
        case .perfectMatch: return "Flawless Victory"
        }
    }
}

// MARK: - Achievement Manager

class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    // MARK: - Published Properties
    
    @Published var badges: [ProfileBadge] = []
    @Published var equippedBadges: [ProfileBadge] = []
    @Published var isGameCenterEnabled: Bool = false
    @Published var gameCenterPlayer: GKLocalPlayer?
    
    // MARK: - Private Properties
    
    private let maxEquippedBadges = 3
    private let badgesSaveKey = "birdgame3_badges"
    
    // MARK: - Initialization
    
    private init() {
        loadBadges()
        authenticateGameCenter()
    }
    
    // MARK: - Game Center Authentication
    
    func authenticateGameCenter() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            DispatchQueue.main.async {
                if GKLocalPlayer.local.isAuthenticated {
                    self?.isGameCenterEnabled = true
                    self?.gameCenterPlayer = GKLocalPlayer.local
                } else {
                    self?.isGameCenterEnabled = false
                    self?.gameCenterPlayer = nil
                }
            }
        }
    }
    
    // MARK: - Game Center Achievement Reporting
    
    func reportAchievement(_ achievement: GameCenterAchievement, percentComplete: Double = 100.0) {
        guard isGameCenterEnabled else { return }
        
        let gcAchievement = GKAchievement(identifier: achievement.rawValue)
        gcAchievement.percentComplete = percentComplete
        gcAchievement.showsCompletionBanner = true
        
        GKAchievement.report([gcAchievement]) { error in
            if let error = error {
                print("Failed to report achievement: \(error.localizedDescription)")
            }
        }
    }
    
    func showGameCenterAchievements() {
        guard isGameCenterEnabled else { return }
        
        let gcViewController = GKGameCenterViewController(state: .achievements)
        gcViewController.gameCenterDelegate = GameCenterDelegate.shared
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(gcViewController, animated: true)
        }
    }
    
    // MARK: - Badge Management
    
    func unlockBadge(_ badgeId: String) {
        guard let index = badges.firstIndex(where: { $0.id == badgeId && !$0.isUnlocked }) else { return }
        
        badges[index].isUnlocked = true
        badges[index].unlockedDate = Date()
        saveBadges()
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Voice announcement
        VoiceChatManager.shared.speak("New badge unlocked: \(badges[index].name)!", priority: .high)
    }
    
    func equipBadge(_ badge: ProfileBadge) {
        guard badge.isUnlocked else { return }
        
        // Unequip if already at max
        if equippedBadges.count >= maxEquippedBadges {
            if let firstEquipped = equippedBadges.first,
               let index = badges.firstIndex(where: { $0.id == firstEquipped.id }) {
                badges[index].isEquipped = false
            }
            equippedBadges.removeFirst()
        }
        
        if let index = badges.firstIndex(where: { $0.id == badge.id }) {
            badges[index].isEquipped = true
            equippedBadges.append(badges[index])
        }
        
        saveBadges()
    }
    
    func unequipBadge(_ badge: ProfileBadge) {
        if let index = badges.firstIndex(where: { $0.id == badge.id }) {
            badges[index].isEquipped = false
        }
        equippedBadges.removeAll { $0.id == badge.id }
        saveBadges()
    }
    
    // MARK: - Track Game Events
    
    func trackWin(totalWins: Int) {
        // Game Center achievements
        if totalWins == 1 {
            reportAchievement(.firstWin)
            unlockBadge("badge_first_win")
        }
        if totalWins >= 10 {
            reportAchievement(.wins10)
            unlockBadge("badge_veteran")
        }
        if totalWins >= 100 {
            reportAchievement(.wins100)
            unlockBadge("badge_master")
        }
    }
    
    func trackNestBuilt() {
        reportAchievement(.firstNest)
        unlockBadge("badge_builder")
    }
    
    func trackFriendAdded(totalFriends: Int) {
        if totalFriends == 1 {
            reportAchievement(.firstFriend)
            unlockBadge("badge_social")
        }
    }
    
    func trackLevelUp(level: Int) {
        if level >= 25 {
            reportAchievement(.level25)
            unlockBadge("badge_experienced")
        }
        if level >= 50 {
            reportAchievement(.level50)
            unlockBadge("badge_maxed")
        }
    }
    
    func trackPrestige(level: Int) {
        if level >= 1 {
            reportAchievement(.prestige1)
            unlockBadge("badge_prestige")
        }
    }
    
    func trackPerfectWin() {
        reportAchievement(.perfectMatch)
        unlockBadge("badge_flawless")
    }
    
    // MARK: - Hidden Location Achievements
    
    /// Track when player visits the bowling alley as a crow
    func trackBowlingAlleyVisit(asCrow: Bool) {
        if asCrow {
            unlockBadge("badge_bowling_crow")
            // This is a hidden achievement - unlock silently then announce
            VoiceChatManager.shared.speak("Secret found! The crow at the bowling alley!", priority: .high)
        }
    }
    
    /// Track when player visits the CHairBNB location
    func trackChairBNBVisit() {
        unlockBadge("badge_chairbnb")
        VoiceChatManager.shared.speak("Easter egg found! Welcome to CHairBNB!", priority: .high)
    }
    
    // MARK: - Persistence
    
    private func saveBadges() {
        if let data = try? JSONEncoder().encode(badges) {
            UserDefaults.standard.set(data, forKey: badgesSaveKey)
        }
        updateEquippedBadges()
    }
    
    private func loadBadges() {
        if let data = UserDefaults.standard.data(forKey: badgesSaveKey),
           let saved = try? JSONDecoder().decode([ProfileBadge].self, from: data) {
            badges = saved
        } else {
            badges = createDefaultBadges()
            saveBadges()
        }
        updateEquippedBadges()
    }
    
    private func updateEquippedBadges() {
        equippedBadges = badges.filter { $0.isEquipped }
    }
    
    // MARK: - Default Badges
    
    private func createDefaultBadges() -> [ProfileBadge] {
        return [
            // Combat badges
            ProfileBadge(id: "badge_first_win", name: "First Victory", icon: "🏆", description: "Won your first battle", rarity: .common, isUnlocked: false, unlockedDate: nil, isEquipped: false),
            ProfileBadge(id: "badge_veteran", name: "Veteran", icon: "⚔️", description: "Won 10 battles", rarity: .rare, isUnlocked: false, unlockedDate: nil, isEquipped: false),
            ProfileBadge(id: "badge_master", name: "Battle Master", icon: "👑", description: "Won 100 battles", rarity: .legendary, isUnlocked: false, unlockedDate: nil, isEquipped: false),
            ProfileBadge(id: "badge_flawless", name: "Flawless", icon: "💯", description: "Won without taking damage", rarity: .epic, isUnlocked: false, unlockedDate: nil, isEquipped: false),
            
            // Progression badges
            ProfileBadge(id: "badge_experienced", name: "Experienced", icon: "📊", description: "Reached level 25", rarity: .rare, isUnlocked: false, unlockedDate: nil, isEquipped: false),
            ProfileBadge(id: "badge_maxed", name: "Maxed Out", icon: "🔥", description: "Reached level 50", rarity: .epic, isUnlocked: false, unlockedDate: nil, isEquipped: false),
            ProfileBadge(id: "badge_prestige", name: "Prestige", icon: "⭐", description: "Reached Prestige 1", rarity: .legendary, isUnlocked: false, unlockedDate: nil, isEquipped: false),
            
            // Social badges
            ProfileBadge(id: "badge_social", name: "Social Bird", icon: "🤝", description: "Added your first friend", rarity: .common, isUnlocked: false, unlockedDate: nil, isEquipped: false),
            ProfileBadge(id: "badge_builder", name: "Architect", icon: "🪺", description: "Built your first nest", rarity: .common, isUnlocked: false, unlockedDate: nil, isEquipped: false),
            
            // Special badges
            ProfileBadge(id: "badge_founder", name: "Founder", icon: "🏛️", description: "Played during launch week", rarity: .legendary, isUnlocked: false, unlockedDate: nil, isEquipped: false),
            ProfileBadge(id: "badge_supporter", name: "Supporter", icon: "💎", description: "Made a purchase", rarity: .epic, isUnlocked: false, unlockedDate: nil, isEquipped: false),
            
            // Bird badges
            ProfileBadge(id: "badge_pigeon", name: "Pigeon Pro", icon: "🐦", description: "Won 25 battles as Pigeon", rarity: .rare, isUnlocked: false, unlockedDate: nil, isEquipped: false),
            ProfileBadge(id: "badge_eagle", name: "Eagle Eye", icon: "🦅", description: "Won 25 battles as Eagle", rarity: .rare, isUnlocked: false, unlockedDate: nil, isEquipped: false),
            ProfileBadge(id: "badge_crow", name: "Crow Master", icon: "🐦‍⬛", description: "Won 25 battles as Crow", rarity: .rare, isUnlocked: false, unlockedDate: nil, isEquipped: false),
            ProfileBadge(id: "badge_hummingbird", name: "Speed Demon", icon: "🪶", description: "Won 25 battles as Hummingbird", rarity: .rare, isUnlocked: false, unlockedDate: nil, isEquipped: false),
            ProfileBadge(id: "badge_pelican", name: "Pelican Power", icon: "🦤", description: "Won 25 battles as Pelican", rarity: .rare, isUnlocked: false, unlockedDate: nil, isEquipped: false),
            
            // HIDDEN BADGES - Easter Eggs
            ProfileBadge(id: "badge_bowling_crow", name: "Strike!", icon: "🎳", description: "???", rarity: .legendary, isUnlocked: false, unlockedDate: nil, isEquipped: false),
            ProfileBadge(id: "badge_chairbnb", name: "CHairBNB Guest", icon: "🪑", description: "???", rarity: .legendary, isUnlocked: false, unlockedDate: nil, isEquipped: false),
        ]
    }
    
    // MARK: - Stats
    
    var unlockedCount: Int {
        badges.filter { $0.isUnlocked }.count
    }
    
    var totalCount: Int {
        badges.count
    }
}

// MARK: - Game Center Delegate

class GameCenterDelegate: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterDelegate()
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
