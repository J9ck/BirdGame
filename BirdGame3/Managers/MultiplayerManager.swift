//
//  MultiplayerManager.swift
//  BirdGame3
//
//  Fortnite-style multiplayer lobby and party system
//

import Foundation
import SwiftUI
import GameKit

// MARK: - Party Member

struct PartyMember: Identifiable, Codable, Equatable {
    let id: String
    var displayName: String
    var birdType: BirdType
    var skinId: String
    var isReady: Bool
    var isLeader: Bool
    var level: Int
    var prestigeLevel: Int
    
    var isLocalPlayer: Bool {
        id == MultiplayerManager.shared.localPlayerId
    }
    
    static func localPlayer() -> PartyMember {
        PartyMember(
            id: MultiplayerManager.shared.localPlayerId,
            displayName: UserDefaults.standard.string(forKey: "birdgame3_playerName") ?? "Bird_\(Int.random(in: 1000...9999))",
            birdType: .pigeon,
            skinId: "pigeon_default",
            isReady: false,
            isLeader: true,
            level: PrestigeManager.shared.currentLevel,
            prestigeLevel: PrestigeManager.shared.prestigeLevel
        )
    }
}

// MARK: - Party

struct Party: Identifiable, Codable {
    let id: String
    var members: [PartyMember]
    var maxSize: Int = 4
    var isMatchmaking: Bool = false
    var partyCode: String
    var gameMode: MultiplayerGameMode
    
    var leader: PartyMember? {
        members.first { $0.isLeader }
    }
    
    var isFull: Bool {
        members.count >= maxSize
    }
    
    var allReady: Bool {
        members.allSatisfy { $0.isReady || $0.isLeader }
    }
    
    var memberCount: Int {
        members.count
    }
    
    static func create() -> Party {
        let code = generatePartyCode()
        return Party(
            id: UUID().uuidString,
            members: [PartyMember.localPlayer()],
            partyCode: code,
            gameMode: .squadBattle
        )
    }
    
    private static func generatePartyCode() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in letters.randomElement()! })
    }
}

// MARK: - Multiplayer Game Mode

enum MultiplayerGameMode: String, Codable, CaseIterable, Identifiable {
    case squadBattle = "squad_battle"
    case openWorld = "open_world"
    case nestWars = "nest_wars"
    case battleRoyale = "battle_royale"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .squadBattle: return "Squad Battle"
        case .openWorld: return "Open World"
        case .nestWars: return "Nest Wars"
        case .battleRoyale: return "Battle Royale"
        }
    }
    
    var description: String {
        switch self {
        case .squadBattle: return "4v4 team battles"
        case .openWorld: return "Explore, build nests, survive"
        case .nestWars: return "Raid enemy nests, defend yours"
        case .battleRoyale: return "50 birds enter, 1 squad survives"
        }
    }
    
    var emoji: String {
        switch self {
        case .squadBattle: return "⚔️"
        case .openWorld: return "🌍"
        case .nestWars: return "🪺"
        case .battleRoyale: return "👑"
        }
    }
    
    var maxPlayers: Int {
        switch self {
        case .squadBattle: return 8
        case .openWorld: return 50
        case .nestWars: return 16
        case .battleRoyale: return 50
        }
    }
    
    var squadSize: Int {
        switch self {
        case .squadBattle: return 4
        case .openWorld: return 4
        case .nestWars: return 4
        case .battleRoyale: return 4
        }
    }
}

// MARK: - Matchmaking State

enum MatchmakingState: Equatable {
    case idle
    case searching(playersFound: Int, maxPlayers: Int)
    case found(countdown: Int)
    case joining
    case failed(error: String)
}

// MARK: - Multiplayer Manager

class MultiplayerManager: ObservableObject {
    static let shared = MultiplayerManager()
    
    // MARK: - Published Properties
    
    @Published var currentParty: Party?
    @Published var matchmakingState: MatchmakingState = .idle
    @Published var isConnected: Bool = false
    @Published var pendingInvites: [PartyInvite] = []
    @Published var recentPlayers: [PartyMember] = []
    @Published var onlineFriends: [PartyMember] = []
    
    // MARK: - Local Player
    
    var localPlayerId: String {
        if let id = UserDefaults.standard.string(forKey: "birdgame3_playerId") {
            return id
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "birdgame3_playerId")
        return newId
    }
    
    var localPlayerName: String {
        get {
            UserDefaults.standard.string(forKey: "birdgame3_playerName") ?? "Bird_\(localPlayerId.prefix(4))"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "birdgame3_playerName")
            updateLocalPlayerInParty()
        }
    }
    
    // MARK: - Fake Online Data (for demo)
    
    @Published var fakeOnlineCount: Int = 0
    @Published var fakeMatchmakingTime: TimeInterval = 0
    
    private var matchmakingTimer: Timer?
    private var onlineCountTimer: Timer?
    
    // MARK: - Initialization
    
    private init() {
        startOnlineCountSimulation()
        loadRecentPlayers()
        generateFakeFriends()
    }
    
    // MARK: - Party Management
    
    func createParty() {
        currentParty = Party.create()
    }
    
    func leaveParty() {
        currentParty = nil
        matchmakingState = .idle
    }
    
    func joinParty(code: String, completion: @escaping (Bool, String?) -> Void) {
        // Simulate joining a party
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // 70% chance of finding a party (demo)
            if Int.random(in: 0...100) < 70 {
                var party = Party.create()
                party.partyCode = code
                
                // Add fake members
                let fakeMembers = self.generateFakePartyMembers(count: Int.random(in: 1...3))
                party.members.append(contentsOf: fakeMembers)
                
                // Make local player not the leader
                if var localMember = party.members.first(where: { $0.isLocalPlayer }) {
                    localMember.isLeader = false
                    if let index = party.members.firstIndex(where: { $0.isLocalPlayer }) {
                        party.members[index] = localMember
                    }
                }
                
                self.currentParty = party
                completion(true, nil)
            } else {
                completion(false, "Party not found or is full")
            }
        }
    }
    
    func invitePlayer(_ player: PartyMember) {
        guard currentParty != nil else { return }
        
        // In a real implementation, this would send a network invite
        // For now, we'll simulate the player joining after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2...5)) { [weak self] in
            guard var party = self?.currentParty, !party.isFull else { return }
            
            // 50% chance they accept
            if Bool.random() {
                var newMember = player
                newMember.isReady = false
                newMember.isLeader = false
                party.members.append(newMember)
                self?.currentParty = party
                
                // Voice announcement
                VoiceChatManager.shared.speak("\(player.displayName) joined the party!", priority: .normal)
            }
        }
    }
    
    func kickPlayer(_ playerId: String) {
        guard var party = currentParty,
              let localMember = party.members.first(where: { $0.isLocalPlayer }),
              localMember.isLeader else { return }
        
        party.members.removeAll { $0.id == playerId }
        currentParty = party
    }
    
    func setReady(_ ready: Bool) {
        guard var party = currentParty,
              let index = party.members.firstIndex(where: { $0.isLocalPlayer }) else { return }
        
        party.members[index].isReady = ready
        currentParty = party
    }
    
    func setGameMode(_ mode: MultiplayerGameMode) {
        guard var party = currentParty else { return }
        party.gameMode = mode
        currentParty = party
    }
    
    func updateLocalPlayerBird(_ birdType: BirdType, skinId: String) {
        guard var party = currentParty,
              let index = party.members.firstIndex(where: { $0.isLocalPlayer }) else { return }
        
        party.members[index].birdType = birdType
        party.members[index].skinId = skinId
        currentParty = party
    }
    
    private func updateLocalPlayerInParty() {
        guard var party = currentParty,
              let index = party.members.firstIndex(where: { $0.isLocalPlayer }) else { return }
        
        party.members[index].displayName = localPlayerName
        party.members[index].level = PrestigeManager.shared.currentLevel
        party.members[index].prestigeLevel = PrestigeManager.shared.prestigeLevel
        currentParty = party
    }
    
    // MARK: - Matchmaking
    
    func startMatchmaking() {
        guard let party = currentParty else { return }
        
        matchmakingState = .searching(playersFound: party.memberCount, maxPlayers: party.gameMode.maxPlayers)
        fakeMatchmakingTime = 0
        
        // Simulate matchmaking
        matchmakingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.fakeMatchmakingTime += 0.5
            
            // Gradually find more players
            let currentPlayers: Int
            let maxPlayers = party.gameMode.maxPlayers
            
            if self.fakeMatchmakingTime < 3 {
                currentPlayers = party.memberCount + Int(self.fakeMatchmakingTime * 2)
            } else if self.fakeMatchmakingTime < 8 {
                currentPlayers = min(maxPlayers - Int.random(in: 0...5), party.memberCount + Int(self.fakeMatchmakingTime * 3))
            } else {
                currentPlayers = maxPlayers
            }
            
            self.matchmakingState = .searching(playersFound: min(currentPlayers, maxPlayers), maxPlayers: maxPlayers)
            
            // Match found after ~10 seconds
            if self.fakeMatchmakingTime >= 10 {
                timer.invalidate()
                self.matchFound()
            }
        }
    }
    
    func cancelMatchmaking() {
        matchmakingTimer?.invalidate()
        matchmakingState = .idle
        fakeMatchmakingTime = 0
    }
    
    private func matchFound() {
        matchmakingState = .found(countdown: 5)
        
        VoiceChatManager.shared.speak("Match found! Get ready!", priority: .high)
        
        // Countdown
        var countdown = 5
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            countdown -= 1
            
            if countdown > 0 {
                self?.matchmakingState = .found(countdown: countdown)
            } else {
                timer.invalidate()
                self?.matchmakingState = .joining
                
                // Simulate joining game
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self?.matchmakingState = .idle
                    // Here you would transition to the actual game
                    NotificationCenter.default.post(name: .matchReady, object: nil)
                }
            }
        }
    }
    
    // MARK: - Simulation Helpers
    
    private func startOnlineCountSimulation() {
        fakeOnlineCount = Int.random(in: 50000...150000)
        
        onlineCountTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.fakeOnlineCount = (self?.fakeOnlineCount ?? 100000) + Int.random(in: -1000...1000)
        }
    }
    
    private func generateFakePartyMembers(count: Int) -> [PartyMember] {
        let names = ["xX_BirdSlayer_Xx", "PigeonMaster69", "EagleEye420", "CrowKing", "PelicanPete",
                     "FeatherFury", "BeakBoss", "WingWarrior", "NestDestroyer", "SkyDominator"]
        
        return (0..<count).map { _ in
            let bird = BirdType.allCases.randomElement()!
            return PartyMember(
                id: UUID().uuidString,
                displayName: names.randomElement()!,
                birdType: bird,
                skinId: "\(bird.rawValue)_default",
                isReady: Bool.random(),
                isLeader: false,
                level: Int.random(in: 1...50),
                prestigeLevel: Int.random(in: 0...5)
            )
        }
    }
    
    private func generateFakeFriends() {
        onlineFriends = generateFakePartyMembers(count: Int.random(in: 3...8))
    }
    
    private func loadRecentPlayers() {
        recentPlayers = generateFakePartyMembers(count: 5)
    }
}

// MARK: - Party Invite

struct PartyInvite: Identifiable {
    let id: String
    let fromPlayer: PartyMember
    let partyCode: String
    let timestamp: Date
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 60 // Expires after 60 seconds
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let matchReady = Notification.Name("birdgame3_matchReady")
    static let partyUpdated = Notification.Name("birdgame3_partyUpdated")
}
