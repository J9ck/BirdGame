//
//  SoundManager.swift
//  BirdGame3
//
//  Complete audio management for epic bird sounds
//

import AVFoundation
import SpriteKit
import SwiftUI

class SoundManager: ObservableObject {
    
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    
    // Published properties for settings
    @Published var musicVolume: Float = 0.7 {
        didSet { save() }
    }
    @Published var sfxVolume: Float = 0.8 {
        didSet { save() }
    }
    @Published var hapticsEnabled: Bool = true {
        didSet { save() }
    }
    @Published var isMuted: Bool = false {
        didSet { save() }
    }
    
    // Persistence keys
    private let musicVolumeKey = "birdgame3_musicVolume"
    private let sfxVolumeKey = "birdgame3_sfxVolume"
    private let hapticsKey = "birdgame3_haptics"
    private let mutedKey = "birdgame3_muted"
    
    // Sound effect types - Complete list for all game actions
    enum SoundEffect: String, CaseIterable {
        // Combat sounds
        case peck = "peck"
        case block = "block"
        case hit = "hit"
        case ability = "ability"
        case sprint = "sprint"
        case dodge = "dodge"
        case criticalHit = "critical_hit"
        
        // Match sounds
        case victory = "victory"
        case defeat = "defeat"
        case countdown = "countdown"
        case fight = "fight"
        case matchFound = "match_found"
        
        // UI sounds
        case menuSelect = "menu_select"
        case menuBack = "menu_back"
        case buttonPress = "button_press"
        case tabSwitch = "tab_switch"
        case notification = "notification"
        case error = "error"
        case success = "success"
        
        // Shop/rewards sounds
        case purchase = "purchase"
        case coinCollect = "coin_collect"
        case levelUp = "level_up"
        case achievementUnlock = "achievement_unlock"
        case rewardClaim = "reward_claim"
        case chestOpen = "chest_open"
        
        // Social sounds
        case friendOnline = "friend_online"
        case partyJoin = "party_join"
        case partyLeave = "party_leave"
        case chatMessage = "chat_message"
        case voiceActivate = "voice_activate"
        
        // Open world sounds
        case resourceGather = "resource_gather"
        case nestBuild = "nest_build"
        case raidAlert = "raid_alert"
        case biomeEnter = "biome_enter"
        case weatherChange = "weather_change"
        
        // Emote sounds
        case emotePlay = "emote_play"
        case emoteWave = "emote_wave"
        case emoteLaugh = "emote_laugh"
        case emoteDance = "emote_dance"
        
        // Description for debugging
        var description: String {
            switch self {
            case .peck: return "PECK! 🐦"
            case .block: return "BLOCKED! 🛡️"
            case .hit: return "OOF! 💥"
            case .ability: return "SPECIAL! ✨"
            case .sprint: return "WHOOSH! 💨"
            case .dodge: return "MISS! ➡️"
            case .criticalHit: return "CRITICAL! 💥💥"
            case .victory: return "VICTORY SCREECH! 🎉"
            case .defeat: return "sad bird noises 😢"
            case .countdown: return "3... 2... 1..."
            case .fight: return "FIGHT! ⚔️"
            case .matchFound: return "MATCH FOUND! 🎮"
            case .menuSelect: return "*click* 🔘"
            case .menuBack: return "*whoosh* ⬅️"
            case .buttonPress: return "*tap* 👆"
            case .tabSwitch: return "*swipe* 📱"
            case .notification: return "*ding* 🔔"
            case .error: return "*buzz* ❌"
            case .success: return "*chime* ✅"
            case .purchase: return "KA-CHING! 💰"
            case .coinCollect: return "*clink* 🪙"
            case .levelUp: return "LEVEL UP! ⬆️"
            case .achievementUnlock: return "ACHIEVEMENT! 🏆"
            case .rewardClaim: return "*sparkle* ✨"
            case .chestOpen: return "*creak* 📦"
            case .friendOnline: return "*pop* 👋"
            case .partyJoin: return "*join* 🎉"
            case .partyLeave: return "*leave* 👋"
            case .chatMessage: return "*blip* 💬"
            case .voiceActivate: return "*beep* 🎙️"
            case .resourceGather: return "*rustle* 🌿"
            case .nestBuild: return "*build* 🪺"
            case .raidAlert: return "⚠️ ALERT! ⚠️"
            case .biomeEnter: return "*ambient* 🌍"
            case .weatherChange: return "*wind* 🌤️"
            case .emotePlay: return "*emote* 🎭"
            case .emoteWave: return "👋"
            case .emoteLaugh: return "😂"
            case .emoteDance: return "💃"
            }
        }
        
        var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .peck, .menuSelect, .buttonPress, .tabSwitch, .coinCollect:
                return .light
            case .block, .dodge, .notification, .chatMessage, .resourceGather:
                return .medium
            case .hit, .ability, .sprint, .criticalHit, .raidAlert, .nestBuild:
                return .heavy
            case .countdown, .fight, .matchFound, .levelUp, .achievementUnlock:
                return .rigid
            default:
                return .soft
            }
        }
    }
    
    // Bird-specific sounds
    enum BirdSound: String {
        case pigeonCoo = "coo"
        case hummingbirdBuzz = "buzz"
        case eagleScreech = "screech"
        case crowCaw = "caw"
        case pelicanGulp = "gulp"
        
        var description: String {
            switch self {
            case .pigeonCoo: return "Coo coo! 🐦"
            case .hummingbirdBuzz: return "*intense vibrating* 🌸"
            case .eagleScreech: return "SCREEEEEE! 🦅"
            case .crowCaw: return "CAW CAW! 🦜"
            case .pelicanGulp: return "*menacing gulp* 🦆"
            }
        }
    }
    
    private init() {
        loadSettings()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Persistence
    
    private func loadSettings() {
        musicVolume = UserDefaults.standard.object(forKey: musicVolumeKey) as? Float ?? 0.7
        sfxVolume = UserDefaults.standard.object(forKey: sfxVolumeKey) as? Float ?? 0.8
        hapticsEnabled = UserDefaults.standard.object(forKey: hapticsKey) as? Bool ?? true
        isMuted = UserDefaults.standard.object(forKey: mutedKey) as? Bool ?? false
    }
    
    private func save() {
        UserDefaults.standard.set(musicVolume, forKey: musicVolumeKey)
        UserDefaults.standard.set(sfxVolume, forKey: sfxVolumeKey)
        UserDefaults.standard.set(hapticsEnabled, forKey: hapticsKey)
        UserDefaults.standard.set(isMuted, forKey: mutedKey)
    }
    
    // MARK: - Public Methods
    
    func playSound(_ sound: SoundEffect) {
        guard !isMuted else { return }
        
        // In a real implementation, this would play actual sound files
        #if DEBUG
        print("🔊 Playing sound: \(sound.description)")
        #endif
        
        // Haptic feedback as audio substitute
        if hapticsEnabled {
            provideFeedback(for: sound)
        }
    }
    
    func playBirdSound(_ sound: BirdSound) {
        guard !isMuted else { return }
        
        #if DEBUG
        print("🐦 Playing bird sound: \(sound.description)")
        #endif
        
        // Light haptic for bird sounds
        if hapticsEnabled {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    func playBirdSound(for type: BirdType) {
        switch type {
        case .pigeon:
            playBirdSound(.pigeonCoo)
        case .hummingbird:
            playBirdSound(.hummingbirdBuzz)
        case .eagle:
            playBirdSound(.eagleScreech)
        case .crow:
            playBirdSound(.crowCaw)
        case .pelican:
            playBirdSound(.pelicanGulp)
        }
    }
    
    private func provideFeedback(for sound: SoundEffect) {
        guard hapticsEnabled else { return }
        
        // Special notification haptics
        switch sound {
        case .victory, .success, .achievementUnlock, .levelUp:
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.notificationOccurred(.success)
            return
        case .defeat, .error:
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.notificationOccurred(.error)
            return
        case .raidAlert, .notification:
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.notificationOccurred(.warning)
            return
        default:
            break
        }
        
        // Standard impact haptics
        let generator = UIImpactFeedbackGenerator(style: sound.hapticStyle)
        generator.impactOccurred()
    }
    
    func toggleMute() {
        isMuted.toggle()
    }
    
    var muted: Bool {
        get { isMuted }
        set { isMuted = newValue }
    }
    
    // MARK: - SpriteKit Integration
    
    func getSKAction(for sound: SoundEffect) -> SKAction {
        // Returns a placeholder action since we don't have actual sound files
        // In production, this would return SKAction.playSoundFileNamed
        return SKAction.run { [weak self] in
            self?.playSound(sound)
        }
    }
    
    func getSKAction(for birdSound: BirdSound) -> SKAction {
        return SKAction.run { [weak self] in
            self?.playBirdSound(birdSound)
        }
    }
}

// MARK: - Sound Generator (Synthesized Sounds)

class SynthesizedSoundGenerator {
    
    static func generatePeckSound() -> AVAudioPlayer? {
        // Would generate a short, sharp "peck" sound
        // Using AudioToolbox or AVAudioEngine
        return nil
    }
    
    static func generateCooSound() -> AVAudioPlayer? {
        // Would generate a pigeon "coo" sound
        return nil
    }
    
    // More synthesized sounds could be added here
}

// MARK: - Music Manager

class MusicManager {
    
    static let shared = MusicManager()
    
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var isMusicEnabled: Bool = true
    
    enum MusicTrack: String, CaseIterable {
        case mainMenu = "menu_theme"
        case battle = "battle_theme"
        case victory = "victory_theme"
        case defeat = "defeat_theme"
        case openWorld = "open_world_theme"
        case lobby = "lobby_theme"
        case shop = "shop_theme"
        case boss = "boss_theme"
        
        var description: String {
            switch self {
            case .mainMenu: return "🎵 Chill bird vibes"
            case .battle: return "🎵 Epic combat music"
            case .victory: return "🎵 Triumphant fanfare"
            case .defeat: return "🎵 Sad trombone"
            case .openWorld: return "🎵 Ambient exploration"
            case .lobby: return "🎵 Social hangout beats"
            case .shop: return "🎵 Shopping muzak"
            case .boss: return "🎵 Intense boss battle"
            }
        }
    }
    
    func playMusic(_ track: MusicTrack) {
        guard isMusicEnabled else { return }
        
        #if DEBUG
        print("🎵 Playing music: \(track.description)")
        #endif
        
        // In production, this would load and play actual music files
    }
    
    func stopMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }
    
    func toggleMusic() {
        isMusicEnabled.toggle()
        if !isMusicEnabled {
            stopMusic()
        }
    }
    
    var musicEnabled: Bool {
        get { isMusicEnabled }
        set {
            isMusicEnabled = newValue
            if !newValue {
                stopMusic()
            }
        }
    }
}
