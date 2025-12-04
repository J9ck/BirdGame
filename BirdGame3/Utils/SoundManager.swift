//
//  SoundManager.swift
//  BirdGame3
//
//  Complete audio management for epic bird sounds
//
//  ASSET SOURCES (Royalty-Free):
//  - Freesound: https://freesound.org/search/?q=bird
//  - Mixkit: https://mixkit.co/free-sound-effects/bird/
//  - OpenGameArt: https://opengameart.org/art-search?keys=bird+sound
//  See ASSETS_README.md for complete asset guide
//

import AVFoundation
import SpriteKit
import SwiftUI

class SoundManager: ObservableObject {
    
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var loadedSounds: [String: URL] = [:]
    
    // Published properties for settings
    @Published var musicVolume: Float = 0.7 {
        didSet {
            save()
            updateMusicVolume()
        }
    }
    @Published var sfxVolume: Float = 0.8 {
        didSet { save() }
    }
    @Published var hapticsEnabled: Bool = true {
        didSet { save() }
    }
    @Published var isMuted: Bool = false {
        didSet {
            save()
            if isMuted {
                stopAllSounds()
            }
        }
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
        
        /// The audio file name for this sound effect (without extension)
        var audioFileName: String {
            return rawValue
        }
        
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
        
        /// File name for the sound effect (without extension)
        var fileName: String {
            return rawValue
        }
    }
    
    // Bird-specific sounds with file mappings
    enum BirdSound: String {
        case pigeonCoo = "pigeon_coo"
        case hummingbirdBuzz = "hummingbird_buzz"
        case eagleScreech = "eagle_screech"
        case crowCaw = "crow_caw"
        case pelicanGulp = "pelican_gulp"
        
        var description: String {
            switch self {
            case .pigeonCoo: return "Coo coo! 🐦"
            case .hummingbirdBuzz: return "*intense vibrating* 🌸"
            case .eagleScreech: return "SCREEEEEE! 🦅"
            case .crowCaw: return "CAW CAW! 🦜"
            case .pelicanGulp: return "*menacing gulp* 🦆"
            }
        }
        
        /// File name for the bird sound (without extension)
        var fileName: String {
            switch self {
            case .pigeonCoo: return "pigeon_coo"
            case .hummingbirdBuzz: return "hummingbird_buzz"
            case .eagleScreech: return "eagle_screech"
            case .crowCaw: return "crow_caw"
            case .pelicanGulp: return "pelican_gulp"
            }
        }
    }
    
    private init() {
        loadSettings()
        setupAudioSession()
        preloadSounds()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    /// Preload common sounds for better performance
    private func preloadSounds() {
        // Preload bird sounds if files exist in bundle
        let soundFiles: [(name: String, ext: String)] = [
            ("pigeon_coo", "mp3"),
            ("pigeon_peck", "mp3"),
            ("hummingbird_buzz", "mp3"),
            ("hummingbird_zip", "mp3"),
            ("eagle_screech", "mp3"),
            ("eagle_attack", "mp3"),
            ("crow_caw", "mp3"),
            ("crow_attack", "mp3"),
            ("pelican_gulp", "mp3"),
            ("pelican_slap", "mp3"),
            ("hit", "mp3"),
            ("block", "mp3"),
            ("victory", "mp3"),
            ("defeat", "mp3"),
            ("menu_select", "mp3"),
            ("bowling_strike", "mp3")
        ]
        
        for file in soundFiles {
            if let url = Bundle.main.url(forResource: file.name, withExtension: file.ext) {
                loadedSounds[file.name] = url
                #if DEBUG
                print("🔊 Preloaded sound: \(file.name).\(file.ext)")
                #endif
            }
        }
    }
    
    private func updateMusicVolume() {
        // Access MusicManager safely - it's a singleton that initializes on first access
        DispatchQueue.main.async {
            MusicManager.shared.setVolume(self.musicVolume)
        }
    }
    
    private func stopAllSounds() {
        for player in audioPlayers.values {
            player.stop()
        }
        // Clear stopped players to prevent memory leaks
        audioPlayers.removeAll()
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
        
        // Try to play actual sound file first
        let soundFileName = sound.fileName
        if let url = loadedSounds[soundFileName] ?? Bundle.main.url(forResource: soundFileName, withExtension: "mp3") {
            playAudioFile(url: url, volume: sfxVolume)
        } else {
            // Fallback to debug output and haptics
            #if DEBUG
            print("🔊 Playing sound: \(sound.description)")
            #endif
        }
        
        // Haptic feedback
        if hapticsEnabled {
            provideFeedback(for: sound)
        }
    }
    
    func playBirdSound(_ sound: BirdSound) {
        guard !isMuted else { return }
        
        // Try to play actual sound file
        let soundFileName = sound.fileName
        if let url = loadedSounds[soundFileName] ?? Bundle.main.url(forResource: soundFileName, withExtension: "mp3") {
            playAudioFile(url: url, volume: sfxVolume)
        } else {
            #if DEBUG
            print("🐦 Playing bird sound: \(sound.description)")
            #endif
        }
        
        // Light haptic for bird sounds
        if hapticsEnabled {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    /// Play an audio file from URL
    private func playAudioFile(url: URL, volume: Float) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.delegate = AudioPlayerDelegate.shared  // Set delegate for cleanup
            player.prepareToPlay()
            player.play()
            
            // Store reference to prevent deallocation
            let key = url.lastPathComponent
            
            // Clean up old player for this sound if it exists and is not playing
            if let oldPlayer = audioPlayers[key], !oldPlayer.isPlaying {
                audioPlayers.removeValue(forKey: key)
            }
            
            audioPlayers[key] = player
        } catch {
            #if DEBUG
            print("❌ Failed to play audio: \(error)")
            #endif
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
        // Try to use native SpriteKit sound playback for better performance
        if Bundle.main.url(forResource: sound.audioFileName, withExtension: "wav") != nil {
            return SKAction.group([
                SKAction.playSoundFileNamed("\(sound.audioFileName).wav", waitForCompletion: false),
                SKAction.run { [weak self] in
                    self?.provideFeedback(for: sound)
                }
            ])
        }
        
        // Fallback to manual playback
        return SKAction.run { [weak self] in
            self?.playSound(sound)
        }
    }
    
    func getSKAction(for birdSound: BirdSound) -> SKAction {
        // Try to use native SpriteKit sound playback
        if Bundle.main.url(forResource: birdSound.audioFileName, withExtension: "wav") != nil {
            return SKAction.playSoundFileNamed("\(birdSound.audioFileName).wav", waitForCompletion: false)
        }
        
        // Fallback to manual playback
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

// MARK: - Audio Player Delegate (for cleanup)

class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioPlayerDelegate()
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Player finished - will be cleaned up on next playAudioFile call
        // This prevents memory leaks by allowing players to be released
    }
}

// MARK: - Music Manager

class MusicManager {
    
    static let shared = MusicManager()
    
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var isMusicEnabled: Bool = true
    private var currentVolume: Float = 0.7
    
    enum MusicTrack: String, CaseIterable {
        case mainMenu = "menu_theme"
        case battle = "battle_theme"
        case victory = "victory_theme"
        case defeat = "defeat_theme"
        case openWorld = "open_world_theme"
        case lobby = "lobby_theme"
        case shop = "shop_theme"
        case boss = "boss_theme"
        case bowlingAlley = "bowling_theme"  // Fun retro arcade music for bowling alley
        
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
            case .bowlingAlley: return "🎵 Retro bowling arcade funk"
            }
        }
        
        /// File name for the music track (without extension)
        var fileName: String {
            return rawValue
        }
    }
    
    func playMusic(_ track: MusicTrack) {
        guard isMusicEnabled else { return }
        
        // Stop current music
        stopMusic()
        
        // Try to load and play the music file
        if let url = Bundle.main.url(forResource: track.fileName, withExtension: "mp3") {
            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
                backgroundMusicPlayer?.volume = currentVolume
                backgroundMusicPlayer?.numberOfLoops = -1  // Loop forever
                backgroundMusicPlayer?.prepareToPlay()
                backgroundMusicPlayer?.play()
            } catch {
                #if DEBUG
                print("❌ Failed to play music: \(error)")
                #endif
            }
        } else {
            #if DEBUG
            print("🎵 Playing music: \(track.description)")
            #endif
        }
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
    
    func setVolume(_ volume: Float) {
        currentVolume = volume
        backgroundMusicPlayer?.volume = volume
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
