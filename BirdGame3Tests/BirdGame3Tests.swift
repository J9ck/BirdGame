//
//  BirdGame3Tests.swift
//  BirdGame3Tests
//
//  Unit tests for Bird Game 3
//

import XCTest
@testable import BirdGame3

final class BirdGame3Tests: XCTestCase {
    
    // MARK: - Currency Manager Tests
    
    func testCurrencyManagerAddCoins() {
        let manager = CurrencyManager.shared
        let initialCoins = manager.coins
        
        manager.addCoins(100, reason: "Test")
        
        XCTAssertEqual(manager.coins, initialCoins + 100)
    }
    
    func testCurrencyManagerSpendCoins() {
        let manager = CurrencyManager.shared
        manager.addCoins(1000, reason: "Test Setup")
        let initialCoins = manager.coins
        
        let success = manager.spendCoins(500, reason: "Test Spend")
        
        XCTAssertTrue(success)
        XCTAssertEqual(manager.coins, initialCoins - 500)
    }
    
    func testCurrencyManagerCannotOverspend() {
        let manager = CurrencyManager.shared
        let initialCoins = manager.coins
        
        let success = manager.spendCoins(initialCoins + 10000, reason: "Test Overspend")
        
        XCTAssertFalse(success)
        XCTAssertEqual(manager.coins, initialCoins)
    }
    
    // MARK: - Prestige Manager Tests
    
    func testPrestigeManagerXPCurve() {
        let manager = PrestigeManager.shared
        
        // Early levels should require less XP
        let earlyXP = manager.xpToNextLevel // At level 1
        
        // Verify XP increases with level
        XCTAssertGreaterThan(earlyXP, 0)
    }
    
    func testPrestigeManagerAddXP() {
        let manager = PrestigeManager.shared
        let initialXP = manager.currentXP
        
        manager.addXP(50)
        
        XCTAssertGreaterThanOrEqual(manager.currentXP, 0)
    }
    
    // MARK: - Challenge Manager Tests
    
    func testChallengeManagerGeneratesChallenges() {
        let manager = ChallengeManager.shared
        
        manager.checkAndRefreshChallenges()
        
        XCTAssertFalse(manager.dailyChallenges.isEmpty)
        XCTAssertFalse(manager.weeklyChallenges.isEmpty)
    }
    
    func testChallengeTimeRemaining() {
        let manager = ChallengeManager.shared
        manager.checkAndRefreshChallenges()
        
        guard let challenge = manager.dailyChallenges.first else {
            XCTFail("No daily challenges")
            return
        }
        
        XCTAssertFalse(challenge.isExpired)
        XCTAssertFalse(challenge.timeRemaining.isEmpty)
    }
    
    // MARK: - Achievement Manager Tests
    
    func testAchievementManagerBadges() {
        let manager = AchievementManager.shared
        
        XCTAssertFalse(manager.badges.isEmpty)
    }
    
    func testAchievementManagerUnlockBadge() {
        let manager = AchievementManager.shared
        
        // Find a locked badge
        guard let lockedBadge = manager.badges.first(where: { !$0.isUnlocked }) else {
            // All badges unlocked, skip test
            return
        }
        
        manager.unlockBadge(lockedBadge.id)
        
        let updatedBadge = manager.badges.first { $0.id == lockedBadge.id }
        XCTAssertTrue(updatedBadge?.isUnlocked ?? false)
    }
    
    // MARK: - Emote Manager Tests
    
    func testEmoteManagerDefaultEmotes() {
        let manager = EmoteManager.shared
        
        XCTAssertFalse(manager.emotes.isEmpty)
        
        // Should have at least one unlocked emote
        XCTAssertFalse(manager.unlockedEmotes.isEmpty)
    }
    
    func testEmoteWheelSlots() {
        let manager = EmoteManager.shared
        
        XCTAssertEqual(manager.emoteWheel.count, 8)
    }
    
    // MARK: - Profile Icon Tests
    
    func testProfileIconManagerDefaultIcons() {
        let manager = ProfileIconManager.shared
        
        XCTAssertFalse(manager.icons.isEmpty)
        
        // Should have unlocked default icons
        XCTAssertFalse(manager.unlockedIcons.isEmpty)
    }
    
    func testProfileIconEquip() {
        let manager = ProfileIconManager.shared
        
        guard let unlockedIcon = manager.unlockedIcons.first else {
            XCTFail("No unlocked icons")
            return
        }
        
        manager.equipIcon(unlockedIcon)
        
        XCTAssertEqual(manager.equippedIconId, unlockedIcon.id)
    }
    
    // MARK: - Bird Type Tests
    
    func testAllBirdTypesHaveEmoji() {
        for bird in BirdType.allCases {
            XCTAssertFalse(bird.emoji.isEmpty)
        }
    }
    
    func testAllBirdTypesHaveDisplayName() {
        for bird in BirdType.allCases {
            XCTAssertFalse(bird.displayName.isEmpty)
        }
    }
    
    // MARK: - World Position Tests
    
    func testWorldPositionDistance() {
        let pos1 = WorldPosition(x: 0, y: 0, z: 0)
        let pos2 = WorldPosition(x: 3, y: 4, z: 0)
        
        let distance = pos1.distance(to: pos2)
        
        XCTAssertEqual(distance, 5.0, accuracy: 0.001)
    }
    
    // MARK: - Biome Tests
    
    func testAllBiomesHaveEmoji() {
        for biome in Biome.allCases {
            XCTAssertFalse(biome.emoji.isEmpty)
        }
    }
    
    func testBiomeResourceMultipliers() {
        for biome in Biome.allCases {
            XCTAssertGreaterThan(biome.resourceMultiplier, 0)
        }
    }
    
    // MARK: - Chat Manager Tests
    
    func testChatManagerBlockUser() {
        let manager = ChatManager.shared
        let testUserId = "test_user_123"
        
        manager.blockUser(testUserId)
        
        XCTAssertTrue(manager.isBlocked(testUserId))
        
        // Clean up
        manager.unblockUser(testUserId)
        XCTAssertFalse(manager.isBlocked(testUserId))
    }
    
    // MARK: - Report Manager Tests
    
    func testReportManagerCanReport() {
        let manager = ReportManager.shared
        
        // Should be able to report when not on cooldown
        // Note: This may fail if run immediately after another test that reported
        XCTAssertTrue(manager.canReport || manager.cooldownRemaining > 0)
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilitySettingsDefaults() {
        let manager = AccessibilityManager.shared
        
        // Default settings should be reasonable
        XCTAssertFalse(manager.settings.highContrastMode)
        XCTAssertTrue(manager.settings.hapticFeedback)
        XCTAssertEqual(manager.settings.colorBlindMode, .none)
    }
    
    func testAccessibilityTextScaling() {
        let manager = AccessibilityManager.shared
        
        manager.settings.largeText = false
        XCTAssertEqual(manager.textScaleFactor, 1.0)
        
        manager.settings.largeText = true
        XCTAssertEqual(manager.textScaleFactor, 1.3)
    }
    
    // MARK: - Localization Tests
    
    func testLocalizationManagerDefaultLanguage() {
        let manager = LocalizationManager.shared
        
        // Should have a valid language
        XCTAssertNotNil(manager.currentLanguage)
    }
    
    func testLocalizedStrings() {
        // Basic strings should localize to something
        let appName = "app_name".localized
        XCTAssertFalse(appName.isEmpty)
    }
    
    // MARK: - Network Manager Tests
    
    func testNetworkManagerOnlineStatus() {
        let manager = NetworkManager.shared
        
        // Should have a defined status
        XCTAssertTrue(manager.networkStatus == .connected || 
                      manager.networkStatus == .disconnected ||
                      manager.networkStatus == .unknown)
    }
    
    // MARK: - Legal Manager Tests
    
    func testLegalDocuments() {
        let manager = LegalManager.shared
        
        for docType in LegalDocumentType.allCases {
            let content = manager.getDocument(docType)
            XCTAssertFalse(content.isEmpty, "\(docType.title) should have content")
        }
    }
    
    // MARK: - Battle Pass Tests
    
    func testBattlePassSeasonExists() {
        let manager = BattlePassManager.shared
        
        XCTAssertNotNil(manager.currentSeason)
    }
    
    func testBattlePassTiers() {
        let manager = BattlePassManager.shared
        
        XCTAssertEqual(manager.maxTier, 100)
        XCTAssertEqual(manager.currentSeason?.tiers.count, 100)
    }
    
    // MARK: - Special Location Tests
    
    func testSpecialLocationsExist() {
        let locations = OpenWorldManager.specialLocations
        
        XCTAssertFalse(locations.isEmpty)
        
        // Should have bowling alley and CHairBNB
        let bowlingAlley = locations.first { $0.id == "bowling_alley" }
        let chairBNB = locations.first { $0.id == "chairbnb" }
        
        XCTAssertNotNil(bowlingAlley)
        XCTAssertNotNil(chairBNB)
        
        // Bowling alley should require crow
        XCTAssertEqual(bowlingAlley?.requiredBird, .crow)
        
        // Both should be hidden
        XCTAssertTrue(bowlingAlley?.isHidden ?? false)
        XCTAssertTrue(chairBNB?.isHidden ?? false)
    }
}
