//
//  VoiceChatManager.swift
//  BirdGame3
//
//  Real-time voice commentary system for battles
//  Mimics the iconic AI-generated voice chat from the meme
//

import Foundation
import AVFoundation
import SwiftUI

// MARK: - Voice Chat Manager

class VoiceChatManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = VoiceChatManager()
    
    // MARK: - Published Properties
    
    @Published var isEnabled: Bool = true {
        didSet { save() }
    }
    @Published var volume: Float = 0.8 {
        didSet { save() }
    }
    @Published var voiceSpeed: Float = 0.52 {
        didSet { save() }
    }
    @Published var currentlySpeaking: Bool = false
    @Published var lastMessage: String = ""
    
    // MARK: - Constants
    
    /// Minimum voice speed (AVSpeechUtterance rate - slowest natural speech)
    static let minVoiceSpeed: Float = 0.4
    /// Maximum voice speed (AVSpeechUtterance rate - fastest comprehensible speech)
    static let maxVoiceSpeed: Float = 0.65
    /// Default British voice identifier (Daniel)
    static let defaultVoiceIdentifier = "com.apple.ttsbundle.Daniel-compact"
    /// Fallback US English voice identifier
    static let fallbackVoiceIdentifier = "com.apple.ttsbundle.Samantha-compact"
    
    // MARK: - Private Properties
    
    private let synthesizer = AVSpeechSynthesizer()
    private var messageQueue: [VoiceMessage] = []
    private var isProcessingQueue = false
    private var battleCommentaryTimer: Timer?
    
    // Voice options - validated on first use
    private var selectedVoiceIdentifier: String = VoiceChatManager.defaultVoiceIdentifier
    private var validatedVoice: AVSpeechSynthesisVoice?
    
    // Persistence keys
    private let enabledKey = "birdgame3_voicechat_enabled"
    private let volumeKey = "birdgame3_voicechat_volume"
    private let speedKey = "birdgame3_voicechat_speed"
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        synthesizer.delegate = self
        loadSettings()
        setupAudioSession()
        validateAndSetVoice()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    /// Validate the selected voice exists, falling back to alternatives if not
    private func validateAndSetVoice() {
        // Try the selected voice first
        if let voice = AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier) {
            validatedVoice = voice
            return
        }
        
        // Try the fallback voice
        if let voice = AVSpeechSynthesisVoice(identifier: Self.fallbackVoiceIdentifier) {
            validatedVoice = voice
            selectedVoiceIdentifier = Self.fallbackVoiceIdentifier
            return
        }
        
        // Fall back to any available English voice
        let englishVoices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.starts(with: "en") }
        if let voice = englishVoices.first {
            validatedVoice = voice
            selectedVoiceIdentifier = voice.identifier
            return
        }
        
        // Last resort: system default
        validatedVoice = AVSpeechSynthesisVoice(language: "en-US")
    }
    
    // MARK: - Public Methods
    
    /// Speak a message immediately (interrupts current speech)
    func speak(_ text: String, priority: VoicePriority = .normal) {
        guard isEnabled else { return }
        
        let message = VoiceMessage(text: text, priority: priority)
        
        if priority == .high {
            // High priority interrupts current speech
            synthesizer.stopSpeaking(at: .immediate)
            messageQueue.insert(message, at: 0)
        } else {
            messageQueue.append(message)
        }
        
        processQueue()
    }
    
    /// Queue a message to be spoken
    func queue(_ text: String, priority: VoicePriority = .normal) {
        guard isEnabled else { return }
        
        let message = VoiceMessage(text: text, priority: priority)
        messageQueue.append(message)
        processQueue()
    }
    
    /// Stop all speech
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        messageQueue.removeAll()
        isProcessingQueue = false
        currentlySpeaking = false
    }
    
    /// Start battle commentary mode
    func startBattleCommentary(playerBird: BirdType, opponentBird: BirdType) {
        // Initial hype
        let introMessages = [
            "Oh we got a \(playerBird.displayName) versus \(opponentBird.displayName)! This is gonna be insane!",
            "Yo chat! \(playerBird.displayName) is fighting \(opponentBird.displayName)! Let's gooo!",
            "The \(playerBird.displayName) player just locked in against \(opponentBird.displayName). Big mistake or five hundred IQ play?",
            "Chat is this even fair? \(playerBird.displayName) against \(opponentBird.displayName)?!"
        ]
        speak(introMessages.randomElement()!, priority: .high)
        
        // Start periodic commentary
        battleCommentaryTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 4...8), repeats: true) { [weak self] _ in
            self?.deliverRandomBattleCommentary()
        }
    }
    
    /// Stop battle commentary mode
    func stopBattleCommentary() {
        battleCommentaryTimer?.invalidate()
        battleCommentaryTimer = nil
    }
    
    /// Commentary for specific battle events
    func commentOnEvent(_ event: BattleEvent) {
        guard isEnabled else { return }
        
        let commentary = getCommentaryForEvent(event)
        speak(commentary, priority: event.priority)
    }
    
    // MARK: - Battle Event Commentary
    
    private func getCommentaryForEvent(_ event: BattleEvent) -> String {
        switch event {
        case .battleStart(let player, let opponent):
            return BattleCommentary.battleStart(player: player, opponent: opponent)
            
        case .playerAttack(let damage):
            return BattleCommentary.playerAttack(damage: damage)
            
        case .playerAbility(let bird, let abilityName):
            return BattleCommentary.playerAbility(bird: bird, ability: abilityName)
            
        case .opponentAttack(let damage):
            return BattleCommentary.opponentAttack(damage: damage)
            
        case .opponentAbility(let bird, let abilityName):
            return BattleCommentary.opponentAbility(bird: bird, ability: abilityName)
            
        case .playerLowHealth:
            return BattleCommentary.playerLowHealth()
            
        case .opponentLowHealth:
            return BattleCommentary.opponentLowHealth()
            
        case .playerBlock:
            return BattleCommentary.playerBlock()
            
        case .playerDodge:
            return BattleCommentary.playerDodge()
            
        case .criticalHit(let damage):
            return BattleCommentary.criticalHit(damage: damage)
            
        case .playerWin(let isPerfect):
            return BattleCommentary.playerWin(isPerfect: isPerfect)
            
        case .playerLose:
            return BattleCommentary.playerLose()
            
        case .closeMatch:
            return BattleCommentary.closeMatch()
        }
    }
    
    private func deliverRandomBattleCommentary() {
        let fillerCommentary = [
            "Chat is going crazy right now!",
            "This is peak Bird Game 3 gameplay right here.",
            "The skill expression is insane!",
            "You love to see it chat, you love to see it.",
            "This player is different, built different.",
            "Nerf this bird by the way, just saying.",
            "The reads! The plays! The pecks!",
            "Chat spam those emotes!",
            "This is what we trained for.",
            "Gaming is happening right now.",
            "The tech! Look at the tech!",
            "Professional bird gamer moment.",
            "Bro thinks he's in the Bird Game World Championship.",
            "The disrespect is crazy!",
            "No way that just happened chat!"
        ]
        
        if let commentary = fillerCommentary.randomElement() {
            speak(commentary, priority: .low)
        }
    }
    
    // MARK: - Queue Processing
    
    private func processQueue() {
        guard !isProcessingQueue, !messageQueue.isEmpty else { return }
        
        isProcessingQueue = true
        
        // Sort by priority
        messageQueue.sort { $0.priority.rawValue > $1.priority.rawValue }
        
        guard let message = messageQueue.first else {
            isProcessingQueue = false
            return
        }
        
        messageQueue.removeFirst()
        speakMessage(message)
    }
    
    private func speakMessage(_ message: VoiceMessage) {
        let utterance = AVSpeechUtterance(string: message.text)
        
        // Use pre-validated voice for better performance and reliability
        utterance.voice = validatedVoice ?? AVSpeechSynthesisVoice(language: "en-US")
        
        utterance.rate = voiceSpeed
        utterance.volume = volume
        utterance.pitchMultiplier = 1.0
        
        // Add slight variation for natural feel
        utterance.rate += Float.random(in: -0.02...0.02)
        utterance.pitchMultiplier += Float.random(in: -0.05...0.05)
        
        currentlySpeaking = true
        lastMessage = message.text
        synthesizer.speak(utterance)
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.currentlySpeaking = false
            self?.isProcessingQueue = false
            self?.processQueue()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.currentlySpeaking = false
            self?.isProcessingQueue = false
            self?.processQueue()
        }
    }
    
    // MARK: - Voice Options
    
    /// Get available voices
    func getAvailableVoices() -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices().filter { voice in
            voice.language.starts(with: "en")
        }
    }
    
    /// Set the voice to use
    func setVoice(identifier: String) {
        selectedVoiceIdentifier = identifier
        UserDefaults.standard.set(identifier, forKey: "birdgame3_voicechat_voice")
        validateAndSetVoice() // Revalidate with new voice
    }
    
    // MARK: - Persistence
    
    private func loadSettings() {
        isEnabled = UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
        volume = UserDefaults.standard.object(forKey: volumeKey) as? Float ?? 0.8
        voiceSpeed = UserDefaults.standard.object(forKey: speedKey) as? Float ?? 0.52
        
        if let voiceId = UserDefaults.standard.string(forKey: "birdgame3_voicechat_voice") {
            selectedVoiceIdentifier = voiceId
        }
    }
    
    private func save() {
        UserDefaults.standard.set(isEnabled, forKey: enabledKey)
        UserDefaults.standard.set(volume, forKey: volumeKey)
        UserDefaults.standard.set(voiceSpeed, forKey: speedKey)
    }
}

// MARK: - Voice Message

struct VoiceMessage {
    let text: String
    let priority: VoicePriority
    let timestamp: Date = Date()
}

// MARK: - Voice Priority

enum VoicePriority: Int {
    case low = 0
    case normal = 1
    case high = 2
}

// MARK: - Battle Events

enum BattleEvent {
    case battleStart(player: BirdType, opponent: BirdType)
    case playerAttack(damage: Double)
    case playerAbility(bird: BirdType, abilityName: String)
    case opponentAttack(damage: Double)
    case opponentAbility(bird: BirdType, abilityName: String)
    case playerLowHealth
    case opponentLowHealth
    case playerBlock
    case playerDodge
    case criticalHit(damage: Double)
    case playerWin(isPerfect: Bool)
    case playerLose
    case closeMatch
    
    var priority: VoicePriority {
        switch self {
        case .battleStart, .playerWin, .playerLose:
            return .high
        case .playerAbility, .opponentAbility, .criticalHit, .closeMatch:
            return .normal
        default:
            return .low
        }
    }
}

// MARK: - Battle Commentary

struct BattleCommentary {
    
    static func battleStart(player: BirdType, opponent: BirdType) -> String {
        let options = [
            "Oh we got a \(player.displayName) versus \(opponent.displayName)! This is gonna be insane!",
            "Yo chat! \(player.displayName) is fighting \(opponent.displayName)! Let's gooo!",
            "The \(player.displayName) player just locked in. Let's see what they got!",
            "Chat is this even fair? \(player.displayName) against \(opponent.displayName)?!",
            "Oh it's a \(player.displayName)! Chat we might actually win this one!",
            "Alright alright, \(player.displayName) versus \(opponent.displayName). Classic matchup."
        ]
        return options.randomElement()!
    }
    
    static func playerAttack(damage: Double) -> String {
        let options: [String]
        if damage > 30 {
            options = [
                "HUGE damage! \(Int(damage)) pecks of pain!",
                "Oh that connected! \(Int(damage)) damage!",
                "CLEAN hit for \(Int(damage))!",
                "That's gotta hurt! \(Int(damage)) damage!"
            ]
        } else if damage > 15 {
            options = [
                "Nice hit! \(Int(damage)) damage!",
                "Solid peck for \(Int(damage))!",
                "There we go! \(Int(damage))!",
                "\(Int(damage)) damage, keep it up!"
            ]
        } else {
            options = [
                "Little chip damage there.",
                "Small hit but they add up!",
                "Poke poke!",
                "Every peck counts chat!"
            ]
        }
        return options.randomElement()!
    }
    
    static func playerAbility(bird: BirdType, ability: String) -> String {
        let options = [
            "OH \(ability.uppercased())! Let's go!",
            "THE \(ability.uppercased())! This is huge!",
            "\(bird.displayName) with the \(ability)! Insane!",
            "There it is! The \(ability)!",
            "Chat look at this! \(ability)!",
            "\(ability) activated! It's over!"
        ]
        return options.randomElement()!
    }
    
    static func opponentAttack(damage: Double) -> String {
        let options: [String]
        if damage > 30 {
            options = [
                "OOF that hurt! \(Int(damage)) damage taken!",
                "Big hit incoming! \(Int(damage))!",
                "That's a lot of damage chat!",
                "We're taking some heat here!"
            ]
        } else {
            options = [
                "Took a hit but we're fine!",
                "Little damage, no problem!",
                "Brush it off, brush it off!",
                "That's nothing!"
            ]
        }
        return options.randomElement()!
    }
    
    static func opponentAbility(bird: BirdType, ability: String) -> String {
        let options = [
            "Watch out! \(ability)!",
            "Oh no the \(ability)! Dodge it!",
            "\(bird.displayName) using \(ability)! Be careful!",
            "Incoming \(ability)! This could be bad!",
            "They're going for the \(ability)!"
        ]
        return options.randomElement()!
    }
    
    static func playerLowHealth() -> String {
        let options = [
            "Chat we're getting low! This is intense!",
            "Health is looking rough! Come on!",
            "We're one shot! Play safe!",
            "Low HP! Need to clutch this!",
            "It's not looking good chat!",
            "We're in the danger zone!"
        ]
        return options.randomElement()!
    }
    
    static func opponentLowHealth() -> String {
        let options = [
            "They're low! Finish them!",
            "One more hit chat! One more hit!",
            "They're about to go down!",
            "The enemy is weak! Attack!",
            "We got this! They're almost done!",
            "FINISH THEM!"
        ]
        return options.randomElement()!
    }
    
    static func playerBlock() -> String {
        let options = [
            "Nice block!",
            "Good defense!",
            "Blocked it! Big brain!",
            "Shield up! Smart play!"
        ]
        return options.randomElement()!
    }
    
    static func playerDodge() -> String {
        let options = [
            "Clean dodge!",
            "Matrix mode activated!",
            "Can't touch this!",
            "Dodged it! Too fast!"
        ]
        return options.randomElement()!
    }
    
    static func criticalHit(damage: Double) -> String {
        let options = [
            "CRITICAL HIT! \(Int(damage)) DAMAGE!",
            "OH THAT'S A CRIT! MASSIVE!",
            "CRITICAL! They felt that one!",
            "CRIT CITY! \(Int(damage)) DAMAGE!",
            "THE CRIT! THE CRIT! IT'S OVER!"
        ]
        return options.randomElement()!
    }
    
    static func playerWin(isPerfect: Bool) -> String {
        if isPerfect {
            let options = [
                "PERFECT VICTORY! Not a scratch! Absolutely flawless!",
                "PERFECT! They didn't even land a hit! God gamer!",
                "FLAWLESS VICTORY! Chat we're just built different!",
                "PERFECT WIN! Is this even fair anymore?!"
            ]
            return options.randomElement()!
        } else {
            let options = [
                "LET'S GOOO! We got the W!",
                "Victory! Another one for the highlight reel!",
                "GG EZ! Wait can I say that?",
                "We take those! Great fight!",
                "Winner winner chicken dinner! Wait wrong game.",
                "That's a dub chat! That's a dub!",
                "Victory secured! Bird Game 3 different!"
            ]
            return options.randomElement()!
        }
    }
    
    static func playerLose() -> String {
        let options = [
            "Nooo! We'll get them next time chat!",
            "GG, that was close though!",
            "Unfortunate! Run it back?",
            "They got us this time. Rematch incoming!",
            "Pain. Suffering even. But we go again!",
            "Skill diff... wait no, they got lucky!",
            "That's okay chat, that's okay. We learn, we grow."
        ]
        return options.randomElement()!
    }
    
    static func closeMatch() -> String {
        let options = [
            "This is SO close chat!",
            "It could go either way!",
            "Nail biter right here!",
            "Both birds are low! Anything can happen!",
            "This is what we play for! The clutch moments!",
            "Heart rate is through the roof!"
        ]
        return options.randomElement()!
    }
}
