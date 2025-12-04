//
//  SoundManager.swift
//  BirdGame3
//
//  Audio management for epic bird sounds
//

import AVFoundation
import SpriteKit

class SoundManager {
    
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var isMuted: Bool = false
    
    // Sound effect types
    enum SoundEffect: String {
        case peck = "peck"
        case block = "block"
        case hit = "hit"
        case ability = "ability"
        case victory = "victory"
        case defeat = "defeat"
        case menuSelect = "menu_select"
        case countdown = "countdown"
        case fight = "fight"
        
        // Meme descriptions for when sounds would play
        var description: String {
            switch self {
            case .peck: return "PECK! 🐦"
            case .block: return "BLOCKED! 🛡️"
            case .hit: return "OOF! 💥"
            case .ability: return "SPECIAL! ✨"
            case .victory: return "VICTORY SCREECH! 🎉"
            case .defeat: return "sad bird noises 😢"
            case .menuSelect: return "*click* 🔘"
            case .countdown: return "3... 2... 1..."
            case .fight: return "FIGHT! ⚔️"
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
    
    // MARK: - Public Methods
    
    func playSound(_ sound: SoundEffect) {
        guard !isMuted else { return }
        
        // In a real implementation, this would play actual sound files
        // For now, we'll just print what would play
        #if DEBUG
        print("🔊 Playing sound: \(sound.description)")
        #endif
        
        // Haptic feedback as audio substitute
        provideFeedback(for: sound)
    }
    
    func playBirdSound(_ sound: BirdSound) {
        guard !isMuted else { return }
        
        #if DEBUG
        print("🐦 Playing bird sound: \(sound.description)")
        #endif
        
        // Light haptic for bird sounds
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
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
        let generator: UIImpactFeedbackGenerator
        
        switch sound {
        case .peck, .menuSelect:
            generator = UIImpactFeedbackGenerator(style: .light)
        case .block:
            generator = UIImpactFeedbackGenerator(style: .medium)
        case .hit, .ability:
            generator = UIImpactFeedbackGenerator(style: .heavy)
        case .victory:
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.notificationOccurred(.success)
            return
        case .defeat:
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.notificationOccurred(.error)
            return
        case .countdown, .fight:
            generator = UIImpactFeedbackGenerator(style: .rigid)
        }
        
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
    
    enum MusicTrack: String {
        case mainMenu = "menu_theme"
        case battle = "battle_theme"
        case victory = "victory_theme"
        case defeat = "defeat_theme"
        
        var description: String {
            switch self {
            case .mainMenu: return "🎵 Chill bird vibes"
            case .battle: return "🎵 Epic combat music"
            case .victory: return "🎵 Triumphant fanfare"
            case .defeat: return "🎵 Sad trombone"
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
