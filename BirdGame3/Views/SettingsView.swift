//
//  SettingsView.swift
//  BirdGame3
//
//  Settings and configuration screen
//

import SwiftUI
import AVFoundation

struct SettingsView: View {
    @EnvironmentObject var gameState: GameState
    @ObservedObject var voiceChat = VoiceChatManager.shared
    @ObservedObject var soundManager = SoundManager.shared
    
    @State private var showResetConfirmation = false
    @State private var selectedVoiceIndex = 0
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Settings list
                ScrollView {
                    VStack(spacing: 24) {
                        // Audio Settings
                        audioSettingsSection
                        
                        // Voice Chat Settings
                        voiceChatSection
                        
                        // Account/Data
                        accountSection
                        
                        // About
                        aboutSection
                    }
                    .padding()
                }
            }
        }
        .alert("Reset Progress?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllProgress()
            }
        } message: {
            Text("This will reset all your coins, skins, levels, and stats. This cannot be undone!")
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Button(action: { gameState.navigateTo(.mainMenu) }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text("⚙️ SETTINGS")
                .font(.title2)
                .fontWeight(.black)
                .foregroundColor(.white)
            
            Spacer()
            
            // Placeholder for symmetry
            Image(systemName: "xmark.circle.fill")
                .font(.title)
                .foregroundColor(.clear)
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Audio Settings
    
    private var audioSettingsSection: some View {
        SettingsSection(title: "🔊 Audio") {
            // Music volume
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Music Volume")
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(soundManager.musicVolume * 100))%")
                        .foregroundColor(.gray)
                }
                Slider(value: $soundManager.musicVolume, in: 0...1)
                    .tint(.blue)
            }
            
            // SFX volume
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Sound Effects")
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(soundManager.sfxVolume * 100))%")
                        .foregroundColor(.gray)
                }
                Slider(value: $soundManager.sfxVolume, in: 0...1)
                    .tint(.blue)
            }
            
            // Haptics toggle
            Toggle(isOn: $soundManager.hapticsEnabled) {
                Text("Haptic Feedback")
                    .foregroundColor(.white)
            }
            .tint(.green)
        }
    }
    
    // MARK: - Voice Chat Settings
    
    private var voiceChatSection: some View {
        SettingsSection(title: "🎙️ Voice Commentary") {
            // Enable voice chat
            Toggle(isOn: $voiceChat.isEnabled) {
                Text("Voice Commentary")
                    .foregroundColor(.white)
            }
            .tint(.green)
            
            if voiceChat.isEnabled {
                // Volume
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Voice Volume")
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(voiceChat.volume * 100))%")
                            .foregroundColor(.gray)
                    }
                    Slider(value: $voiceChat.volume, in: 0...1)
                        .tint(.cyan)
                }
                
                // Speed
                // Speed slider with documented range
                // AVSpeechUtterance rate ranges from 0 (slowest) to 1 (fastest)
                // 0.4-0.65 provides natural speech without being too fast or robotic
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Voice Speed")
                            .foregroundColor(.white)
                        Spacer()
                        Text(speedLabel)
                            .foregroundColor(.gray)
                    }
                    Slider(value: $voiceChat.voiceSpeed, in: VoiceChatManager.minVoiceSpeed...VoiceChatManager.maxVoiceSpeed)
                        .tint(.cyan)
                }
                
                // Test voice button
                Button(action: testVoice) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Test Voice")
                    }
                    .foregroundColor(.cyan)
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    private var speedLabel: String {
        if voiceChat.voiceSpeed < 0.45 {
            return "Slow"
        } else if voiceChat.voiceSpeed < 0.55 {
            return "Normal"
        } else {
            return "Fast"
        }
    }
    
    private func testVoice() {
        voiceChat.speak("Let's go chat! Bird Game 3 is the best game ever made!", priority: .high)
    }
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        SettingsSection(title: "👤 Account") {
            // Stats
            HStack {
                Text("Total Wins")
                    .foregroundColor(.white)
                Spacer()
                Text("\(gameState.playerStats.wins)")
                    .foregroundColor(.green)
                    .fontWeight(.bold)
            }
            
            HStack {
                Text("Current Rank")
                    .foregroundColor(.white)
                Spacer()
                Text(gameState.playerStats.rank)
                    .foregroundColor(.yellow)
            }
            
            HStack {
                Text("Level")
                    .foregroundColor(.white)
                Spacer()
                Text(PrestigeManager.shared.displayLevel)
                    .foregroundColor(.purple)
                    .fontWeight(.bold)
            }
            
            // Reset button
            Button(action: { showResetConfirmation = true }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Reset All Progress")
                }
                .foregroundColor(.red)
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        SettingsSection(title: "ℹ️ About") {
            HStack {
                Text("Version")
                    .foregroundColor(.white)
                Spacer()
                Text("3.47.2")
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("Build")
                    .foregroundColor(.white)
                Spacer()
                Text("LEGENDARY")
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Bird Game 3")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                Text("There is no Bird Game 1 or 2. Only 3.")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("🐦 PIGEON MAINS RISE UP 🐦")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
    }
    
    // MARK: - Actions
    
    private func resetAllProgress() {
        CurrencyManager.shared.reset()
        SkinManager.shared.reset()
        PrestigeManager.shared.reset()
        gameState.resetPlayerStats()
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                content()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.15))
            )
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(GameState())
}
