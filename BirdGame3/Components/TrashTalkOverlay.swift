//
//  TrashTalkOverlay.swift
//  BirdGame3
//
//  The essential trash talk experience
//

import SwiftUI

struct TrashTalkOverlay: View {
    @State private var currentMessage: String = ""
    @State private var isVisible: Bool = false
    @State private var messageQueue: [String] = []
    
    let generator = TrashTalkGenerator.shared
    
    var body: some View {
        VStack {
            Spacer()
            
            if isVisible {
                TrashTalkBubble(message: currentMessage)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
            
            Spacer()
                .frame(height: 150) // Space for controls
        }
        .onAppear {
            startMessageLoop()
        }
    }
    
    private func startMessageLoop() {
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            showNextMessage()
        }
        // Show first message immediately
        showNextMessage()
    }
    
    private func showNextMessage() {
        withAnimation(.spring(response: 0.3)) {
            isVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentMessage = generator.getRandomMessage()
            withAnimation(.spring(response: 0.3)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Trash Talk Bubble

struct TrashTalkBubble: View {
    let message: String
    
    var body: some View {
        HStack {
            // Fake username
            Text(TrashTalkGenerator.shared.getRandomUsername() + ":")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.cyan)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: .cyan.opacity(0.3), radius: 5)
    }
}

// MARK: - Floating Trash Talk

struct FloatingTrashTalk: View {
    let message: String
    let position: TrashTalkPosition
    
    enum TrashTalkPosition {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
    
    var alignment: Alignment {
        switch position {
        case .topLeft: return .topLeading
        case .topRight: return .topTrailing
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            TrashTalkBubble(message: message)
                .frame(maxWidth: geometry.size.width * 0.6)
                .position(positionFor(position, in: geometry.size))
        }
    }
    
    private func positionFor(_ position: TrashTalkPosition, in size: CGSize) -> CGPoint {
        switch position {
        case .topLeft:
            return CGPoint(x: size.width * 0.25, y: 100)
        case .topRight:
            return CGPoint(x: size.width * 0.75, y: 100)
        case .bottomLeft:
            return CGPoint(x: size.width * 0.25, y: size.height - 150)
        case .bottomRight:
            return CGPoint(x: size.width * 0.75, y: size.height - 150)
        }
    }
}

// MARK: - Kill Feed Style Messages

struct KillFeedMessage: View {
    let attacker: String
    let defender: String
    let action: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(attacker)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.cyan)
            
            Text(action)
                .font(.caption2)
                .foregroundColor(.gray)
            
            Text(defender)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.6))
        .cornerRadius(4)
    }
}

// MARK: - Announcement Banner

struct AnnouncementBanner: View {
    let text: String
    let type: AnnouncementType
    
    enum AnnouncementType {
        case fight
        case ability
        case victory
        case defeat
        
        var color: Color {
            switch self {
            case .fight: return .red
            case .ability: return .yellow
            case .victory: return .green
            case .defeat: return .gray
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 32, weight: .heavy))
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(type.color.opacity(0.8))
                    .shadow(color: type.color, radius: 10)
            )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 20) {
            TrashTalkBubble(message: "PIGEON MAINS RISE UP")
            
            KillFeedMessage(attacker: "xX_PigeonLord_Xx", defender: "EagleFan2024", action: "pecked")
            
            AnnouncementBanner(text: "FIGHT!", type: .fight)
            
            AnnouncementBanner(text: "VICTORY!", type: .victory)
        }
    }
}
