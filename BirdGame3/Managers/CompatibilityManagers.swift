//
//  Untitled.swift
//  BirdGame3
//
//  Created by Jack Doyle on 12/4/25.
//

import Foundation
import UIKit

/// Small compatibility shims for missing managers used by OpenWorldManager.
/// These provide lightweight, safe implementations so the app will compile and run.
/// Replace these with your full implementations later if needed.

final class AchievementManager {
    static let shared = AchievementManager()
    private init() {}

    private let discoveredAchievementsKey = "birdgame3_discovered_achievements"

    private var unlocked: Set<String> {
        get {
            let arr = UserDefaults.standard.stringArray(forKey: discoveredAchievementsKey) ?? []
            return Set(arr)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: discoveredAchievementsKey)
        }
    }

    func trackBowlingAlleyVisit(asCrow: Bool) {
        // Example behavior: record a specific achievement id.
        // If asCrow is true, unlock a special crow badge.
        let id = asCrow ? "track_bowling_alley_crow" : "track_bowling_alley"
        unlockBadge(id)
        print("[AchievementManager] Tracked bowling alley visit (asCrow: \(asCrow))")
    }

    func trackChairBNBVisit() {
        let id = "track_chairbnb_visit"
        unlockBadge(id)
        print("[AchievementManager] Tracked ChairBNB visit")
    }

    func unlockBadge(_ badgeId: String) {
        var s = unlocked
        if !s.contains(badgeId) {
            s.insert(badgeId)
            unlocked = s
            // Post a notification so UI can respond if desired
            NotificationCenter.default.post(name: .achievementUnlocked, object: nil, userInfo: ["badgeId": badgeId])
            // Light haptic feedback to match discovery behavior
            DispatchQueue.main.async {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
            print("[AchievementManager] Unlocked badge: \(badgeId)")
        } else {
            print("[AchievementManager] Badge already unlocked: \(badgeId)")
        }
    }

    func hasUnlocked(_ badgeId: String) -> Bool {
        unlocked.contains(badgeId)
    }
}

final class ProfileIconManager {
    static let shared = ProfileIconManager()
    private init() {}

    private let unlockedIconsKey = "birdgame3_unlocked_icons"

    private var unlockedIcons: Set<String> {
        get {
            let arr = UserDefaults.standard.stringArray(forKey: unlockedIconsKey) ?? []
            return Set(arr)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: unlockedIconsKey)
        }
    }

    func unlockIcon(_ iconId: String) {
        var s = unlockedIcons
        guard !s.contains(iconId) else {
            print("[ProfileIconManager] Icon already unlocked: \(iconId)")
            return
        }
        s.insert(iconId)
        unlockedIcons = s
        NotificationCenter.default.post(name: .profileIconUnlocked, object: nil, userInfo: ["iconId": iconId])
        print("[ProfileIconManager] Unlocked icon: \(iconId)")
    }

    func isIconUnlocked(_ iconId: String) -> Bool {
        unlockedIcons.contains(iconId)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let achievementUnlocked = Notification.Name("BirdGame3.AchievementUnlocked")
    static let profileIconUnlocked = Notification.Name("BirdGame3.ProfileIconUnlocked")
}
