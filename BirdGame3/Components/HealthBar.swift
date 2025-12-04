//
//  HealthBar.swift
//  BirdGame3
//
//  Visual representation of bird vitality
//

import SwiftUI

struct HealthBar: View {
    let currentHealth: Double
    let maxHealth: Double
    let isPlayer: Bool
    
    var healthPercentage: Double {
        max(0, min(1, currentHealth / maxHealth))
    }
    
    var healthColor: Color {
        if healthPercentage > 0.6 {
            return isPlayer ? .green : .red
        } else if healthPercentage > 0.3 {
            return .yellow
        } else {
            return isPlayer ? .red : .green
        }
    }
    
    var body: some View {
        VStack(alignment: isPlayer ? .leading : .trailing, spacing: 4) {
            // Health text
            HStack {
                if !isPlayer { Spacer() }
                Text("\(Int(currentHealth))/\(Int(maxHealth))")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                if isPlayer { Spacer() }
            }
            
            // Bar
            GeometryReader { geometry in
                ZStack(alignment: isPlayer ? .leading : .trailing) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                    
                    // Health fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(healthColor)
                        .frame(width: geometry.size.width * healthPercentage)
                    
                    // Border
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                }
            }
            .frame(height: 12)
        }
        .frame(width: 120)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(isPlayer ? "Your" : "Opponent's") health")
        .accessibilityValue("\(Int(healthPercentage * 100)) percent, \(Int(currentHealth)) of \(Int(maxHealth))")
    }
}

// MARK: - Animated Health Bar (for SpriteKit overlay)

struct AnimatedHealthBar: View {
    @Binding var currentHealth: Double
    let maxHealth: Double
    let isPlayer: Bool
    
    @State private var displayedHealth: Double = 0
    
    var body: some View {
        HealthBar(currentHealth: displayedHealth, maxHealth: maxHealth, isPlayer: isPlayer)
            .onChange(of: currentHealth) { _, newValue in
                withAnimation(.easeOut(duration: 0.3)) {
                    displayedHealth = newValue
                }
            }
            .onAppear {
                displayedHealth = currentHealth
            }
    }
}

// MARK: - Mini Health Bar (for small displays)

struct MiniHealthBar: View {
    let percentage: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * max(0, min(1, percentage)))
            }
        }
        .frame(height: 6)
        .cornerRadius(3)
    }
}

#Preview {
    VStack(spacing: 20) {
        HealthBar(currentHealth: 80, maxHealth: 100, isPlayer: true)
        HealthBar(currentHealth: 40, maxHealth: 100, isPlayer: false)
        HealthBar(currentHealth: 20, maxHealth: 100, isPlayer: true)
        
        MiniHealthBar(percentage: 0.7, color: .green)
            .frame(width: 100)
    }
    .padding()
    .background(Color.black)
}
