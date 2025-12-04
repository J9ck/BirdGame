//
//  LiveVoiceChatManager.swift
//  BirdGame3
//
//  Real-time voice chat for squad communication (WebRTC-based)
//

import Foundation
import AVFoundation
import SwiftUI
import UIKit

// MARK: - Voice Chat Participant

struct VoiceChatParticipant: Identifiable, Equatable {
    let id: String
    var displayName: String
    var isMuted: Bool
    var isSpeaking: Bool
    var volume: Float
    var isSelf: Bool
    
    static func == (lhs: VoiceChatParticipant, rhs: VoiceChatParticipant) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Voice Chat Channel

struct VoiceChatChannel: Identifiable {
    let id: String
    let name: String
    let type: ChannelType
    var participants: [VoiceChatParticipant]
    var maxParticipants: Int
    var isLocked: Bool
    
    enum ChannelType {
        case party
        case team
        case proximity
        case global
    }
    
    var participantCount: Int {
        participants.count
    }
    
    var isFull: Bool {
        participants.count >= maxParticipants
    }
}

// MARK: - Voice Chat Settings

struct VoiceChatSettings: Codable {
    var inputDevice: String?
    var outputDevice: String?
    var inputVolume: Float = 1.0
    var outputVolume: Float = 1.0
    var voiceActivationThreshold: Float = 0.02
    var noiseSuppression: Bool = true
    var echoCancellation: Bool = true
    var pushToTalk: Bool = false
    var pushToTalkKey: String = "V"
    var muteWhenDeafened: Bool = true
    var autoJoinPartyVoice: Bool = true
    var proximityVoiceEnabled: Bool = true
    var proximityRange: Float = 50.0 // In-game units
}

// MARK: - Voice Activity

enum VoiceActivity {
    case idle
    case speaking
    case muted
    case deafened
    case connecting
    case disconnected
}

// MARK: - Live Voice Chat Manager

class LiveVoiceChatManager: NSObject, ObservableObject {
    static let shared = LiveVoiceChatManager()
    
    // MARK: - Published Properties
    
    @Published var isConnected: Bool = false
    @Published var isConnecting: Bool = false
    @Published var isMuted: Bool = false
    @Published var isDeafened: Bool = false
    @Published var isSpeaking: Bool = false
    @Published var voiceActivity: VoiceActivity = .disconnected
    
    @Published var currentChannel: VoiceChatChannel?
    @Published var participants: [VoiceChatParticipant] = []
    @Published var speakingParticipants: Set<String> = []
    
    @Published var settings: VoiceChatSettings
    
    @Published var connectionQuality: ConnectionQuality = .good
    @Published var latency: Int = 0 // ms
    
    // Audio levels
    @Published var inputLevel: Float = 0
    @Published var outputLevel: Float = 0
    
    // MARK: - Private Properties
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var playerNode: AVAudioPlayerNode?
    
    private var voiceActivityTimer: Timer?
    private var connectionTimer: Timer?
    
    // Persistence
    private let settingsKey = "birdgame3_voicechat_settings"
    
    // MARK: - Initialization
    
    private override init() {
        // Load settings
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let savedSettings = try? JSONDecoder().decode(VoiceChatSettings.self, from: data) {
            self.settings = savedSettings
        } else {
            self.settings = VoiceChatSettings()
        }
        
        super.init()
        
        setupAudioSession()
        requestMicrophonePermission()
    }
    
    // MARK: - Audio Setup
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    print("Microphone permission denied")
                }
            }
        }
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else { return }
        
        inputNode = engine.inputNode
        playerNode = AVAudioPlayerNode()
        
        guard let player = playerNode else { return }
        engine.attach(player)
        
        // Setup audio format
        let format = inputNode?.outputFormat(forBus: 0)
        
        // Install tap for voice activity detection
        inputNode?.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
            self?.processInputBuffer(buffer)
        }
        
        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func processInputBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride).map { channelDataValue[$0] }
        
        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        
        DispatchQueue.main.async { [weak self] in
            self?.inputLevel = rms
            
            // Voice activity detection
            if let threshold = self?.settings.voiceActivationThreshold,
               !self!.settings.pushToTalk {
                let wasSpeaking = self?.isSpeaking ?? false
                let nowSpeaking = rms > threshold
                
                if nowSpeaking != wasSpeaking {
                    self?.isSpeaking = nowSpeaking
                    self?.voiceActivity = nowSpeaking ? .speaking : .idle
                }
            }
        }
    }
    
    // MARK: - Connection
    
    func connect(to channel: VoiceChatChannel) {
        guard !isConnected else { return }
        
        isConnecting = true
        voiceActivity = .connecting
        
        // In production, connect to voice server via WebRTC
        // For now, simulate connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.currentChannel = channel
            self?.isConnected = true
            self?.isConnecting = false
            self?.voiceActivity = .idle
            
            // Setup audio processing
            self?.setupAudioEngine()
            
            // Add self as participant
            let selfParticipant = VoiceChatParticipant(
                id: AccountManager.shared.currentAccount?.id ?? UUID().uuidString,
                displayName: AccountManager.shared.currentAccount?.displayName ?? "You",
                isMuted: self?.isMuted ?? false,
                isSpeaking: false,
                volume: 1.0,
                isSelf: true
            )
            
            self?.participants = [selfParticipant] + (channel.participants.filter { !$0.isSelf })
            
            // Start monitoring
            self?.startConnectionMonitoring()
            
            // Announce join
            VoiceChatManager.shared.speak("Connected to voice chat", priority: .low)
        }
    }
    
    func disconnect() {
        stopConnectionMonitoring()
        
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        audioEngine = nil
        
        currentChannel = nil
        participants = []
        isConnected = false
        voiceActivity = .disconnected
    }
    
    func joinPartyVoice() {
        guard let party = MultiplayerManager.shared.currentParty else { return }
        
        let channel = VoiceChatChannel(
            id: party.id,
            name: "Party Voice",
            type: .party,
            participants: party.members.map { member in
                VoiceChatParticipant(
                    id: member.id,
                    displayName: member.displayName,
                    isMuted: false,
                    isSpeaking: false,
                    volume: 1.0,
                    isSelf: member.isLocalPlayer
                )
            },
            maxParticipants: 4,
            isLocked: false
        )
        
        connect(to: channel)
    }
    
    func joinTeamVoice() {
        // Join team voice channel in match
        let channel = VoiceChatChannel(
            id: UUID().uuidString,
            name: "Team Voice",
            type: .team,
            participants: [],
            maxParticipants: 50,
            isLocked: false
        )
        
        connect(to: channel)
    }
    
    // MARK: - Mute/Deafen
    
    func toggleMute() {
        isMuted.toggle()
        
        if isMuted {
            voiceActivity = .muted
        } else {
            voiceActivity = isSpeaking ? .speaking : .idle
        }
        
        updateSelfParticipant()
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func toggleDeafen() {
        isDeafened.toggle()
        
        if isDeafened {
            // Mute when deafening
            if settings.muteWhenDeafened {
                isMuted = true
            }
            voiceActivity = .deafened
            
            // Mute all audio output
            audioEngine?.mainMixerNode.outputVolume = 0
        } else {
            voiceActivity = isMuted ? .muted : .idle
            audioEngine?.mainMixerNode.outputVolume = settings.outputVolume
        }
        
        updateSelfParticipant()
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func setMuted(_ muted: Bool) {
        guard muted != isMuted else { return }
        toggleMute()
    }
    
    // MARK: - Push to Talk
    
    func pushToTalkPressed() {
        guard settings.pushToTalk && isConnected && !isMuted else { return }
        
        isSpeaking = true
        voiceActivity = .speaking
        updateSelfParticipant()
    }
    
    func pushToTalkReleased() {
        guard settings.pushToTalk else { return }
        
        isSpeaking = false
        voiceActivity = isMuted ? .muted : .idle
        updateSelfParticipant()
    }
    
    // MARK: - Participant Management
    
    func setParticipantVolume(_ participantId: String, volume: Float) {
        guard let index = participants.firstIndex(where: { $0.id == participantId }) else { return }
        participants[index].volume = max(0, min(2.0, volume)) // 0-200%
    }
    
    func muteParticipant(_ participantId: String, muted: Bool) {
        guard let index = participants.firstIndex(where: { $0.id == participantId }) else { return }
        participants[index].isMuted = muted
    }
    
    private func updateSelfParticipant() {
        guard let index = participants.firstIndex(where: { $0.isSelf }) else { return }
        participants[index].isMuted = isMuted
        participants[index].isSpeaking = isSpeaking
    }
    
    // MARK: - Connection Monitoring
    
    private func startConnectionMonitoring() {
        connectionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            // Simulate latency updates
            self?.latency = Int.random(in: 20...80)
            
            // Determine connection quality
            if let latency = self?.latency {
                if latency < 50 {
                    self?.connectionQuality = .excellent
                } else if latency < 100 {
                    self?.connectionQuality = .good
                } else if latency < 200 {
                    self?.connectionQuality = .fair
                } else {
                    self?.connectionQuality = .poor
                }
            }
            
            // Simulate other participants speaking
            self?.simulateParticipantActivity()
        }
    }
    
    private func stopConnectionMonitoring() {
        connectionTimer?.invalidate()
        connectionTimer = nil
    }
    
    private func simulateParticipantActivity() {
        for i in 0..<participants.count {
            if !participants[i].isSelf && !participants[i].isMuted {
                // Random speaking activity
                let wasSpeaking = participants[i].isSpeaking
                let nowSpeaking = Double.random(in: 0...1) < 0.1 // 10% chance each second
                
                if nowSpeaking != wasSpeaking {
                    participants[i].isSpeaking = nowSpeaking
                    
                    if nowSpeaking {
                        speakingParticipants.insert(participants[i].id)
                    } else {
                        speakingParticipants.remove(participants[i].id)
                    }
                }
            }
        }
    }
    
    // MARK: - Settings
    
    func updateSettings(_ newSettings: VoiceChatSettings) {
        settings = newSettings
        
        // Apply audio settings
        audioEngine?.mainMixerNode.outputVolume = isDeafened ? 0 : settings.outputVolume
        
        // Save settings
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }
    
    // MARK: - Audio Devices
    
    func getAvailableInputDevices() -> [AVAudioSessionPortDescription] {
        AVAudioSession.sharedInstance().availableInputs ?? []
    }
    
    func getAvailableOutputDevices() -> [AVAudioSessionPortDescription] {
        AVAudioSession.sharedInstance().currentRoute.outputs
    }
    
    func setInputDevice(_ device: AVAudioSessionPortDescription) {
        do {
            try AVAudioSession.sharedInstance().setPreferredInput(device)
            settings.inputDevice = device.uid
        } catch {
            print("Failed to set input device: \(error)")
        }
    }
}

// MARK: - Connection Quality

enum ConnectionQuality {
    case excellent
    case good
    case fair
    case poor
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .green
        case .fair: return .yellow
        case .poor: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .excellent: return "wifi"
        case .good: return "wifi"
        case .fair: return "wifi.exclamationmark"
        case .poor: return "wifi.slash"
        }
    }
    
    var bars: Int {
        switch self {
        case .excellent: return 4
        case .good: return 3
        case .fair: return 2
        case .poor: return 1
        }
    }
}

// MARK: - Voice Chat Overlay View

struct VoiceChatOverlay: View {
    @ObservedObject var voiceChat = LiveVoiceChatManager.shared
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                // Voice chat indicator
                if voiceChat.isConnected {
                    VStack(alignment: .trailing, spacing: 4) {
                        // Speaking indicators
                        ForEach(voiceChat.participants.filter { $0.isSpeaking }) { participant in
                            HStack(spacing: 6) {
                                Text(participant.displayName)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                
                                Image(systemName: "waveform")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                        }
                        
                        // Self status
                        HStack(spacing: 8) {
                            // Connection quality
                            Image(systemName: voiceChat.connectionQuality.icon)
                                .foregroundColor(voiceChat.connectionQuality.color)
                                .font(.caption)
                            
                            // Mute status
                            if voiceChat.isDeafened {
                                Image(systemName: "speaker.slash.fill")
                                    .foregroundColor(.red)
                            } else if voiceChat.isMuted {
                                Image(systemName: "mic.slash.fill")
                                    .foregroundColor(.red)
                            } else if voiceChat.isSpeaking {
                                Image(systemName: "mic.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "mic.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Voice Chat Controls View

struct VoiceChatControlsView: View {
    @ObservedObject var voiceChat = LiveVoiceChatManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Mute button
            Button(action: { voiceChat.toggleMute() }) {
                Image(systemName: voiceChat.isMuted ? "mic.slash.fill" : "mic.fill")
                    .font(.title2)
                    .foregroundColor(voiceChat.isMuted ? .red : .white)
                    .frame(width: 44, height: 44)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(Circle())
            }
            
            // Deafen button
            Button(action: { voiceChat.toggleDeafen() }) {
                Image(systemName: voiceChat.isDeafened ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundColor(voiceChat.isDeafened ? .red : .white)
                    .frame(width: 44, height: 44)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(Circle())
            }
            
            // Push to talk (if enabled)
            if voiceChat.settings.pushToTalk {
                Button(action: {}) {
                    Image(systemName: "hand.tap.fill")
                        .font(.title2)
                        .foregroundColor(voiceChat.isSpeaking ? .green : .white)
                        .frame(width: 44, height: 44)
                        .background(voiceChat.isSpeaking ? Color.green.opacity(0.3) : Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in voiceChat.pushToTalkPressed() }
                        .onEnded { _ in voiceChat.pushToTalkReleased() }
                )
            }
        }
    }
}

