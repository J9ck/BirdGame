#if canImport(SwiftUI)
import SwiftUI

/// A health bar display showing current health status
struct HealthBar: View {
    // MARK: - Properties
    
    /// Name of the entity (bird)
    let name: String
    
    /// Current health value
    let currentHealth: Double
    
    /// Maximum health value
    let maxHealth: Double
    
    /// Whether this is the enemy health bar (affects alignment)
    var isEnemy: Bool = false
    
    /// Width of the health bar
    var width: CGFloat = 150
    
    /// Height of the health bar
    var height: CGFloat = 16
    
    // MARK: - Computed Properties
    
    private var healthPercentage: Double {
        guard maxHealth > 0 else { return 0 }
        return max(0, min(1, currentHealth / maxHealth))
    }
    
    private var healthColor: Color {
        if healthPercentage > 0.5 {
            return .green
        } else if healthPercentage > 0.25 {
            return .yellow
        } else {
            return .red
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: isEnemy ? .trailing : .leading, spacing: 4) {
            // Name label
            Text(name)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            // Health bar container
            ZStack(alignment: isEnemy ? .trailing : .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: width, height: height)
                
                // Health fill
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(healthColor)
                    .frame(width: width * healthPercentage, height: height)
                    .animation(.easeInOut(duration: 0.3), value: healthPercentage)
                
                // Border
                RoundedRectangle(cornerRadius: height / 2)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    .frame(width: width, height: height)
                
                // Health text
                Text("\(Int(currentHealth))/\(Int(maxHealth))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name) health")
        .accessibilityValue("\(Int(currentHealth)) of \(Int(maxHealth))")
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 30) {
            HealthBar(name: "Phoenix", currentHealth: 80, maxHealth: 100)
            HealthBar(name: "Hawk", currentHealth: 45, maxHealth: 100)
            HealthBar(name: "Enemy Owl", currentHealth: 15, maxHealth: 90, isEnemy: true)
        }
    }
}
#endif
