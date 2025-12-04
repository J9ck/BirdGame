//
//  AccountManager.swift
//  BirdGame3
//
//  User account management, authentication, and cloud saves
//

import Foundation
import SwiftUI
import AuthenticationServices
import CryptoKit

// MARK: - User Account

struct UserAccount: Codable, Identifiable {
    let id: String
    var username: String
    var displayName: String
    var email: String?
    var avatarURL: String?
    var createdAt: Date
    var lastLogin: Date
    var authProvider: AuthProvider
    var isVerified: Bool
    var isPremium: Bool
    var premiumExpiresAt: Date?
    var banStatus: BanStatus?
    
    // Privacy settings
    var privacySettings: PrivacySettings
    
    // Social
    var friendCode: String
    var friendCount: Int
    var blockedUsers: [String]
    
    // Stats summary
    var totalWins: Int
    var totalMatches: Int
    var seasonRank: String
    var globalRank: Int?
    
    var winRate: Double {
        guard totalMatches > 0 else { return 0 }
        return Double(totalWins) / Double(totalMatches) * 100
    }
    
    var isBanned: Bool {
        guard let ban = banStatus else { return false }
        if let until = ban.until {
            return until > Date()
        }
        return ban.isPermanent
    }
}

// MARK: - Auth Provider

enum AuthProvider: String, Codable {
    case apple
    case google
    case guest
    case email
    
    var displayName: String {
        switch self {
        case .apple: return "Apple"
        case .google: return "Google"
        case .guest: return "Guest"
        case .email: return "Email"
        }
    }
    
    var icon: String {
        switch self {
        case .apple: return "apple.logo"
        case .google: return "g.circle.fill"
        case .guest: return "person.fill.questionmark"
        case .email: return "envelope.fill"
        }
    }
}

// MARK: - Privacy Settings

struct PrivacySettings: Codable {
    var showOnlineStatus: Bool = true
    var allowFriendRequests: Bool = true
    var allowPartyInvites: PartyInviteSetting = .friendsOnly
    var showInLeaderboards: Bool = true
    var allowVoiceChat: Bool = true
    var allowDirectMessages: Bool = true
    var shareGameActivity: Bool = true
}

enum PartyInviteSetting: String, Codable {
    case anyone
    case friendsOnly
    case nobody
    
    var displayName: String {
        switch self {
        case .anyone: return "Anyone"
        case .friendsOnly: return "Friends Only"
        case .nobody: return "Nobody"
        }
    }
}

// MARK: - Ban Status

struct BanStatus: Codable {
    let reason: String
    let issuedAt: Date
    let until: Date?
    let isPermanent: Bool
    let appealable: Bool
}

// MARK: - Friend

struct Friend: Identifiable, Codable {
    let id: String
    var username: String
    var displayName: String
    var avatarURL: String?
    var isOnline: Bool
    var lastSeen: Date?
    var currentActivity: String?
    var friendshipDate: Date
    
    var statusColor: Color {
        isOnline ? .green : .gray
    }
}

// MARK: - Friend Request

struct FriendRequest: Identifiable, Codable {
    let id: String
    let fromUserId: String
    let fromUsername: String
    let fromDisplayName: String
    let sentAt: Date
    let message: String?
    
    var isExpired: Bool {
        Date().timeIntervalSince(sentAt) > 7 * 24 * 3600 // 7 days
    }
}

// MARK: - Cloud Save

struct CloudSave: Codable {
    let id: String
    let userId: String
    let timestamp: Date
    let version: Int
    let data: CloudSaveData
    let checksum: String
}

struct CloudSaveData: Codable {
    var playerStats: PlayerStats
    var currencyCoins: Int
    var currencyFeathers: Int
    var ownedSkins: Set<String>
    var equippedSkins: [String: String]
    var prestigeLevel: Int
    var currentLevel: Int
    var currentXP: Int
    var settings: GameSettings
    var achievements: [String: Bool]
    var nestData: Data? // Encoded Nest
    var openWorldState: Data? // Encoded PlayerWorldState
}

struct GameSettings: Codable {
    var musicVolume: Float
    var sfxVolume: Float
    var voiceChatEnabled: Bool
    var voiceChatVolume: Float
    var hapticsEnabled: Bool
    var pushNotificationsEnabled: Bool
    var language: String
}

// MARK: - Account Manager

class AccountManager: ObservableObject {
    static let shared = AccountManager()
    
    // MARK: - Published Properties
    
    @Published var currentAccount: UserAccount?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var authError: String?
    
    @Published var friends: [Friend] = []
    @Published var pendingRequests: [FriendRequest] = []
    @Published var sentRequests: [FriendRequest] = []
    
    @Published var lastCloudSave: Date?
    @Published var isSyncing: Bool = false
    
    // MARK: - Session Token
    
    private var sessionToken: String?
    private let tokenKey = "birdgame3_sessionToken"
    private let accountKey = "birdgame3_account"
    
    // MARK: - Initialization
    
    private init() {
        loadLocalAccount()
        if isLoggedIn {
            refreshAccountData()
        }
    }
    
    // MARK: - Authentication
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) {
        isLoading = true
        authError = nil
        
        let userId = credential.user
        let email = credential.email
        let fullName = credential.fullName
        
        // In production, send to server for verification
        // For now, create local account
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            let displayName = [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            let account = UserAccount(
                id: userId,
                username: "bird_\(userId.prefix(8))",
                displayName: displayName.isEmpty ? "Bird Warrior" : displayName,
                email: email,
                avatarURL: nil,
                createdAt: Date(),
                lastLogin: Date(),
                authProvider: .apple,
                isVerified: true,
                isPremium: false,
                premiumExpiresAt: nil,
                banStatus: nil,
                privacySettings: PrivacySettings(),
                friendCode: self?.generateFriendCode() ?? "XXXX-XXXX",
                friendCount: 0,
                blockedUsers: [],
                totalWins: 0,
                totalMatches: 0,
                seasonRank: "Egg 🥚",
                globalRank: nil
            )
            
            self?.completeLogin(account: account, token: UUID().uuidString)
        }
    }
    
    func signInAsGuest() {
        isLoading = true
        authError = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            let guestId = UUID().uuidString
            
            let account = UserAccount(
                id: guestId,
                username: "guest_\(guestId.prefix(8))",
                displayName: "Guest Bird",
                email: nil,
                avatarURL: nil,
                createdAt: Date(),
                lastLogin: Date(),
                authProvider: .guest,
                isVerified: false,
                isPremium: false,
                premiumExpiresAt: nil,
                banStatus: nil,
                privacySettings: PrivacySettings(),
                friendCode: self?.generateFriendCode() ?? "XXXX-XXXX",
                friendCount: 0,
                blockedUsers: [],
                totalWins: 0,
                totalMatches: 0,
                seasonRank: "Egg 🥚",
                globalRank: nil
            )
            
            self?.completeLogin(account: account, token: UUID().uuidString)
        }
    }
    
    func signInWithEmail(email: String, password: String) {
        isLoading = true
        authError = nil
        
        // Validate input
        guard isValidEmail(email) else {
            authError = "Invalid email address"
            isLoading = false
            return
        }
        
        guard password.count >= 8 else {
            authError = "Password must be at least 8 characters"
            isLoading = false
            return
        }
        
        // In production, authenticate with server
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            // Simulate successful login
            let userId = SHA256.hash(data: Data(email.utf8)).compactMap { String(format: "%02x", $0) }.joined().prefix(32)
            
            let account = UserAccount(
                id: String(userId),
                username: email.components(separatedBy: "@").first ?? "bird",
                displayName: email.components(separatedBy: "@").first?.capitalized ?? "Bird",
                email: email,
                avatarURL: nil,
                createdAt: Date(),
                lastLogin: Date(),
                authProvider: .email,
                isVerified: false,
                isPremium: false,
                premiumExpiresAt: nil,
                banStatus: nil,
                privacySettings: PrivacySettings(),
                friendCode: self?.generateFriendCode() ?? "XXXX-XXXX",
                friendCount: 0,
                blockedUsers: [],
                totalWins: 0,
                totalMatches: 0,
                seasonRank: "Egg 🥚",
                globalRank: nil
            )
            
            self?.completeLogin(account: account, token: UUID().uuidString)
        }
    }
    
    func signUp(email: String, password: String, username: String) {
        isLoading = true
        authError = nil
        
        // Validate input
        guard isValidEmail(email) else {
            authError = "Invalid email address"
            isLoading = false
            return
        }
        
        guard password.count >= 8 else {
            authError = "Password must be at least 8 characters"
            isLoading = false
            return
        }
        
        guard username.count >= 3 && username.count <= 20 else {
            authError = "Username must be 3-20 characters"
            isLoading = false
            return
        }
        
        guard isValidUsername(username) else {
            authError = "Username can only contain letters, numbers, and underscores"
            isLoading = false
            return
        }
        
        // In production, create account on server
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            let userId = UUID().uuidString
            
            let account = UserAccount(
                id: userId,
                username: username.lowercased(),
                displayName: username,
                email: email,
                avatarURL: nil,
                createdAt: Date(),
                lastLogin: Date(),
                authProvider: .email,
                isVerified: false,
                isPremium: false,
                premiumExpiresAt: nil,
                banStatus: nil,
                privacySettings: PrivacySettings(),
                friendCode: self?.generateFriendCode() ?? "XXXX-XXXX",
                friendCount: 0,
                blockedUsers: [],
                totalWins: 0,
                totalMatches: 0,
                seasonRank: "Egg 🥚",
                globalRank: nil
            )
            
            self?.completeLogin(account: account, token: UUID().uuidString)
            
            // Send verification email (simulated)
            VoiceChatManager.shared.speak("Account created! Check your email to verify.", priority: .normal)
        }
    }
    
    func signOut() {
        // Save data before signing out
        saveToCloud { [weak self] _ in
            self?.sessionToken = nil
            self?.currentAccount = nil
            self?.isLoggedIn = false
            self?.friends = []
            self?.pendingRequests = []
            
            UserDefaults.standard.removeObject(forKey: self?.tokenKey ?? "")
            UserDefaults.standard.removeObject(forKey: self?.accountKey ?? "")
        }
    }
    
    func deleteAccount(confirmation: String, completion: @escaping (Bool, String?) -> Void) {
        guard confirmation == "DELETE" else {
            completion(false, "Please type DELETE to confirm")
            return
        }
        
        isLoading = true
        
        // In production, delete from server
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.signOut()
            self?.isLoading = false
            completion(true, nil)
        }
    }
    
    private func completeLogin(account: UserAccount, token: String) {
        currentAccount = account
        sessionToken = token
        isLoggedIn = true
        isLoading = false
        
        saveLocalAccount()
        loadFriends()
        syncFromCloud()
    }
    
    // MARK: - Profile Management
    
    func updateDisplayName(_ name: String) -> Bool {
        guard var account = currentAccount else { return false }
        guard name.count >= 2 && name.count <= 30 else { return false }
        
        account.displayName = name
        currentAccount = account
        saveLocalAccount()
        
        return true
    }
    
    func updateUsername(_ username: String, completion: @escaping (Bool, String?) -> Void) {
        guard var account = currentAccount else {
            completion(false, "Not logged in")
            return
        }
        
        guard isValidUsername(username) else {
            completion(false, "Invalid username format")
            return
        }
        
        // In production, check availability on server
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            account.username = username.lowercased()
            self?.currentAccount = account
            self?.saveLocalAccount()
            completion(true, nil)
        }
    }
    
    func updatePrivacySettings(_ settings: PrivacySettings) {
        guard var account = currentAccount else { return }
        account.privacySettings = settings
        currentAccount = account
        saveLocalAccount()
    }
    
    // MARK: - Friends
    
    func sendFriendRequest(friendCode: String, completion: @escaping (Bool, String?) -> Void) {
        guard currentAccount != nil else {
            completion(false, "Not logged in")
            return
        }
        
        guard friendCode.count == 9 else { // XXXX-XXXX format
            completion(false, "Invalid friend code")
            return
        }
        
        // In production, send request to server
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            // Simulate success
            let request = FriendRequest(
                id: UUID().uuidString,
                fromUserId: self?.currentAccount?.id ?? "",
                fromUsername: self?.currentAccount?.username ?? "",
                fromDisplayName: self?.currentAccount?.displayName ?? "",
                sentAt: Date(),
                message: nil
            )
            self?.sentRequests.append(request)
            completion(true, nil)
        }
    }
    
    func acceptFriendRequest(_ request: FriendRequest) {
        // In production, accept on server
        pendingRequests.removeAll { $0.id == request.id }
        
        let friend = Friend(
            id: request.fromUserId,
            username: request.fromUsername,
            displayName: request.fromDisplayName,
            avatarURL: nil,
            isOnline: Bool.random(),
            lastSeen: Date(),
            currentActivity: nil,
            friendshipDate: Date()
        )
        
        friends.append(friend)
        
        if var account = currentAccount {
            account.friendCount = friends.count
            currentAccount = account
            saveLocalAccount()
        }
    }
    
    func declineFriendRequest(_ request: FriendRequest) {
        pendingRequests.removeAll { $0.id == request.id }
    }
    
    func removeFriend(_ friendId: String) {
        friends.removeAll { $0.id == friendId }
        
        if var account = currentAccount {
            account.friendCount = friends.count
            currentAccount = account
            saveLocalAccount()
        }
    }
    
    func blockUser(_ userId: String) {
        guard var account = currentAccount else { return }
        
        if !account.blockedUsers.contains(userId) {
            account.blockedUsers.append(userId)
            currentAccount = account
            saveLocalAccount()
        }
        
        // Also remove from friends if they were a friend
        removeFriend(userId)
    }
    
    func unblockUser(_ userId: String) {
        guard var account = currentAccount else { return }
        account.blockedUsers.removeAll { $0 == userId }
        currentAccount = account
        saveLocalAccount()
    }
    
    private func loadFriends() {
        // In production, load from server
        // Generate fake friends for demo
        friends = (0..<Int.random(in: 3...10)).map { i in
            Friend(
                id: UUID().uuidString,
                username: ["birdmaster", "pigeon_king", "eagle_eye", "crow_noir", "pelican_pete"][i % 5] + "\(i)",
                displayName: ["BirdMaster", "Pigeon King", "Eagle Eye", "Crow Noir", "Pelican Pete"][i % 5],
                avatarURL: nil,
                isOnline: Bool.random(),
                lastSeen: Bool.random() ? Date() : Date().addingTimeInterval(-Double.random(in: 300...86400)),
                currentActivity: Bool.random() ? ["In Match", "In Lobby", "Building Nest", "Open World"].randomElement() : nil,
                friendshipDate: Date().addingTimeInterval(-Double.random(in: 86400...2592000))
            )
        }
        
        // Generate fake pending requests
        pendingRequests = (0..<Int.random(in: 0...3)).map { _ in
            FriendRequest(
                id: UUID().uuidString,
                fromUserId: UUID().uuidString,
                fromUsername: "new_bird_\(Int.random(in: 100...999))",
                fromDisplayName: "New Bird",
                sentAt: Date().addingTimeInterval(-Double.random(in: 3600...172800)),
                message: ["Want to squad up?", "GG last match!", nil].randomElement() ?? nil
            )
        }
    }
    
    // MARK: - Cloud Sync
    
    func saveToCloud(completion: ((Bool) -> Void)? = nil) {
        guard let account = currentAccount else {
            completion?(false)
            return
        }
        
        isSyncing = true
        
        // Gather all game data
        let saveData = CloudSaveData(
            playerStats: GameState().playerStats, // Would need proper access
            currencyCoins: CurrencyManager.shared.coins,
            currencyFeathers: CurrencyManager.shared.feathers,
            ownedSkins: SkinManager.shared.ownedSkins,
            equippedSkins: SkinManager.shared.equippedSkins,
            prestigeLevel: PrestigeManager.shared.prestigeLevel,
            currentLevel: PrestigeManager.shared.currentLevel,
            currentXP: PrestigeManager.shared.currentXP,
            settings: GameSettings(
                musicVolume: SoundManager.shared.musicVolume,
                sfxVolume: SoundManager.shared.sfxVolume,
                voiceChatEnabled: VoiceChatManager.shared.isEnabled,
                voiceChatVolume: VoiceChatManager.shared.volume,
                hapticsEnabled: SoundManager.shared.hapticsEnabled,
                pushNotificationsEnabled: true,
                language: "en"
            ),
            achievements: [:],
            nestData: nil,
            openWorldState: nil
        )
        
        // In production, upload to server
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.lastCloudSave = Date()
            self?.isSyncing = false
            completion?(true)
        }
    }
    
    func syncFromCloud(completion: ((Bool) -> Void)? = nil) {
        guard currentAccount != nil else {
            completion?(false)
            return
        }
        
        isSyncing = true
        
        // In production, download from server and apply
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.lastCloudSave = Date()
            self?.isSyncing = false
            completion?(true)
        }
    }
    
    // MARK: - Account Data Updates
    
    func recordMatchResult(won: Bool) {
        guard var account = currentAccount else { return }
        
        account.totalMatches += 1
        if won {
            account.totalWins += 1
        }
        
        // Update rank based on wins
        account.seasonRank = calculateRank(wins: account.totalWins)
        
        currentAccount = account
        saveLocalAccount()
    }
    
    private func calculateRank(wins: Int) -> String {
        switch wins {
        case 0: return "Egg 🥚"
        case 1...5: return "Hatchling 🐣"
        case 6...15: return "Fledgling 🐤"
        case 16...30: return "Skyward 🐦"
        case 31...50: return "Soaring 🦅"
        case 51...100: return "Apex 🦉"
        case 101...200: return "Legend 👑"
        default: return "Mythic ✨"
        }
    }
    
    func refreshAccountData() {
        // In production, refresh from server
        loadFriends()
    }
    
    // MARK: - Local Storage
    
    private func saveLocalAccount() {
        guard let account = currentAccount,
              let data = try? JSONEncoder().encode(account) else { return }
        
        UserDefaults.standard.set(data, forKey: accountKey)
        
        if let token = sessionToken {
            UserDefaults.standard.set(token, forKey: tokenKey)
        }
    }
    
    private func loadLocalAccount() {
        guard let data = UserDefaults.standard.data(forKey: accountKey),
              let account = try? JSONDecoder().decode(UserAccount.self, from: data) else {
            return
        }
        
        sessionToken = UserDefaults.standard.string(forKey: tokenKey)
        currentAccount = account
        isLoggedIn = true
    }
    
    // MARK: - Helpers
    
    private func generateFriendCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let part1 = String((0..<4).map { _ in chars.randomElement()! })
        let part2 = String((0..<4).map { _ in chars.randomElement()! })
        return "\(part1)-\(part2)"
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
    
    private func isValidUsername(_ username: String) -> Bool {
        let regex = "^[a-zA-Z0-9_]+$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: username)
    }
}
