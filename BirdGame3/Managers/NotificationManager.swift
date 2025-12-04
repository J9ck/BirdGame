//
//  NotificationManager.swift
//  BirdGame3
//
//  Push notification management for raids, friends, and game events
//

import Foundation
import UserNotifications
import SwiftUI

// MARK: - Notification Type

enum GameNotificationType: String, CaseIterable {
    case raidAlert = "raid_alert"
    case friendOnline = "friend_online"
    case partyInvite = "party_invite"
    case flockMessage = "flock_message"
    case challengeComplete = "challenge_complete"
    case battlePassReward = "battlepass_reward"
    case dailyReminder = "daily_reminder"
    case shopRefresh = "shop_refresh"
    case matchReady = "match_ready"
    
    var title: String {
        switch self {
        case .raidAlert: return "🚨 Nest Under Attack!"
        case .friendOnline: return "👋 Friend Online"
        case .partyInvite: return "🎉 Party Invite"
        case .flockMessage: return "💬 Flock Message"
        case .challengeComplete: return "✅ Challenge Complete!"
        case .battlePassReward: return "🎁 Reward Ready!"
        case .dailyReminder: return "🐦 Your Birds Miss You!"
        case .shopRefresh: return "🛒 Shop Updated!"
        case .matchReady: return "⚔️ Match Found!"
        }
    }
    
    var sound: UNNotificationSound {
        switch self {
        case .raidAlert, .matchReady:
            return .defaultCritical
        case .partyInvite, .friendOnline:
            return .default
        default:
            return .default
        }
    }
    
    var categoryIdentifier: String {
        rawValue
    }
}

// MARK: - Notification Settings

struct NotificationSettings: Codable {
    var raidAlerts: Bool = true
    var friendOnline: Bool = true
    var partyInvites: Bool = true
    var flockMessages: Bool = true
    var challengeComplete: Bool = true
    var battlePassRewards: Bool = true
    var dailyReminder: Bool = true
    var shopRefresh: Bool = false
    var matchReady: Bool = true
    
    func isEnabled(for type: GameNotificationType) -> Bool {
        switch type {
        case .raidAlert: return raidAlerts
        case .friendOnline: return friendOnline
        case .partyInvite: return partyInvites
        case .flockMessage: return flockMessages
        case .challengeComplete: return challengeComplete
        case .battlePassReward: return battlePassRewards
        case .dailyReminder: return dailyReminder
        case .shopRefresh: return shopRefresh
        case .matchReady: return matchReady
        }
    }
}

// MARK: - Notification Manager

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    // MARK: - Published Properties
    
    @Published var isAuthorized: Bool = false
    @Published var settings: NotificationSettings = NotificationSettings()
    @Published var pendingNotifications: Int = 0
    
    // MARK: - Private Properties
    
    private let saveKey = "birdgame3_notificationSettings"
    private let center = UNUserNotificationCenter.current()
    
    // MARK: - Initialization
    
    private init() {
        loadSettings()
        checkAuthorizationStatus()
        setupNotificationCategories()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                completion(granted)
                
                if granted {
                    self?.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func checkAuthorizationStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - Notification Categories
    
    private func setupNotificationCategories() {
        // Raid Alert Category - with actions
        let raidViewAction = UNNotificationAction(
            identifier: "RAID_VIEW",
            title: "View Nest",
            options: .foreground
        )
        let raidDefendAction = UNNotificationAction(
            identifier: "RAID_DEFEND",
            title: "Defend Now!",
            options: .foreground
        )
        let raidCategory = UNNotificationCategory(
            identifier: GameNotificationType.raidAlert.categoryIdentifier,
            actions: [raidViewAction, raidDefendAction],
            intentIdentifiers: []
        )
        
        // Party Invite Category
        let acceptAction = UNNotificationAction(
            identifier: "PARTY_ACCEPT",
            title: "Join Party",
            options: .foreground
        )
        let declineAction = UNNotificationAction(
            identifier: "PARTY_DECLINE",
            title: "Decline",
            options: .destructive
        )
        let partyCategory = UNNotificationCategory(
            identifier: GameNotificationType.partyInvite.categoryIdentifier,
            actions: [acceptAction, declineAction],
            intentIdentifiers: []
        )
        
        // Match Ready Category
        let joinMatchAction = UNNotificationAction(
            identifier: "MATCH_JOIN",
            title: "Join Match",
            options: .foreground
        )
        let matchCategory = UNNotificationCategory(
            identifier: GameNotificationType.matchReady.categoryIdentifier,
            actions: [joinMatchAction],
            intentIdentifiers: []
        )
        
        center.setNotificationCategories([raidCategory, partyCategory, matchCategory])
    }
    
    // MARK: - Sending Notifications
    
    func sendLocalNotification(
        type: GameNotificationType,
        body: String,
        userInfo: [String: Any] = [:],
        delay: TimeInterval = 0
    ) {
        guard isAuthorized && settings.isEnabled(for: type) else { return }
        
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = body
        content.sound = type.sound
        content.categoryIdentifier = type.categoryIdentifier
        content.userInfo = userInfo
        
        let trigger: UNNotificationTrigger?
        if delay > 0 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        } else {
            trigger = nil
        }
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    // MARK: - Specific Notifications
    
    func sendRaidAlert(attackerName: String, nestLevel: Int) {
        sendLocalNotification(
            type: .raidAlert,
            body: "\(attackerName) is attacking your level \(nestLevel) nest! Defend it now!",
            userInfo: ["action": "open_nest"]
        )
    }
    
    func sendFriendOnlineNotification(friendName: String) {
        sendLocalNotification(
            type: .friendOnline,
            body: "\(friendName) just came online. Invite them to play!"
        )
    }
    
    func sendPartyInvite(from playerName: String, partyCode: String) {
        sendLocalNotification(
            type: .partyInvite,
            body: "\(playerName) invited you to their party!",
            userInfo: ["partyCode": partyCode]
        )
    }
    
    func sendFlockMessage(from playerName: String, flockName: String) {
        sendLocalNotification(
            type: .flockMessage,
            body: "\(playerName) sent a message in \(flockName)"
        )
    }
    
    func sendChallengeComplete(challengeName: String) {
        sendLocalNotification(
            type: .challengeComplete,
            body: "You completed '\(challengeName)'! Claim your reward!"
        )
    }
    
    func sendBattlePassReward(tier: Int) {
        sendLocalNotification(
            type: .battlePassReward,
            body: "You reached tier \(tier)! Claim your new rewards!"
        )
    }
    
    func sendMatchReady() {
        sendLocalNotification(
            type: .matchReady,
            body: "Your match is ready! Join now before it starts!"
        )
    }
    
    // MARK: - Scheduled Notifications
    
    func scheduleDailyReminder(at hour: Int = 19, minute: Int = 0) {
        guard settings.dailyReminder else { return }
        
        // Remove existing daily reminders
        center.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let content = UNMutableNotificationContent()
        content.title = GameNotificationType.dailyReminder.title
        content.body = "Complete your daily challenges and collect rewards!"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    func scheduleShopRefreshReminder() {
        guard settings.shopRefresh else { return }
        
        // Schedule for next shop refresh (usually midnight)
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        components.hour = 0
        components.minute = 0
        
        let content = UNMutableNotificationContent()
        content.title = GameNotificationType.shopRefresh.title
        content.body = "New items available in the shop!"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "shop_refresh",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    // MARK: - Badge Management
    
    func updateBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
            self.pendingNotifications = count
        }
    }
    
    func clearBadge() {
        updateBadgeCount(0)
    }
    
    // MARK: - Pending Notifications
    
    func cancelAllPendingNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    func cancelNotification(withIdentifier identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // MARK: - Settings
    
    func updateSettings(_ newSettings: NotificationSettings) {
        settings = newSettings
        saveSettings()
        
        // Update scheduled notifications based on new settings
        if newSettings.dailyReminder {
            scheduleDailyReminder()
        } else {
            cancelNotification(withIdentifier: "daily_reminder")
        }
    }
    
    // MARK: - Persistence
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let saved = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            settings = saved
        }
    }
}
