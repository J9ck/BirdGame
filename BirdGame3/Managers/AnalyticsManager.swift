//
//  AnalyticsManager.swift
//  BirdGame3
//
//  Analytics and telemetry for tracking game events and user behavior
//

import Foundation
import SwiftUI

// MARK: - Analytics Event

struct AnalyticsEvent: Codable {
    let id: String
    let name: String
    let category: AnalyticsCategory
    let parameters: [String: String]
    let timestamp: Date
    let sessionId: String
}

// MARK: - Analytics Category

enum AnalyticsCategory: String, Codable {
    case gameplay
    case progression
    case social
    case monetization
    case ui
    case error
    case performance
}

// MARK: - Screen Name

enum ScreenName: String {
    case mainMenu = "main_menu"
    case characterSelect = "character_select"
    case game = "game"
    case results = "results"
    case shop = "shop"
    case itemShop = "item_shop"
    case settings = "settings"
    case lobby = "lobby"
    case openWorld = "open_world"
    case nestBuilder = "nest_builder"
    case profile = "profile"
    case battlePass = "battle_pass"
    case challenges = "challenges"
    case flock = "flock"
    case chat = "chat"
}

// MARK: - Analytics Manager

class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    // MARK: - Published Properties
    
    @Published var isEnabled: Bool = true
    @Published var sessionId: String
    @Published var sessionStart: Date
    
    // MARK: - Private Properties
    
    private var eventQueue: [AnalyticsEvent] = []
    private let maxQueueSize = 100
    private let flushInterval: TimeInterval = 60 // Flush every 60 seconds
    private var flushTimer: Timer?
    
    private let saveKey = "birdgame3_analytics"
    private let sessionCountKey = "birdgame3_sessionCount"
    private let firstLaunchKey = "birdgame3_firstLaunch"
    
    // MARK: - User Properties
    
    private var userProperties: [String: String] = [:]
    
    // MARK: - Initialization
    
    private init() {
        sessionId = UUID().uuidString
        sessionStart = Date()
        
        loadSettings()
        loadPendingEvents()
        incrementSessionCount()
        startFlushTimer()
        
        // Track app launch
        trackAppLaunch()
    }
    
    deinit {
        flushTimer?.invalidate()
    }
    
    // MARK: - Configuration
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "\(saveKey)_enabled")
    }
    
    func setUserProperty(_ value: String?, forKey key: String) {
        if let value = value {
            userProperties[key] = value
        } else {
            userProperties.removeValue(forKey: key)
        }
    }
    
    func setUserId(_ userId: String?) {
        setUserProperty(userId, forKey: "user_id")
    }
    
    // MARK: - Event Tracking
    
    func trackEvent(_ name: String, category: AnalyticsCategory, parameters: [String: String] = [:]) {
        guard isEnabled else { return }
        
        var params = parameters
        params["session_duration"] = String(Int(Date().timeIntervalSince(sessionStart)))
        
        let event = AnalyticsEvent(
            id: UUID().uuidString,
            name: name,
            category: category,
            parameters: params,
            timestamp: Date(),
            sessionId: sessionId
        )
        
        eventQueue.append(event)
        
        // Flush if queue is full
        if eventQueue.count >= maxQueueSize {
            flush()
        }
        
        #if DEBUG
        print("📊 Analytics: \(name) - \(parameters)")
        #endif
    }
    
    // MARK: - Screen Tracking
    
    func trackScreen(_ screen: ScreenName) {
        trackEvent("screen_view", category: .ui, parameters: [
            "screen_name": screen.rawValue
        ])
    }
    
    // MARK: - Gameplay Events
    
    func trackMatchStart(mode: String, birdType: String) {
        trackEvent("match_start", category: .gameplay, parameters: [
            "game_mode": mode,
            "bird_type": birdType
        ])
    }
    
    func trackMatchEnd(won: Bool, duration: TimeInterval, damageDealt: Int, damageReceived: Int) {
        trackEvent("match_end", category: .gameplay, parameters: [
            "won": String(won),
            "duration": String(Int(duration)),
            "damage_dealt": String(damageDealt),
            "damage_received": String(damageReceived)
        ])
    }
    
    func trackAbilityUsed(ability: String, birdType: String) {
        trackEvent("ability_used", category: .gameplay, parameters: [
            "ability": ability,
            "bird_type": birdType
        ])
    }
    
    func trackNestBuilt(componentType: String) {
        trackEvent("nest_built", category: .gameplay, parameters: [
            "component_type": componentType
        ])
    }
    
    func trackResourceGathered(resourceType: String, amount: Int) {
        trackEvent("resource_gathered", category: .gameplay, parameters: [
            "resource_type": resourceType,
            "amount": String(amount)
        ])
    }
    
    // MARK: - Progression Events
    
    func trackLevelUp(level: Int) {
        trackEvent("level_up", category: .progression, parameters: [
            "level": String(level)
        ])
    }
    
    func trackPrestige(level: Int) {
        trackEvent("prestige", category: .progression, parameters: [
            "prestige_level": String(level)
        ])
    }
    
    func trackAchievementUnlocked(achievementId: String) {
        trackEvent("achievement_unlocked", category: .progression, parameters: [
            "achievement_id": achievementId
        ])
    }
    
    func trackBattlePassTierReached(tier: Int, isPremium: Bool) {
        trackEvent("battlepass_tier", category: .progression, parameters: [
            "tier": String(tier),
            "is_premium": String(isPremium)
        ])
    }
    
    func trackChallengeCompleted(challengeId: String, type: String) {
        trackEvent("challenge_completed", category: .progression, parameters: [
            "challenge_id": challengeId,
            "challenge_type": type
        ])
    }
    
    // MARK: - Social Events
    
    func trackFriendAdded() {
        trackEvent("friend_added", category: .social)
    }
    
    func trackPartyJoined(memberCount: Int) {
        trackEvent("party_joined", category: .social, parameters: [
            "member_count": String(memberCount)
        ])
    }
    
    func trackFlockJoined(flockSize: Int) {
        trackEvent("flock_joined", category: .social, parameters: [
            "flock_size": String(flockSize)
        ])
    }
    
    func trackEmoteUsed(emoteId: String) {
        trackEvent("emote_used", category: .social, parameters: [
            "emote_id": emoteId
        ])
    }
    
    func trackChatMessageSent(channelType: String) {
        trackEvent("chat_message", category: .social, parameters: [
            "channel_type": channelType
        ])
    }
    
    // MARK: - Monetization Events
    
    func trackPurchaseStarted(itemId: String, price: Int, currency: String) {
        trackEvent("purchase_started", category: .monetization, parameters: [
            "item_id": itemId,
            "price": String(price),
            "currency": currency
        ])
    }
    
    func trackPurchaseCompleted(itemId: String, price: Int, currency: String) {
        trackEvent("purchase_completed", category: .monetization, parameters: [
            "item_id": itemId,
            "price": String(price),
            "currency": currency
        ])
    }
    
    func trackBattlePassPurchased() {
        trackEvent("battlepass_purchased", category: .monetization)
    }
    
    func trackAdWatched(adType: String, reward: String) {
        trackEvent("ad_watched", category: .monetization, parameters: [
            "ad_type": adType,
            "reward": reward
        ])
    }
    
    // MARK: - Error Events
    
    func trackError(_ error: String, context: String) {
        trackEvent("error", category: .error, parameters: [
            "error_message": error,
            "context": context
        ])
    }
    
    func trackCrash(_ crash: String) {
        trackEvent("crash", category: .error, parameters: [
            "crash_info": crash
        ])
    }
    
    // MARK: - Performance Events
    
    func trackLoadTime(screen: ScreenName, duration: TimeInterval) {
        trackEvent("load_time", category: .performance, parameters: [
            "screen": screen.rawValue,
            "duration_ms": String(Int(duration * 1000))
        ])
    }
    
    func trackFPS(average: Int, minimum: Int) {
        trackEvent("fps", category: .performance, parameters: [
            "average": String(average),
            "minimum": String(minimum)
        ])
    }
    
    // MARK: - App Lifecycle
    
    private func trackAppLaunch() {
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: firstLaunchKey)
        
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: firstLaunchKey)
            trackEvent("first_launch", category: .ui)
        }
        
        trackEvent("app_launch", category: .ui, parameters: [
            "is_first_launch": String(isFirstLaunch),
            "session_number": String(sessionCount)
        ])
    }
    
    func trackAppBackground() {
        trackEvent("app_background", category: .ui, parameters: [
            "session_duration": String(Int(Date().timeIntervalSince(sessionStart)))
        ])
        flush()
    }
    
    func trackAppForeground() {
        // Start new session if app was backgrounded for > 30 min
        let lastActive = UserDefaults.standard.object(forKey: "\(saveKey)_lastActive") as? Date ?? Date()
        if Date().timeIntervalSince(lastActive) > 30 * 60 {
            sessionId = UUID().uuidString
            sessionStart = Date()
            incrementSessionCount()
        }
        
        trackEvent("app_foreground", category: .ui)
    }
    
    // MARK: - Session Management
    
    private var sessionCount: Int {
        UserDefaults.standard.integer(forKey: sessionCountKey)
    }
    
    private func incrementSessionCount() {
        let current = sessionCount
        UserDefaults.standard.set(current + 1, forKey: sessionCountKey)
    }
    
    // MARK: - Flushing Events
    
    private func startFlushTimer() {
        flushTimer = Timer.scheduledTimer(withTimeInterval: flushInterval, repeats: true) { [weak self] _ in
            self?.flush()
        }
    }
    
    func flush() {
        guard !eventQueue.isEmpty else { return }
        
        let eventsToSend = eventQueue
        eventQueue.removeAll()
        
        // In a real app, send to analytics server (Firebase, Amplitude, etc.)
        sendToServer(eventsToSend)
        
        // Save pending events in case of failure
        savePendingEvents()
    }
    
    private func sendToServer(_ events: [AnalyticsEvent]) {
        // Simulate sending to analytics server
        #if DEBUG
        print("📊 Flushing \(events.count) analytics events")
        #endif
        
        // In production, this would be:
        // - Firebase Analytics: Analytics.logEvent(...)
        // - Amplitude: Amplitude.instance().logEvent(...)
        // - Custom backend: URLSession POST request
    }
    
    // MARK: - Persistence
    
    private func loadSettings() {
        isEnabled = UserDefaults.standard.object(forKey: "\(saveKey)_enabled") as? Bool ?? true
    }
    
    private func savePendingEvents() {
        if let data = try? JSONEncoder().encode(eventQueue) {
            UserDefaults.standard.set(data, forKey: "\(saveKey)_pending")
        }
    }
    
    private func loadPendingEvents() {
        if let data = UserDefaults.standard.data(forKey: "\(saveKey)_pending"),
           let events = try? JSONDecoder().decode([AnalyticsEvent].self, from: data) {
            eventQueue = events
        }
    }
}
