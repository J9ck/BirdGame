//
//  PauseMenuView.swift
//  BirdGame3
//
//  Pause menu overlay during gameplay
//

import SwiftUI

struct PauseMenuView: View {
    @EnvironmentObject var gameState: GameState
    @Binding var isPaused: Bool
    @Binding var showSettings: Bool
    let onResume: () -> Void
    let onQuit: () -> Void
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    // Tapping background resumes
                    resume()
                }
            
            // Pause menu content
            VStack(spacing: 20) {
                // Title
                VStack(spacing: 8) {
                    Text("⏸️ PAUSED")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Text("Take a breather, bird warrior")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Battle info
                VStack(spacing: 8) {
                    HStack(spacing: 30) {
                        VStack {
                            Text(gameState.selectedBird.emoji)
                                .font(.system(size: 40))
                            Text("YOU")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        Text("VS")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        VStack {
                            Text(gameState.opponentBird.emoji)
                                .font(.system(size: 40))
                            Text("CPU")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                
                // Menu buttons
                VStack(spacing: 12) {
                    PauseMenuButton(
                        title: "▶️ Resume",
                        subtitle: "Continue the battle",
                        color: .green
                    ) {
                        resume()
                    }
                    
                    PauseMenuButton(
                        title: "⚙️ Settings",
                        subtitle: "Adjust audio & voice",
                        color: .blue
                    ) {
                        showSettings = true
                    }
                    
                    PauseMenuButton(
                        title: "🏳️ Forfeit",
                        subtitle: "Surrender this match",
                        color: .red
                    ) {
                        forfeit()
                    }
                    
                    PauseMenuButton(
                        title: "🏠 Quit to Menu",
                        subtitle: "Exit without saving",
                        color: .gray
                    ) {
                        quit()
                    }
                }
                .padding(.horizontal, 40)
                
                // Control hint
                Text("Tap anywhere to resume")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 10)
            }
            .padding(.vertical, 30)
        }
        .transition(.opacity)
    }
    
    private func resume() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isPaused = false
        }
        onResume()
    }
    
    private func forfeit() {
        // Count as a loss
        gameState.endBattle(
            playerWon: false,
            duration: 0,
            damageDealt: 0,
            damageReceived: 0
        )
    }
    
    private func quit() {
        onQuit()
        gameState.returnToMenu()
    }
}

// MARK: - Pause Menu Button

struct PauseMenuButton: View {
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(isPressed ? 0.6 : 0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.6), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - In-Game Settings View

struct InGameSettingsView: View {
    @ObservedObject var voiceChat = VoiceChatManager.shared
    @ObservedObject var soundManager = SoundManager.shared
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("⚙️ Quick Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                // Audio settings
                VStack(spacing: 16) {
                    // Music
                    HStack {
                        Text("🎵 Music")
                            .foregroundColor(.white)
                        Spacer()
                        Slider(value: $soundManager.musicVolume, in: 0...1)
                            .frame(width: 150)
                            .tint(.blue)
                    }
                    
                    // SFX
                    HStack {
                        Text("🔊 Sound Effects")
                            .foregroundColor(.white)
                        Spacer()
                        Slider(value: $soundManager.sfxVolume, in: 0...1)
                            .frame(width: 150)
                            .tint(.blue)
                    }
                    
                    // Voice chat toggle
                    Toggle(isOn: $voiceChat.isEnabled) {
                        Text("🎙️ Voice Commentary")
                            .foregroundColor(.white)
                    }
                    .tint(.green)
                    
                    // Haptics toggle
                    Toggle(isOn: $soundManager.hapticsEnabled) {
                        Text("📳 Haptics")
                            .foregroundColor(.white)
                    }
                    .tint(.green)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(16)
                
                // Done button
                Button(action: { isPresented = false }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.15))
            )
            .padding(40)
        }
    }
}

#Preview {
    PauseMenuView(
        isPaused: .constant(true),
        showSettings: .constant(false),
        onResume: {},
        onQuit: {}
    )
    .environmentObject(GameState())
}
