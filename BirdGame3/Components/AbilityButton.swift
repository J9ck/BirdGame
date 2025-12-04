//
//  AbilityButton.swift
//  BirdGame3
//
//  Special move activation interface
//

import SwiftUI

struct AbilityButton: View {
    let abilityName: String
    let isReady: Bool
    let cooldownRemaining: Double
    let totalCooldown: Double
    let action: () -> Void
    
    var cooldownPercentage: Double {
        guard totalCooldown > 0 else { return 1 }
        return 1 - (cooldownRemaining / totalCooldown)
    }
    
    var body: some View {
        Button(action: {
            if isReady {
                action()
            }
        }) {
            ZStack {
                // Background circle
                Circle()
                    .fill(isReady ? Color.yellow : Color.gray.opacity(0.5))
                    .frame(width: 70, height: 70)
                
                // Cooldown overlay
                if !isReady {
                    Circle()
                        .trim(from: 0, to: cooldownPercentage)
                        .stroke(Color.yellow.opacity(0.7), lineWidth: 4)
                        .frame(width: 66, height: 66)
                        .rotationEffect(.degrees(-90))
                }
                
                // Border
                Circle()
                    .stroke(isReady ? Color.orange : Color.gray, lineWidth: 3)
                    .frame(width: 70, height: 70)
                
                // Icon
                VStack(spacing: 2) {
                    Text("✨")
                        .font(.system(size: 24))
                    
                    if !isReady {
                        Text(String(format: "%.1f", cooldownRemaining))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .disabled(!isReady)
        .opacity(isReady ? 1.0 : 0.7)
    }
}

// MARK: - Ability Info View

struct AbilityInfoView: View {
    let birdType: BirdType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("✨")
                    .font(.title2)
                
                Text(birdType.abilityName)
                    .font(.headline)
                    .foregroundColor(.yellow)
            }
            
            Text(birdType.abilityDescription)
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack {
                Text("Cooldown:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("\(birdType.baseStats.abilityCooldown, specifier: "%.1f")s")
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Damage:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("\(Int(birdType.baseStats.abilityDamage))")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Compact Ability Button

struct CompactAbilityButton: View {
    let isReady: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if isReady {
                action()
            }
        }) {
            ZStack {
                Circle()
                    .fill(isReady ? Color.yellow.opacity(0.8) : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                Circle()
                    .stroke(isReady ? Color.orange : Color.gray, lineWidth: 2)
                    .frame(width: 50, height: 50)
                
                Text("✨")
                    .font(.system(size: 20))
            }
        }
        .disabled(!isReady)
    }
}

#Preview {
    VStack(spacing: 20) {
        AbilityButton(
            abilityName: "Breadcrumb Frenzy",
            isReady: true,
            cooldownRemaining: 0,
            totalCooldown: 5,
            action: {}
        )
        
        AbilityButton(
            abilityName: "Hover Strike",
            isReady: false,
            cooldownRemaining: 2.3,
            totalCooldown: 3,
            action: {}
        )
        
        AbilityInfoView(birdType: .pigeon)
            .frame(width: 250)
        
        CompactAbilityButton(isReady: true, action: {})
    }
    .padding()
    .background(Color.black)
}
