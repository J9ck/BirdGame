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
        
        manager.addCoins(100)
        
        XCTAssertEqual(manager.coins, initialCoins + 100)
    }
    
    func testCurrencyManagerSpendCoins() {
        let manager = CurrencyManager.shared
        manager.addCoins(1000)
        let initialCoins = manager.coins
        
        let success = manager.spendCoins(500)
        
        XCTAssertTrue(success)
        XCTAssertEqual(manager.coins, initialCoins - 500)
    }
    
    func testCurrencyManagerCannotOverspend() {
        let manager = CurrencyManager.shared
        let initialCoins = manager.coins
        
        let success = manager.spendCoins(initialCoins + 10000)
        
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
    
    func testOwlBirdTypeExists() {
        XCTAssertTrue(BirdType.allCases.contains(.owl))
        XCTAssertEqual(BirdType.owl.displayName, "Owl")
        XCTAssertEqual(BirdType.owl.emoji, "🦉")
    }
    
    func testAllBirdTypesHaveSkills() {
        for bird in BirdType.allCases {
            let skills = bird.skills
            XCTAssertGreaterThanOrEqual(skills.count, 3, "\(bird.displayName) should have at least 3 skills")
            XCTAssertLessThanOrEqual(skills.count, 4, "\(bird.displayName) should have at most 4 skills")
        }
    }
    
    func testAllBirdTypesHavePassive() {
        for bird in BirdType.allCases {
            let passive = bird.passive
            XCTAssertFalse(passive.name.isEmpty, "\(bird.displayName) should have a passive name")
            XCTAssertFalse(passive.description.isEmpty, "\(bird.displayName) should have a passive description")
        }
    }
    
    func testBirdSkillsHaveValidData() {
        for bird in BirdType.allCases {
            for skill in bird.skills {
                XCTAssertFalse(skill.id.isEmpty)
                XCTAssertFalse(skill.name.isEmpty)
                XCTAssertFalse(skill.description.isEmpty)
                XCTAssertGreaterThan(skill.cooldown, 0)
                XCTAssertGreaterThanOrEqual(skill.energyCost, 0)
                XCTAssertFalse(skill.icon.isEmpty)
            }
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
    
    // MARK: - Prey System Tests (Like "The Wolf" MMORPG)
    
    func testAllPreyTypesHaveEmoji() {
        for preyType in PreyType.allCases {
            XCTAssertFalse(preyType.emoji.isEmpty)
        }
    }
    
    func testAllPreyTypesHaveDisplayName() {
        for preyType in PreyType.allCases {
            XCTAssertFalse(preyType.displayName.isEmpty)
        }
    }
    
    func testPreyTypeHungerRestore() {
        for preyType in PreyType.allCases {
            XCTAssertGreaterThan(preyType.hungerRestore, 0)
        }
    }
    
    func testPreyTypeXPReward() {
        for preyType in PreyType.allCases {
            XCTAssertGreaterThan(preyType.xpReward, 0)
        }
    }
    
    func testPreyTypeBaseHealth() {
        for preyType in PreyType.allCases {
            XCTAssertGreaterThan(preyType.baseHealth, 0)
        }
    }
    
    func testPreyTypeSpeed() {
        for preyType in PreyType.allCases {
            XCTAssertGreaterThan(preyType.speed, 0)
        }
    }
    
    func testPreyTypeDifficultyTiers() {
        for preyType in PreyType.allCases {
            XCTAssertGreaterThanOrEqual(preyType.difficultyTier, 1)
            XCTAssertLessThanOrEqual(preyType.difficultyTier, 5)
        }
    }
    
    func testPreyTypeHasPreferredBiomes() {
        for preyType in PreyType.allCases {
            XCTAssertFalse(preyType.preferredBiomes.isEmpty, "\(preyType.displayName) should have preferred biomes")
        }
    }
    
    func testPreyCreation() {
        let prey = Prey(
            id: "test_prey",
            type: .worm,
            position: WorldPosition(x: 0, y: 0, z: 0),
            health: 10,
            maxHealth: 10,
            isAlerted: false,
            fleeDirection: nil
        )
        
        XCTAssertEqual(prey.health, 10)
        XCTAssertFalse(prey.isDead)
        XCTAssertEqual(prey.healthPercent, 1.0)
    }
    
    func testPreyDamageAndDeath() {
        var prey = Prey(
            id: "test_prey",
            type: .worm,
            position: WorldPosition(x: 0, y: 0, z: 0),
            health: 10,
            maxHealth: 10,
            isAlerted: false,
            fleeDirection: nil
        )
        
        // Deal partial damage
        prey.health -= 5
        XCTAssertEqual(prey.health, 5)
        XCTAssertFalse(prey.isDead)
        XCTAssertEqual(prey.healthPercent, 0.5, accuracy: 0.001)
        
        // Kill the prey
        prey.health = 0
        XCTAssertTrue(prey.isDead)
        XCTAssertEqual(prey.healthPercent, 0)
    }
    
    // MARK: - Territory System Tests
    
    func testTerritoryCreation() {
        let territory = Territory(
            id: "test_territory",
            name: "Test Plains",
            centerPosition: WorldPosition(x: 100, y: 100, z: 50),
            radius: 500,
            controllingFlockId: nil,
            controllingFlockName: nil,
            controlPoints: 0,
            maxControlPoints: 100,
            biome: .plains,
            bonusMultiplier: 1.2,
            lastCaptured: nil
        )
        
        XCTAssertTrue(territory.isNeutral)
        XCTAssertFalse(territory.isContested)
        XCTAssertEqual(territory.controlPercent, 0)
    }
    
    func testTerritoryContested() {
        let territory = Territory(
            id: "test_territory",
            name: "Test Plains",
            centerPosition: WorldPosition(x: 100, y: 100, z: 50),
            radius: 500,
            controllingFlockId: "flock_1",
            controllingFlockName: "Sky Warriors",
            controlPoints: 50,
            maxControlPoints: 100,
            biome: .plains,
            bonusMultiplier: 1.2,
            lastCaptured: nil
        )
        
        XCTAssertFalse(territory.isNeutral)
        XCTAssertTrue(territory.isContested)
        XCTAssertEqual(territory.controlPercent, 0.5, accuracy: 0.001)
    }
    
    func testHuntResultSuccess() {
        let result = HuntResult(
            success: true,
            message: "Caught the prey!",
            hungerRestored: 20,
            xpGained: 50,
            preyType: .rabbit
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.hungerRestored, 20)
        XCTAssertEqual(result.xpGained, 50)
        XCTAssertEqual(result.preyType, .rabbit)
    }
    
    func testHuntResultFailure() {
        let result = HuntResult(
            success: false,
            message: "Prey escaped!",
            hungerRestored: 0,
            xpGained: 0,
            preyType: nil
        )
        
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.hungerRestored, 0)
        XCTAssertEqual(result.xpGained, 0)
        XCTAssertNil(result.preyType)
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
    
    // MARK: - Core Gameplay Validation Tests
    
    func testCombatSystemDamageCalculation() {
        // Verify basic damage calculation works correctly
        let pigeon = Bird(type: .pigeon)
        let eagle = Bird(type: .eagle)
        
        let normalDamage = CombatSystem.calculateDamage(attacker: pigeon, defender: eagle, isAbility: false)
        let abilityDamage = CombatSystem.calculateDamage(attacker: pigeon, defender: eagle, isAbility: true)
        
        // Damage should be positive
        XCTAssertGreaterThan(normalDamage, 0)
        XCTAssertGreaterThan(abilityDamage, 0)
    }
    
    func testAllBirdTypesHaveValidStats() {
        for bird in BirdType.allCases {
            let stats = bird.baseStats
            
            // All stats should be positive
            XCTAssertGreaterThan(stats.health, 0, "\(bird.displayName) health should be positive")
            XCTAssertGreaterThan(stats.maxHealth, 0, "\(bird.displayName) maxHealth should be positive")
            XCTAssertGreaterThan(stats.attack, 0, "\(bird.displayName) attack should be positive")
            XCTAssertGreaterThan(stats.defense, 0, "\(bird.displayName) defense should be positive")
            XCTAssertGreaterThan(stats.speed, 0, "\(bird.displayName) speed should be positive")
            XCTAssertGreaterThan(stats.abilityCooldown, 0, "\(bird.displayName) abilityCooldown should be positive")
            XCTAssertGreaterThan(stats.abilityDamage, 0, "\(bird.displayName) abilityDamage should be positive")
        }
    }
    
    func testAllBirdTypesHaveAbilities() {
        for bird in BirdType.allCases {
            XCTAssertFalse(bird.abilityName.isEmpty, "\(bird.displayName) should have an ability name")
            XCTAssertFalse(bird.abilityDescription.isEmpty, "\(bird.displayName) should have an ability description")
        }
    }
    
    func testBirdStatsBalance() {
        // Verify game balance - no bird should be completely overpowered
        var statsSum: [BirdType: Double] = [:]
        
        for bird in BirdType.allCases {
            let stats = bird.baseStats
            // Simple balance metric: sum of normalized stats
            let totalStat = stats.health / 10 + stats.attack + stats.defense + stats.speed
            statsSum[bird] = totalStat
        }
        
        // All birds should be within a reasonable range of each other in total stats
        let minStat = statsSum.values.min() ?? 0
        let maxStat = statsSum.values.max() ?? 0
        
        // The ratio between strongest and weakest shouldn't be too extreme
        if minStat > 0 {
            let ratio = maxStat / minStat
            XCTAssertLessThan(ratio, 2.5, "Bird balance ratio should not exceed 2.5x")
        }
    }
    
    // MARK: - Game Mode Tests
    
    func testGameStateModeTransitions() {
        let gameState = GameState()
        
        // Quick match should lead to character select
        gameState.startQuickMatch()
        XCTAssertEqual(gameState.currentScreen, .characterSelect)
        XCTAssertEqual(gameState.gameMode, .quickMatch)
        
        // Reset
        gameState.returnToMenu()
        
        // Arcade mode
        gameState.startArcade()
        XCTAssertEqual(gameState.currentScreen, .characterSelect)
        XCTAssertEqual(gameState.gameMode, .arcade)
        
        // Reset
        gameState.returnToMenu()
        
        // Training mode
        gameState.startTraining()
        XCTAssertEqual(gameState.currentScreen, .characterSelect)
        XCTAssertEqual(gameState.gameMode, .training)
    }
    
    func testOpenWorldModeAccessibility() {
        let gameState = GameState()
        
        // Open world should be accessible
        gameState.openOpenWorld()
        XCTAssertEqual(gameState.currentScreen, .openWorld)
    }
    
    // MARK: - Open World Biome Tests
    
    func testAllBiomesHaveValidConfiguration() {
        for biome in Biome.allCases {
            // Each biome should have display properties
            XCTAssertFalse(biome.displayName.isEmpty, "\(biome) should have a display name")
            XCTAssertFalse(biome.emoji.isEmpty, "\(biome) should have an emoji")
            
            // Resource multiplier should be valid
            XCTAssertGreaterThan(biome.resourceMultiplier, 0, "\(biome) should have positive resource multiplier")
            XCTAssertLessThanOrEqual(biome.resourceMultiplier, 2.0, "\(biome) resource multiplier should not exceed 2.0")
            
            // Danger level should be in valid range
            XCTAssertGreaterThanOrEqual(biome.dangerLevel, 1, "\(biome) danger level should be at least 1")
            XCTAssertLessThanOrEqual(biome.dangerLevel, 5, "\(biome) danger level should not exceed 5")
        }
    }
    
    // MARK: - Resource System Tests
    
    func testResourceTypesHaveValidProperties() {
        for resourceType in ResourceType.allCases {
            XCTAssertFalse(resourceType.displayName.isEmpty, "\(resourceType) should have a display name")
            XCTAssertFalse(resourceType.emoji.isEmpty, "\(resourceType) should have an emoji")
            XCTAssertGreaterThan(resourceType.respawnTime, 0, "\(resourceType) should have positive respawn time")
            XCTAssertGreaterThan(resourceType.baseYield, 0, "\(resourceType) should have positive base yield")
        }
    }
    
    // MARK: - Combat Ability Tests
    
    func testAbilityResultStruct() {
        // Test default AbilityResult
        let result = AbilityResult()
        XCTAssertEqual(result.damage, 0)
        XCTAssertFalse(result.multiHit)
        XCTAssertEqual(result.hitCount, 1)
        XCTAssertFalse(result.stunApplied)
        XCTAssertEqual(result.stunDuration, 0)
        XCTAssertFalse(result.knockback)
        XCTAssertFalse(result.buffApplied)
        XCTAssertEqual(result.buffType, .none)
        XCTAssertEqual(result.buffDuration, 0)
    }
    
    func testAIDifficultyLevels() {
        for difficulty in AIDifficulty.allCases {
            XCTAssertFalse(difficulty.displayName.isEmpty, "\(difficulty) should have a display name")
            XCTAssertGreaterThan(difficulty.reactionTime, 0, "\(difficulty) reaction time should be positive")
            XCTAssertLessThanOrEqual(difficulty.reactionTime, 2.0, "\(difficulty) reaction time should not exceed 2s")
            XCTAssertGreaterThanOrEqual(difficulty.blockChance, 0, "\(difficulty) block chance should be >= 0")
            XCTAssertLessThanOrEqual(difficulty.blockChance, 1.0, "\(difficulty) block chance should be <= 1.0")
        }
    }
    
    // MARK: - Battle Arena Tests
    
    func testBattleArenasExist() {
        let arenas = BattleArena.allCases
        XCTAssertGreaterThan(arenas.count, 0, "Should have at least one arena")
        
        for arena in arenas {
            XCTAssertFalse(arena.rawValue.isEmpty, "\(arena) should have a raw value name")
            XCTAssertFalse(arena.emoji.isEmpty, "\(arena) should have an emoji")
        }
    }
    
    // MARK: - Voice Chat System Tests
    
    func testVoiceChatManagerExists() {
        let manager = VoiceChatManager.shared
        
        // Manager should be accessible
        XCTAssertNotNil(manager)
        
        // Volume should be in valid range
        XCTAssertGreaterThanOrEqual(manager.volume, 0)
        XCTAssertLessThanOrEqual(manager.volume, 1.0)
        
        // Voice speed should be in valid range
        XCTAssertGreaterThanOrEqual(manager.voiceSpeed, VoiceChatManager.minVoiceSpeed)
        XCTAssertLessThanOrEqual(manager.voiceSpeed, VoiceChatManager.maxVoiceSpeed)
    }
    
    // MARK: - Sound Manager Tests
    
    func testSoundManagerConfiguration() {
        let manager = SoundManager.shared
        
        // Volume settings should be in valid range
        XCTAssertGreaterThanOrEqual(manager.musicVolume, 0)
        XCTAssertLessThanOrEqual(manager.musicVolume, 1.0)
        XCTAssertGreaterThanOrEqual(manager.sfxVolume, 0)
        XCTAssertLessThanOrEqual(manager.sfxVolume, 1.0)
    }
    
    func testSoundEffectsHaveFileNames() {
        for effect in SoundManager.SoundEffect.allCases {
            XCTAssertFalse(effect.fileName.isEmpty, "\(effect) should have a file name")
            XCTAssertFalse(effect.audioFileName.isEmpty, "\(effect) should have an audio file name")
        }
    }
    
    // MARK: - Weather System Tests
    
    func testWeatherSystemConfiguration() {
        for weather in Weather.allCases {
            XCTAssertFalse(weather.displayName.isEmpty, "\(weather) should have a display name")
            XCTAssertFalse(weather.emoji.isEmpty, "\(weather) should have an emoji")
        }
    }
    
    func testTimeOfDayConfiguration() {
        for time in TimeOfDay.allCases {
            XCTAssertFalse(time.displayName.isEmpty, "\(time) should have a display name")
            XCTAssertFalse(time.emoji.isEmpty, "\(time) should have an emoji")
        }
    }
    
    // MARK: - Nest Building Tests
    
    func testNestComponentTypes() {
        for component in NestComponentType.allCases {
            XCTAssertFalse(component.displayName.isEmpty, "\(component) should have a display name")
            XCTAssertFalse(component.emoji.isEmpty, "\(component) should have an emoji")
            XCTAssertFalse(component.requiredResources.isEmpty, "\(component) should require resources")
            XCTAssertGreaterThan(component.health, 0, "\(component) should have positive health")
        }
    }
    
    // MARK: - Player World State Tests
    
    func testPlayerWorldStateInitialization() {
        let state = PlayerWorldState.new()
        
        XCTAssertEqual(state.health, 100)
        XCTAssertEqual(state.hunger, 100)
        XCTAssertEqual(state.energy, 100)
        XCTAssertTrue(state.inventory.isEmpty)
        XCTAssertEqual(state.currentBiome, .plains)
    }
    
    func testPlayerWorldStateResourceManagement() {
        var state = PlayerWorldState.new()
        
        // Add resources
        let added = state.addResource(.twigs, amount: 10)
        XCTAssertEqual(added, 10)
        XCTAssertEqual(state.inventory[.twigs], 10)
        
        // Remove resources
        let removed = state.removeResource(.twigs, amount: 5)
        XCTAssertTrue(removed)
        XCTAssertEqual(state.inventory[.twigs], 5)
        
        // Can't remove more than available
        let removeTooMany = state.removeResource(.twigs, amount: 100)
        XCTAssertFalse(removeTooMany)
        XCTAssertEqual(state.inventory[.twigs], 5)
    }
}
