//
//  SupabaseManager.swift
//  BirdGame3
//
//  Supabase backend integration for authentication, database, and real-time features
//
//  Setup Instructions:
//  1. Create a Supabase project at https://supabase.com
//  2. Copy your project URL and anon key
//  3. Replace the placeholder values in Configuration
//  4. Run the SQL schema in your Supabase SQL editor
//

import Foundation
import Combine

// MARK: - Configuration

/// Supabase configuration - Your Bird Game 3 Supabase project
struct SupabaseConfig {
    /// Your Supabase project URL
    static let projectURL = "https://xwuaipfwvdlrrqhzahey.supabase.co"
    
    /// Your Supabase anon/public key (safe for client-side use with RLS enabled)
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh3dWFpcGZ3dmRscnJxaHphaGV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ4NTkzMjUsImV4cCI6MjA4MDQzNTMyNX0.89ZZ5lnE8_1bye5nyzaW2O0Aie3ikDVItpu1VlHM6Y0"
    
    /// REST API base URL
    static var restURL: String { "\(projectURL)/rest/v1" }
    
    /// Auth API base URL
    static var authURL: String { "\(projectURL)/auth/v1" }
    
    /// Realtime WebSocket URL
    static var realtimeURL: String { projectURL.replacingOccurrences(of: "https://", with: "wss://") + "/realtime/v1/websocket" }
    
    /// Storage API base URL
    static var storageURL: String { "\(projectURL)/storage/v1" }
}

// MARK: - Supabase Error

enum SupabaseError: Error, LocalizedError {
    case notConfigured
    case authenticationFailed(String)
    case networkError(Error)
    case databaseError(String)
    case notFound
    case unauthorized
    case serverError(Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase is not configured. Please add your project credentials."
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .notFound:
            return "Resource not found"
        case .unauthorized:
            return "Unauthorized access"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

// MARK: - Auth Response Models

struct SupabaseAuthResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String
    let user: SupabaseUser
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case user
    }
}

struct SupabaseUser: Codable {
    let id: String
    let email: String?
    let phone: String?
    let createdAt: String
    let updatedAt: String?
    let appMetadata: AppMetadata?
    let userMetadata: UserMetadata?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case phone
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case appMetadata = "app_metadata"
        case userMetadata = "user_metadata"
    }
}

struct AppMetadata: Codable {
    let provider: String?
}

struct UserMetadata: Codable {
    let displayName: String?
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}

// MARK: - Database Models

/// Player profile stored in Supabase
struct PlayerProfile: Codable {
    let id: String
    var username: String
    var displayName: String
    var avatarUrl: String?
    var friendCode: String
    var level: Int
    var prestigeLevel: Int
    var totalXp: Int
    var coins: Int
    var feathers: Int
    var totalWins: Int
    var totalMatches: Int
    var totalKills: Int
    var seasonRank: String
    var isPremium: Bool
    var premiumExpiresAt: String?
    var createdAt: String
    var updatedAt: String
    var lastOnline: String
    var isOnline: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case friendCode = "friend_code"
        case level
        case prestigeLevel = "prestige_level"
        case totalXp = "total_xp"
        case coins
        case feathers
        case totalWins = "total_wins"
        case totalMatches = "total_matches"
        case totalKills = "total_kills"
        case seasonRank = "season_rank"
        case isPremium = "is_premium"
        case premiumExpiresAt = "premium_expires_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastOnline = "last_online"
        case isOnline = "is_online"
    }
}

/// Player inventory (skins, emotes, etc.)
struct PlayerInventory: Codable {
    let id: String
    let playerId: String
    var ownedSkins: [String]
    var ownedEmotes: [String]
    var ownedTrails: [String]
    var equippedSkins: [String: String] // birdType -> skinId
    var equippedEmote: String?
    var equippedTrail: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case playerId = "player_id"
        case ownedSkins = "owned_skins"
        case ownedEmotes = "owned_emotes"
        case ownedTrails = "owned_trails"
        case equippedSkins = "equipped_skins"
        case equippedEmote = "equipped_emote"
        case equippedTrail = "equipped_trail"
    }
}

/// Friend relationship
struct FriendRelation: Codable {
    let id: String
    let playerId: String
    let friendId: String
    let status: String // "pending", "accepted", "blocked"
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case playerId = "player_id"
        case friendId = "friend_id"
        case status
        case createdAt = "created_at"
    }
}

/// Game match record
struct MatchRecord: Codable {
    let id: String
    let gameMode: String
    let winnerId: String?
    let playerIds: [String]
    let duration: Int
    let startedAt: String
    let endedAt: String?
    let mapId: String?
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case gameMode = "game_mode"
        case winnerId = "winner_id"
        case playerIds = "player_ids"
        case duration
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case mapId = "map_id"
        case metadata
    }
}

/// Player match stats for a specific match
struct PlayerMatchStats: Codable {
    let id: String
    let matchId: String
    let playerId: String
    let birdType: String
    let skinId: String
    let kills: Int
    let deaths: Int
    let damageDealt: Int
    let damageTaken: Int
    let placement: Int?
    let xpEarned: Int
    let coinsEarned: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case matchId = "match_id"
        case playerId = "player_id"
        case birdType = "bird_type"
        case skinId = "skin_id"
        case kills
        case deaths
        case damageDealt = "damage_dealt"
        case damageTaken = "damage_taken"
        case placement
        case xpEarned = "xp_earned"
        case coinsEarned = "coins_earned"
    }
}

/// Nest data for open world
struct NestData: Codable {
    let id: String
    let playerId: String
    var locationX: Double
    var locationY: Double
    var biome: String
    var level: Int
    var components: [String] // JSON array of component types
    var resources: [String: Int]
    var lastRaided: String?
    var createdAt: String
    var updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case playerId = "player_id"
        case locationX = "location_x"
        case locationY = "location_y"
        case biome
        case level
        case components
        case resources
        case lastRaided = "last_raided"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Flock (clan/guild)
struct FlockData: Codable {
    let id: String
    var name: String
    var tag: String
    var description: String
    var leaderId: String
    var memberCount: Int
    var maxMembers: Int
    var level: Int
    var totalXp: Int
    var iconId: String?
    var isRecruiting: Bool
    var minLevelToJoin: Int
    var createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case tag
        case description
        case leaderId = "leader_id"
        case memberCount = "member_count"
        case maxMembers = "max_members"
        case level
        case totalXp = "total_xp"
        case iconId = "icon_id"
        case isRecruiting = "is_recruiting"
        case minLevelToJoin = "min_level_to_join"
        case createdAt = "created_at"
    }
}

/// Chat message
struct ChatMessage: Codable, Identifiable {
    let id: String
    let channelId: String
    let senderId: String
    let senderName: String
    var content: String
    let messageType: String // "text", "emote", "system"
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case channelId = "channel_id"
        case senderId = "sender_id"
        case senderName = "sender_name"
        case content
        case messageType = "message_type"
        case createdAt = "created_at"
    }
}

// MARK: - Supabase Manager

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    // MARK: - Published Properties
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: SupabaseUser?
    @Published var currentProfile: PlayerProfile?
    @Published var isLoading: Bool = false
    @Published var error: SupabaseError?
    
    // MARK: - Private Properties
    
    private var accessToken: String?
    private var refreshToken: String?
    private let session: URLSession
    private var tokenExpiresAt: Date?
    private var cancellables = Set<AnyCancellable>()
    
    // Storage keys
    private let accessTokenKey = "supabase_access_token"
    private let refreshTokenKey = "supabase_refresh_token"
    private let tokenExpiryKey = "supabase_token_expiry"
    private let userIdKey = "supabase_user_id"
    
    // MARK: - Initialization
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
        
        // Load saved tokens
        loadTokens()
        
        // Auto-refresh token if needed
        if isAuthenticated {
            Task {
                await refreshTokenIfNeeded()
            }
        }
    }
    
    // MARK: - Configuration Check
    
    var isConfigured: Bool {
        return SupabaseConfig.projectURL != "YOUR_SUPABASE_PROJECT_URL" &&
               SupabaseConfig.anonKey != "YOUR_SUPABASE_ANON_KEY"
    }
    
    // MARK: - Authentication
    
    /// Sign up with email and password
    func signUp(email: String, password: String, username: String) async throws -> SupabaseUser {
        guard isConfigured else { throw SupabaseError.notConfigured }
        
        let url = URL(string: "\(SupabaseConfig.authURL)/signup")!
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "data": [
                "display_name": username
            ]
        ]
        
        let response: SupabaseAuthResponse = try await postRequest(url: url, body: body, authenticated: false)
        
        // Save tokens
        saveTokens(access: response.accessToken, refresh: response.refreshToken, expiresIn: response.expiresIn)
        
        DispatchQueue.main.async {
            self.currentUser = response.user
            self.isAuthenticated = true
        }
        
        // Create player profile
        try await createPlayerProfile(userId: response.user.id, username: username, email: email)
        
        return response.user
    }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> SupabaseUser {
        guard isConfigured else { throw SupabaseError.notConfigured }
        
        let url = URL(string: "\(SupabaseConfig.authURL)/token?grant_type=password")!
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        let response: SupabaseAuthResponse = try await postRequest(url: url, body: body, authenticated: false)
        
        // Save tokens
        saveTokens(access: response.accessToken, refresh: response.refreshToken, expiresIn: response.expiresIn)
        
        DispatchQueue.main.async {
            self.currentUser = response.user
            self.isAuthenticated = true
        }
        
        // Load player profile
        try await loadPlayerProfile(userId: response.user.id)
        
        return response.user
    }
    
    /// Sign in anonymously (guest)
    func signInAnonymously() async throws -> SupabaseUser {
        guard isConfigured else { throw SupabaseError.notConfigured }
        
        let url = URL(string: "\(SupabaseConfig.authURL)/signup")!
        
        // Generate a random email for anonymous user
        let anonymousEmail = "guest_\(UUID().uuidString.prefix(8))@birdgame3.temp"
        let anonymousPassword = UUID().uuidString
        
        let body: [String: Any] = [
            "email": anonymousEmail,
            "password": anonymousPassword,
            "data": [
                "display_name": "Guest Bird",
                "is_anonymous": true
            ]
        ]
        
        let response: SupabaseAuthResponse = try await postRequest(url: url, body: body, authenticated: false)
        
        saveTokens(access: response.accessToken, refresh: response.refreshToken, expiresIn: response.expiresIn)
        
        DispatchQueue.main.async {
            self.currentUser = response.user
            self.isAuthenticated = true
        }
        
        // Create player profile
        try await createPlayerProfile(userId: response.user.id, username: "Guest_\(response.user.id.prefix(6))", email: nil)
        
        return response.user
    }
    
    /// Sign out
    func signOut() async {
        guard isConfigured, let token = accessToken else { return }
        
        let url = URL(string: "\(SupabaseConfig.authURL)/logout")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        
        _ = try? await session.data(for: request)
        
        // Clear local state
        clearTokens()
        
        DispatchQueue.main.async {
            self.currentUser = nil
            self.currentProfile = nil
            self.isAuthenticated = false
        }
    }
    
    /// Refresh access token
    func refreshTokenIfNeeded() async {
        guard let expiry = tokenExpiresAt, let refresh = refreshToken else { return }
        
        // Refresh if token expires in less than 5 minutes
        if expiry.timeIntervalSinceNow < 300 {
            do {
                try await refreshAccessToken(refreshToken: refresh)
            } catch {
                // Token refresh failed, sign out
                await signOut()
            }
        }
    }
    
    private func refreshAccessToken(refreshToken: String) async throws {
        guard isConfigured else { throw SupabaseError.notConfigured }
        
        let url = URL(string: "\(SupabaseConfig.authURL)/token?grant_type=refresh_token")!
        
        let body: [String: Any] = [
            "refresh_token": refreshToken
        ]
        
        let response: SupabaseAuthResponse = try await postRequest(url: url, body: body, authenticated: false)
        
        saveTokens(access: response.accessToken, refresh: response.refreshToken, expiresIn: response.expiresIn)
        
        DispatchQueue.main.async {
            self.currentUser = response.user
        }
    }
    
    // MARK: - Player Profile
    
    private func createPlayerProfile(userId: String, username: String, email: String?) async throws {
        guard isConfigured else { throw SupabaseError.notConfigured }
        
        let friendCode = generateFriendCode()
        
        let profile: [String: Any] = [
            "id": userId,
            "username": username.lowercased(),
            "display_name": username,
            "friend_code": friendCode,
            "level": 1,
            "prestige_level": 0,
            "total_xp": 0,
            "coins": 500, // Starting coins
            "feathers": 10, // Starting premium currency
            "total_wins": 0,
            "total_matches": 0,
            "total_kills": 0,
            "season_rank": "Egg 🥚",
            "is_premium": false,
            "is_online": true
        ]
        
        let url = URL(string: "\(SupabaseConfig.restURL)/player_profiles")!
        let _: PlayerProfile = try await postRequest(url: url, body: profile, authenticated: true)
        
        // Also create inventory
        let inventory: [String: Any] = [
            "player_id": userId,
            "owned_skins": ["pigeon_default", "crow_default", "eagle_default", "pelican_default", "owl_default"],
            "owned_emotes": ["wave", "taunt"],
            "owned_trails": [],
            "equipped_skins": [:],
            "equipped_emote": "wave"
        ]
        
        let inventoryUrl = URL(string: "\(SupabaseConfig.restURL)/player_inventory")!
        let _: PlayerInventory = try await postRequest(url: inventoryUrl, body: inventory, authenticated: true)
        
        // Load the created profile
        try await loadPlayerProfile(userId: userId)
    }
    
    func loadPlayerProfile(userId: String) async throws {
        guard isConfigured else { throw SupabaseError.notConfigured }
        
        let url = URL(string: "\(SupabaseConfig.restURL)/player_profiles?id=eq.\(userId)&select=*")!
        
        let profiles: [PlayerProfile] = try await getRequest(url: url, authenticated: true)
        
        guard let profile = profiles.first else {
            throw SupabaseError.notFound
        }
        
        DispatchQueue.main.async {
            self.currentProfile = profile
        }
    }
    
    func updatePlayerProfile(_ updates: [String: Any]) async throws {
        guard isConfigured, let userId = currentUser?.id else {
            throw SupabaseError.unauthorized
        }
        
        var mutableUpdates = updates
        mutableUpdates["updated_at"] = ISO8601DateFormatter().string(from: Date())
        
        let url = URL(string: "\(SupabaseConfig.restURL)/player_profiles?id=eq.\(userId)")!
        let _: [PlayerProfile] = try await patchRequest(url: url, body: mutableUpdates, authenticated: true)
        
        // Reload profile
        try await loadPlayerProfile(userId: userId)
    }
    
    func setOnlineStatus(_ isOnline: Bool) async {
        guard currentUser != nil else { return }
        
        try? await updatePlayerProfile([
            "is_online": isOnline,
            "last_online": ISO8601DateFormatter().string(from: Date())
        ])
    }
    
    // MARK: - Currency
    
    func addCoins(_ amount: Int) async throws {
        guard let profile = currentProfile else { throw SupabaseError.unauthorized }
        
        try await updatePlayerProfile([
            "coins": profile.coins + amount
        ])
    }
    
    func spendCoins(_ amount: Int) async throws -> Bool {
        guard let profile = currentProfile else { throw SupabaseError.unauthorized }
        
        if profile.coins >= amount {
            try await updatePlayerProfile([
                "coins": profile.coins - amount
            ])
            return true
        }
        return false
    }
    
    func addFeathers(_ amount: Int) async throws {
        guard let profile = currentProfile else { throw SupabaseError.unauthorized }
        
        try await updatePlayerProfile([
            "feathers": profile.feathers + amount
        ])
    }
    
    // MARK: - Progression
    
    /// XP required for a given level using a simple exponential curve.
    /// Base XP is 1000 for level 1 and increases by 10% per level.
    private func calculateXPRequired(for level: Int) -> Int {
        guard level > 1 else { return 1000 }
        let base: Double = 1000
        let multiplier: Double = 1.1
        let required = base * pow(multiplier, Double(level - 1))
        return Int(required.rounded())
    }
    
    func addXP(_ amount: Int) async throws {
        guard let profile = currentProfile else { throw SupabaseError.unauthorized }
        
        let newXP = profile.totalXp + amount
        var newLevel = profile.level
        var newPrestige = profile.prestigeLevel
        
        // Calculate level ups using simplified XP curve matching PrestigeManager
        // XP required increases with level: base * multiplier^(level-1)
        let xpForLevel = calculateXPRequired(for: newLevel)
        if newXP >= xpForLevel && newLevel < 50 {
            newLevel += 1
        } else if newXP >= xpForLevel && newLevel >= 50 {
            // Prestige
            newPrestige += 1
            newLevel = 1
        }
        
        try await updatePlayerProfile([
            "total_xp": newXP,
            "level": newLevel,
            "prestige_level": newPrestige
        ])
    }
    
    func recordMatchResult(won: Bool, kills: Int, xpEarned: Int, coinsEarned: Int) async throws {
        guard let profile = currentProfile else { throw SupabaseError.unauthorized }
        
        try await updatePlayerProfile([
            "total_matches": profile.totalMatches + 1,
            "total_wins": profile.totalWins + (won ? 1 : 0),
            "total_kills": profile.totalKills + kills,
            "total_xp": profile.totalXp + xpEarned,
            "coins": profile.coins + coinsEarned
        ])
    }
    
    // MARK: - Friends
    
    func sendFriendRequest(friendCode: String) async throws {
        guard isConfigured, let userId = currentUser?.id else {
            throw SupabaseError.unauthorized
        }
        
        // Find player by friend code
        let searchUrl = URL(string: "\(SupabaseConfig.restURL)/player_profiles?friend_code=eq.\(friendCode)&select=id")!
        let players: [PlayerProfile] = try await getRequest(url: searchUrl, authenticated: true)
        
        guard let friend = players.first else {
            throw SupabaseError.notFound
        }
        
        // Create friend request
        let request: [String: Any] = [
            "player_id": userId,
            "friend_id": friend.id,
            "status": "pending"
        ]
        
        let url = URL(string: "\(SupabaseConfig.restURL)/friend_relations")!
        let _: FriendRelation = try await postRequest(url: url, body: request, authenticated: true)
    }
    
    func acceptFriendRequest(requestId: String) async throws {
        guard isConfigured else { throw SupabaseError.notConfigured }
        
        let url = URL(string: "\(SupabaseConfig.restURL)/friend_relations?id=eq.\(requestId)")!
        let _: [FriendRelation] = try await patchRequest(url: url, body: ["status": "accepted"], authenticated: true)
    }
    
    func getFriends() async throws -> [PlayerProfile] {
        guard isConfigured, let userId = currentUser?.id else {
            throw SupabaseError.unauthorized
        }
        
        // Get accepted friend relations
        let url = URL(string: "\(SupabaseConfig.restURL)/friend_relations?player_id=eq.\(userId)&status=eq.accepted&select=friend_id")!
        let relations: [FriendRelation] = try await getRequest(url: url, authenticated: true)
        
        // Get friend profiles
        let friendIds = relations.map { $0.friendId }
        if friendIds.isEmpty { return [] }
        
        let idsParam = friendIds.joined(separator: ",")
        let profilesUrl = URL(string: "\(SupabaseConfig.restURL)/player_profiles?id=in.(\(idsParam))&select=*")!
        let profiles: [PlayerProfile] = try await getRequest(url: profilesUrl, authenticated: true)
        
        return profiles
    }
    
    // MARK: - Inventory
    
    func getInventory() async throws -> PlayerInventory {
        guard isConfigured, let userId = currentUser?.id else {
            throw SupabaseError.unauthorized
        }
        
        let url = URL(string: "\(SupabaseConfig.restURL)/player_inventory?player_id=eq.\(userId)&select=*")!
        let inventories: [PlayerInventory] = try await getRequest(url: url, authenticated: true)
        
        guard let inventory = inventories.first else {
            throw SupabaseError.notFound
        }
        
        return inventory
    }
    
    func purchaseSkin(skinId: String, cost: Int, currencyType: String) async throws -> Bool {
        guard isConfigured else { throw SupabaseError.notConfigured }
        
        // Spend currency
        if currencyType == "coins" {
            let success = try await spendCoins(cost)
            if !success { return false }
        } else {
            guard let profile = currentProfile, profile.feathers >= cost else { return false }
            try await updatePlayerProfile(["feathers": profile.feathers - cost])
        }
        
        // Add skin to inventory
        var inventory = try await getInventory()
        if !inventory.ownedSkins.contains(skinId) {
            inventory.ownedSkins.append(skinId)
            
            let url = URL(string: "\(SupabaseConfig.restURL)/player_inventory?player_id=eq.\(currentUser!.id)")!
            let _: [PlayerInventory] = try await patchRequest(url: url, body: ["owned_skins": inventory.ownedSkins], authenticated: true)
        }
        
        return true
    }
    
    // MARK: - Nest / Open World
    
    func saveNest(_ nest: NestData) async throws {
        guard isConfigured, let userId = currentUser?.id else {
            throw SupabaseError.unauthorized
        }
        
        let nestData: [String: Any] = [
            "player_id": userId,
            "location_x": nest.locationX,
            "location_y": nest.locationY,
            "biome": nest.biome,
            "level": nest.level,
            "components": nest.components,
            "resources": nest.resources,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        // Upsert nest
        let url = URL(string: "\(SupabaseConfig.restURL)/nests?player_id=eq.\(userId)")!
        let _: [NestData] = try await patchRequest(url: url, body: nestData, authenticated: true)
    }
    
    func loadNest() async throws -> NestData? {
        guard isConfigured, let userId = currentUser?.id else {
            throw SupabaseError.unauthorized
        }
        
        let url = URL(string: "\(SupabaseConfig.restURL)/nests?player_id=eq.\(userId)&select=*")!
        let nests: [NestData] = try await getRequest(url: url, authenticated: true)
        
        return nests.first
    }
    
    // MARK: - Chat
    
    func sendChatMessage(channelId: String, content: String, messageType: String = "text") async throws {
        guard isConfigured, let userId = currentUser?.id, let profile = currentProfile else {
            throw SupabaseError.unauthorized
        }
        
        let message: [String: Any] = [
            "channel_id": channelId,
            "sender_id": userId,
            "sender_name": profile.displayName,
            "content": content,
            "message_type": messageType
        ]
        
        let url = URL(string: "\(SupabaseConfig.restURL)/chat_messages")!
        let _: ChatMessage = try await postRequest(url: url, body: message, authenticated: true)
    }
    
    func getChatMessages(channelId: String, limit: Int = 50) async throws -> [ChatMessage] {
        guard isConfigured else { throw SupabaseError.notConfigured }
        
        let url = URL(string: "\(SupabaseConfig.restURL)/chat_messages?channel_id=eq.\(channelId)&order=created_at.desc&limit=\(limit)")!
        let messages: [ChatMessage] = try await getRequest(url: url, authenticated: true)
        
        return messages.reversed()
    }
    
    // MARK: - Leaderboards
    
    func getLeaderboard(type: String, limit: Int = 100) async throws -> [PlayerProfile] {
        guard isConfigured else { throw SupabaseError.notConfigured }
        
        let orderBy: String
        switch type {
        case "wins":
            orderBy = "total_wins.desc"
        case "kills":
            orderBy = "total_kills.desc"
        case "level":
            orderBy = "prestige_level.desc,level.desc"
        default:
            orderBy = "total_xp.desc"
        }
        
        let url = URL(string: "\(SupabaseConfig.restURL)/player_profiles?order=\(orderBy)&limit=\(limit)&select=id,username,display_name,avatar_url,level,prestige_level,total_wins,total_kills,season_rank")!
        let profiles: [PlayerProfile] = try await getRequest(url: url, authenticated: true)
        
        return profiles
    }
    
    // MARK: - HTTP Helpers
    
    private func getRequest<T: Decodable>(url: URL, authenticated: Bool) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addHeaders(to: &request, authenticated: authenticated)
        
        return try await performRequest(request)
    }
    
    private func postRequest<T: Decodable>(url: URL, body: [String: Any], authenticated: Bool) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        addHeaders(to: &request, authenticated: authenticated)
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        return try await performRequest(request)
    }
    
    private func patchRequest<T: Decodable>(url: URL, body: [String: Any], authenticated: Bool) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        addHeaders(to: &request, authenticated: authenticated)
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        return try await performRequest(request)
    }
    
    private func addHeaders(to request: inout URLRequest, authenticated: Bool) {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        
        if authenticated, let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
    
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError(NSError(domain: "Invalid response", code: -1))
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    // Handle array vs single object response
                    let decoder = JSONDecoder()
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw SupabaseError.decodingError
                }
            case 401:
                throw SupabaseError.unauthorized
            case 404:
                throw SupabaseError.notFound
            default:
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorData["message"] as? String {
                    throw SupabaseError.databaseError(message)
                }
                throw SupabaseError.serverError(httpResponse.statusCode)
            }
        } catch let error as SupabaseError {
            throw error
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    // MARK: - Token Management
    
    private func saveTokens(access: String, refresh: String, expiresIn: Int) {
        accessToken = access
        refreshToken = refresh
        tokenExpiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
        
        UserDefaults.standard.set(access, forKey: accessTokenKey)
        UserDefaults.standard.set(refresh, forKey: refreshTokenKey)
        UserDefaults.standard.set(tokenExpiresAt, forKey: tokenExpiryKey)
    }
    
    private func loadTokens() {
        accessToken = UserDefaults.standard.string(forKey: accessTokenKey)
        refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey)
        tokenExpiresAt = UserDefaults.standard.object(forKey: tokenExpiryKey) as? Date
        
        isAuthenticated = accessToken != nil
    }
    
    private func clearTokens() {
        accessToken = nil
        refreshToken = nil
        tokenExpiresAt = nil
        
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: tokenExpiryKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
    }
    
    // MARK: - Helpers
    
    private func generateFriendCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let part1 = String((0..<4).map { _ in chars.randomElement()! })
        let part2 = String((0..<4).map { _ in chars.randomElement()! })
        return "\(part1)-\(part2)"
    }
}

// MARK: - SQL Schema for Supabase

/*
 
 Run this SQL in your Supabase SQL Editor to create the required tables:
 
 -- Enable UUID extension
 CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

 -- Player Profiles
 CREATE TABLE player_profiles (
     id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
     username TEXT UNIQUE NOT NULL,
     display_name TEXT NOT NULL,
     avatar_url TEXT,
     friend_code TEXT UNIQUE NOT NULL,
     level INTEGER DEFAULT 1,
     prestige_level INTEGER DEFAULT 0,
     total_xp INTEGER DEFAULT 0,
     coins INTEGER DEFAULT 500,
     feathers INTEGER DEFAULT 10,
     total_wins INTEGER DEFAULT 0,
     total_matches INTEGER DEFAULT 0,
     total_kills INTEGER DEFAULT 0,
     season_rank TEXT DEFAULT 'Egg 🥚',
     is_premium BOOLEAN DEFAULT FALSE,
     premium_expires_at TIMESTAMPTZ,
     created_at TIMESTAMPTZ DEFAULT NOW(),
     updated_at TIMESTAMPTZ DEFAULT NOW(),
     last_online TIMESTAMPTZ DEFAULT NOW(),
     is_online BOOLEAN DEFAULT TRUE
 );

 -- Player Inventory
 CREATE TABLE player_inventory (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     player_id UUID REFERENCES player_profiles(id) ON DELETE CASCADE,
     owned_skins TEXT[] DEFAULT ARRAY['pigeon_default', 'crow_default', 'eagle_default', 'pelican_default', 'owl_default'],
     owned_emotes TEXT[] DEFAULT ARRAY['wave', 'taunt'],
     owned_trails TEXT[] DEFAULT ARRAY[]::TEXT[],
     equipped_skins JSONB DEFAULT '{}',
     equipped_emote TEXT DEFAULT 'wave',
     equipped_trail TEXT,
     UNIQUE(player_id)
 );

 -- Friend Relations
 CREATE TABLE friend_relations (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     player_id UUID REFERENCES player_profiles(id) ON DELETE CASCADE,
     friend_id UUID REFERENCES player_profiles(id) ON DELETE CASCADE,
     status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked')),
     created_at TIMESTAMPTZ DEFAULT NOW(),
     UNIQUE(player_id, friend_id)
 );

 -- Nests (Open World)
 CREATE TABLE nests (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     player_id UUID REFERENCES player_profiles(id) ON DELETE CASCADE,
     location_x DOUBLE PRECISION NOT NULL,
     location_y DOUBLE PRECISION NOT NULL,
     biome TEXT NOT NULL,
     level INTEGER DEFAULT 1,
     components TEXT[] DEFAULT ARRAY[]::TEXT[],
     resources JSONB DEFAULT '{}',
     last_raided TIMESTAMPTZ,
     created_at TIMESTAMPTZ DEFAULT NOW(),
     updated_at TIMESTAMPTZ DEFAULT NOW(),
     UNIQUE(player_id)
 );

 -- Matches
 CREATE TABLE matches (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     game_mode TEXT NOT NULL,
     winner_id UUID REFERENCES player_profiles(id),
     player_ids UUID[] NOT NULL,
     duration INTEGER,
     started_at TIMESTAMPTZ DEFAULT NOW(),
     ended_at TIMESTAMPTZ,
     map_id TEXT,
     metadata JSONB
 );

 -- Player Match Stats
 CREATE TABLE player_match_stats (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
     player_id UUID REFERENCES player_profiles(id) ON DELETE CASCADE,
     bird_type TEXT NOT NULL,
     skin_id TEXT NOT NULL,
     kills INTEGER DEFAULT 0,
     deaths INTEGER DEFAULT 0,
     damage_dealt INTEGER DEFAULT 0,
     damage_taken INTEGER DEFAULT 0,
     placement INTEGER,
     xp_earned INTEGER DEFAULT 0,
     coins_earned INTEGER DEFAULT 0
 );

 -- Flocks (Clans/Guilds)
 CREATE TABLE flocks (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     name TEXT UNIQUE NOT NULL,
     tag TEXT UNIQUE NOT NULL,
     description TEXT,
     leader_id UUID REFERENCES player_profiles(id),
     member_count INTEGER DEFAULT 1,
     max_members INTEGER DEFAULT 50,
     level INTEGER DEFAULT 1,
     total_xp INTEGER DEFAULT 0,
     icon_id TEXT,
     is_recruiting BOOLEAN DEFAULT TRUE,
     min_level_to_join INTEGER DEFAULT 1,
     created_at TIMESTAMPTZ DEFAULT NOW()
 );

 -- Flock Members
 CREATE TABLE flock_members (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     flock_id UUID REFERENCES flocks(id) ON DELETE CASCADE,
     player_id UUID REFERENCES player_profiles(id) ON DELETE CASCADE,
     role TEXT DEFAULT 'member' CHECK (role IN ('leader', 'officer', 'member')),
     joined_at TIMESTAMPTZ DEFAULT NOW(),
     UNIQUE(player_id)
 );

 -- Chat Messages
 CREATE TABLE chat_messages (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     channel_id TEXT NOT NULL,
     sender_id UUID REFERENCES player_profiles(id) ON DELETE SET NULL,
     sender_name TEXT NOT NULL,
     content TEXT NOT NULL,
     message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'emote', 'system')),
     created_at TIMESTAMPTZ DEFAULT NOW()
 );

 -- Reports
 CREATE TABLE reports (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     reporter_id UUID REFERENCES player_profiles(id),
     reported_id UUID REFERENCES player_profiles(id),
     reason TEXT NOT NULL,
     description TEXT,
     status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'action_taken', 'dismissed')),
     created_at TIMESTAMPTZ DEFAULT NOW()
 );

 -- Enable Row Level Security
 ALTER TABLE player_profiles ENABLE ROW LEVEL SECURITY;
 ALTER TABLE player_inventory ENABLE ROW LEVEL SECURITY;
 ALTER TABLE friend_relations ENABLE ROW LEVEL SECURITY;
 ALTER TABLE nests ENABLE ROW LEVEL SECURITY;
 ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

 -- Policies: Allow users to read all profiles but only update their own
 CREATE POLICY "Public profiles are viewable by everyone" ON player_profiles FOR SELECT USING (true);
 CREATE POLICY "Users can update own profile" ON player_profiles FOR UPDATE USING (auth.uid() = id);
 CREATE POLICY "Users can insert own profile" ON player_profiles FOR INSERT WITH CHECK (auth.uid() = id);

 -- Inventory policies
 CREATE POLICY "Users can view own inventory" ON player_inventory FOR SELECT USING (auth.uid() = player_id);
 CREATE POLICY "Users can update own inventory" ON player_inventory FOR UPDATE USING (auth.uid() = player_id);
 CREATE POLICY "Users can insert own inventory" ON player_inventory FOR INSERT WITH CHECK (auth.uid() = player_id);

 -- Friend policies
 CREATE POLICY "Users can view own friends" ON friend_relations FOR SELECT USING (auth.uid() = player_id OR auth.uid() = friend_id);
 CREATE POLICY "Users can send friend requests" ON friend_relations FOR INSERT WITH CHECK (auth.uid() = player_id);
 CREATE POLICY "Users can update friend status" ON friend_relations FOR UPDATE USING (auth.uid() = friend_id);

 -- Nest policies
 CREATE POLICY "Users can view all nests" ON nests FOR SELECT USING (true);
 CREATE POLICY "Users can update own nest" ON nests FOR UPDATE USING (auth.uid() = player_id);
 CREATE POLICY "Users can insert own nest" ON nests FOR INSERT WITH CHECK (auth.uid() = player_id);

 -- Chat policies
 CREATE POLICY "Users can view chat messages" ON chat_messages FOR SELECT USING (true);
 CREATE POLICY "Users can send chat messages" ON chat_messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

 -- Create indexes for performance
 CREATE INDEX idx_player_profiles_friend_code ON player_profiles(friend_code);
 CREATE INDEX idx_player_profiles_username ON player_profiles(username);
 CREATE INDEX idx_friend_relations_player ON friend_relations(player_id);
 CREATE INDEX idx_friend_relations_friend ON friend_relations(friend_id);
 CREATE INDEX idx_nests_player ON nests(player_id);
 CREATE INDEX idx_chat_messages_channel ON chat_messages(channel_id);
 CREATE INDEX idx_chat_messages_created ON chat_messages(created_at DESC);

 -- =====================================================
 -- NEW TABLES FOR 3D MMORPG FEATURES
 -- =====================================================

 -- Territories (Flock-controlled zones)
 CREATE TABLE territories (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     name TEXT UNIQUE NOT NULL,
     center_x DOUBLE PRECISION NOT NULL,
     center_y DOUBLE PRECISION NOT NULL,
     center_z DOUBLE PRECISION DEFAULT 50,
     radius DOUBLE PRECISION DEFAULT 800,
     biome TEXT NOT NULL,
     controlling_flock_id UUID REFERENCES flocks(id) ON DELETE SET NULL,
     control_points INTEGER DEFAULT 0,
     max_control_points INTEGER DEFAULT 100,
     bonus_multiplier DOUBLE PRECISION DEFAULT 1.0,
     last_captured_at TIMESTAMPTZ,
     created_at TIMESTAMPTZ DEFAULT NOW(),
     updated_at TIMESTAMPTZ DEFAULT NOW()
 );

 -- Territory Control History (for tracking captures)
 CREATE TABLE territory_history (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     territory_id UUID REFERENCES territories(id) ON DELETE CASCADE,
     flock_id UUID REFERENCES flocks(id) ON DELETE SET NULL,
     captured_at TIMESTAMPTZ DEFAULT NOW(),
     held_duration INTEGER, -- seconds held before loss
     points_earned INTEGER DEFAULT 0
 );

 -- Game Sessions (for multiplayer state synchronization)
 CREATE TABLE game_sessions (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     session_type TEXT NOT NULL CHECK (session_type IN ('open_world', 'squad_battle', 'nest_wars', 'battle_royale')),
     host_id UUID REFERENCES player_profiles(id),
     player_ids UUID[] DEFAULT ARRAY[]::UUID[],
     max_players INTEGER DEFAULT 50,
     current_players INTEGER DEFAULT 0,
     region TEXT DEFAULT 'auto',
     status TEXT DEFAULT 'active' CHECK (status IN ('active', 'starting', 'full', 'ended')),
     server_address TEXT,
     created_at TIMESTAMPTZ DEFAULT NOW(),
     updated_at TIMESTAMPTZ DEFAULT NOW(),
     ended_at TIMESTAMPTZ
 );

 -- Session Players (for tracking player state in sessions)
 CREATE TABLE session_players (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     session_id UUID REFERENCES game_sessions(id) ON DELETE CASCADE,
     player_id UUID REFERENCES player_profiles(id) ON DELETE CASCADE,
     bird_type TEXT NOT NULL,
     skin_id TEXT NOT NULL,
     position_x DOUBLE PRECISION DEFAULT 0,
     position_y DOUBLE PRECISION DEFAULT 0,
     position_z DOUBLE PRECISION DEFAULT 50,
     health DOUBLE PRECISION DEFAULT 100,
     energy DOUBLE PRECISION DEFAULT 100,
     is_alive BOOLEAN DEFAULT TRUE,
     joined_at TIMESTAMPTZ DEFAULT NOW(),
     last_update TIMESTAMPTZ DEFAULT NOW(),
     UNIQUE(session_id, player_id)
 );

 -- Player Quests (tracking quest progress)
 CREATE TABLE player_quests (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     player_id UUID REFERENCES player_profiles(id) ON DELETE CASCADE,
     quest_id TEXT NOT NULL,
     quest_type TEXT NOT NULL CHECK (quest_type IN ('daily', 'weekly', 'story', 'achievement', 'event')),
     objectives JSONB DEFAULT '[]',
     is_completed BOOLEAN DEFAULT FALSE,
     is_claimed BOOLEAN DEFAULT FALSE,
     started_at TIMESTAMPTZ DEFAULT NOW(),
     completed_at TIMESTAMPTZ,
     expires_at TIMESTAMPTZ
 );

 -- Crafted Items Inventory
 CREATE TABLE player_crafted_items (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     player_id UUID REFERENCES player_profiles(id) ON DELETE CASCADE,
     item_type TEXT NOT NULL,
     item_id TEXT NOT NULL,
     quantity INTEGER DEFAULT 1,
     acquired_at TIMESTAMPTZ DEFAULT NOW(),
     UNIQUE(player_id, item_id)
 );

 -- Crafting Queue
 CREATE TABLE crafting_queue (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     player_id UUID REFERENCES player_profiles(id) ON DELETE CASCADE,
     recipe_id TEXT NOT NULL,
     started_at TIMESTAMPTZ DEFAULT NOW(),
     completes_at TIMESTAMPTZ NOT NULL,
     is_collected BOOLEAN DEFAULT FALSE
 );

 -- Combat Logs (for anti-cheat and analytics)
 CREATE TABLE combat_logs (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     session_id UUID REFERENCES game_sessions(id) ON DELETE CASCADE,
     attacker_id UUID REFERENCES player_profiles(id),
     defender_id UUID,
     damage_dealt DOUBLE PRECISION,
     skill_id TEXT,
     was_critical BOOLEAN DEFAULT FALSE,
     attacker_position_x DOUBLE PRECISION,
     attacker_position_y DOUBLE PRECISION,
     attacker_position_z DOUBLE PRECISION,
     defender_position_x DOUBLE PRECISION,
     defender_position_y DOUBLE PRECISION,
     defender_position_z DOUBLE PRECISION,
     distance DOUBLE PRECISION,
     timestamp TIMESTAMPTZ DEFAULT NOW(),
     validation_status TEXT DEFAULT 'pending' CHECK (validation_status IN ('pending', 'valid', 'suspicious', 'rejected'))
 );

 -- Player Settings (synced across devices)
 CREATE TABLE player_settings (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     player_id UUID REFERENCES player_profiles(id) ON DELETE CASCADE UNIQUE,
     graphics_quality TEXT DEFAULT 'high',
     target_fps INTEGER DEFAULT 60,
     camera_sensitivity_x DOUBLE PRECISION DEFAULT 1.0,
     camera_sensitivity_y DOUBLE PRECISION DEFAULT 1.0,
     invert_camera_x BOOLEAN DEFAULT FALSE,
     invert_camera_y BOOLEAN DEFAULT FALSE,
     haptic_feedback BOOLEAN DEFAULT TRUE,
     master_volume DOUBLE PRECISION DEFAULT 1.0,
     music_volume DOUBLE PRECISION DEFAULT 0.7,
     sfx_volume DOUBLE PRECISION DEFAULT 1.0,
     push_notifications BOOLEAN DEFAULT TRUE,
     updated_at TIMESTAMPTZ DEFAULT NOW()
 );

 -- Enable RLS on new tables
 ALTER TABLE territories ENABLE ROW LEVEL SECURITY;
 ALTER TABLE territory_history ENABLE ROW LEVEL SECURITY;
 ALTER TABLE game_sessions ENABLE ROW LEVEL SECURITY;
 ALTER TABLE session_players ENABLE ROW LEVEL SECURITY;
 ALTER TABLE player_quests ENABLE ROW LEVEL SECURITY;
 ALTER TABLE player_crafted_items ENABLE ROW LEVEL SECURITY;
 ALTER TABLE crafting_queue ENABLE ROW LEVEL SECURITY;
 ALTER TABLE combat_logs ENABLE ROW LEVEL SECURITY;
 ALTER TABLE player_settings ENABLE ROW LEVEL SECURITY;

 -- Policies for new tables
 CREATE POLICY "Territories are viewable by everyone" ON territories FOR SELECT USING (true);
 CREATE POLICY "Territory history is viewable by everyone" ON territory_history FOR SELECT USING (true);
 
 CREATE POLICY "Game sessions are viewable by everyone" ON game_sessions FOR SELECT USING (true);
 CREATE POLICY "Users can create game sessions" ON game_sessions FOR INSERT WITH CHECK (auth.uid() = host_id);
 CREATE POLICY "Hosts can update sessions" ON game_sessions FOR UPDATE USING (auth.uid() = host_id);

 CREATE POLICY "Session players viewable by session members" ON session_players FOR SELECT USING (true);
 CREATE POLICY "Users can join sessions" ON session_players FOR INSERT WITH CHECK (auth.uid() = player_id);
 CREATE POLICY "Users can update own session state" ON session_players FOR UPDATE USING (auth.uid() = player_id);

 CREATE POLICY "Users can view own quests" ON player_quests FOR SELECT USING (auth.uid() = player_id);
 CREATE POLICY "Users can update own quests" ON player_quests FOR ALL USING (auth.uid() = player_id);

 CREATE POLICY "Users can view own crafted items" ON player_crafted_items FOR SELECT USING (auth.uid() = player_id);
 CREATE POLICY "Users can manage own crafted items" ON player_crafted_items FOR ALL USING (auth.uid() = player_id);

 CREATE POLICY "Users can view own crafting queue" ON crafting_queue FOR SELECT USING (auth.uid() = player_id);
 CREATE POLICY "Users can manage own crafting queue" ON crafting_queue FOR ALL USING (auth.uid() = player_id);

 CREATE POLICY "Combat logs viewable by participants" ON combat_logs FOR SELECT USING (auth.uid() = attacker_id);
 CREATE POLICY "Combat logs insertable by attackers" ON combat_logs FOR INSERT WITH CHECK (auth.uid() = attacker_id);

 CREATE POLICY "Users can view own settings" ON player_settings FOR SELECT USING (auth.uid() = player_id);
 CREATE POLICY "Users can manage own settings" ON player_settings FOR ALL USING (auth.uid() = player_id);

 -- Indexes for new tables
 CREATE INDEX idx_territories_biome ON territories(biome);
 CREATE INDEX idx_territories_flock ON territories(controlling_flock_id);
 CREATE INDEX idx_game_sessions_status ON game_sessions(status);
 CREATE INDEX idx_game_sessions_type ON game_sessions(session_type);
 CREATE INDEX idx_session_players_session ON session_players(session_id);
 CREATE INDEX idx_player_quests_player ON player_quests(player_id);
 CREATE INDEX idx_player_quests_type ON player_quests(quest_type);
 CREATE INDEX idx_combat_logs_session ON combat_logs(session_id);
 CREATE INDEX idx_combat_logs_attacker ON combat_logs(attacker_id);
 CREATE INDEX idx_combat_logs_timestamp ON combat_logs(timestamp DESC);

 */

