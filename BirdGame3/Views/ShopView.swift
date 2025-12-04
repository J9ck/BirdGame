//
//  ShopView.swift
//  BirdGame3
//
//  Shop interface for purchasing skins and cosmetics
//

import SwiftUI

struct ShopView: View {
    @EnvironmentObject var gameState: GameState
    @ObservedObject var skinManager = SkinManager.shared
    @ObservedObject var currencyManager = CurrencyManager.shared
    @ObservedObject var prestigeManager = PrestigeManager.shared
    
    @State private var selectedBirdType: BirdType = .pigeon
    @State private var selectedSkin: BirdSkin?
    @State private var showPurchaseAlert = false
    @State private var purchaseResult: PurchaseResult?
    
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
                // Header with currency
                shopHeader
                
                // Bird type selector
                birdTypeSelector
                
                // Skins grid
                skinsGrid
            }
        }
        .alert("Purchase", isPresented: $showPurchaseAlert) {
            purchaseAlertButtons
        } message: {
            purchaseAlertMessage
        }
    }
    
    // MARK: - Header
    
    private var shopHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: { gameState.navigateTo(.mainMenu) }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Text("🛒 SKIN SHOP")
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Placeholder for symmetry
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.clear)
            }
            .padding(.horizontal)
            
            // Currency display
            HStack(spacing: 20) {
                CurrencyBadge(icon: "🪙", amount: currencyManager.coins, color: .yellow)
                CurrencyBadge(icon: "🪶", amount: currencyManager.feathers, color: .cyan)
                
                Spacer()
                
                Text(prestigeManager.displayLevel)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.purple.opacity(0.3))
                    )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Bird Type Selector
    
    private var birdTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BirdType.allCases) { birdType in
                    BirdTypeTab(
                        birdType: birdType,
                        isSelected: selectedBirdType == birdType,
                        action: { selectedBirdType = birdType }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color.black.opacity(0.2))
    }
    
    // MARK: - Skins Grid
    
    private var skinsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(skinManager.skins(for: selectedBirdType)) { skin in
                    SkinCard(
                        skin: skin,
                        isOwned: skinManager.owns(skinId: skin.id),
                        isEquipped: skinManager.equippedSkins[selectedBirdType.rawValue] == skin.id,
                        onTap: { handleSkinTap(skin) }
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Purchase Alert
    
    @ViewBuilder
    private var purchaseAlertButtons: some View {
        if let skin = selectedSkin {
            if skinManager.owns(skinId: skin.id) {
                // Already owned - equip
                Button("Equip") {
                    _ = skinManager.equip(skin: skin)
                    purchaseResult = .equipped
                }
                Button("Cancel", role: .cancel) { }
            } else if skin.price.isFree {
                // Free skin (needs unlock requirement)
                Button("OK", role: .cancel) { }
            } else {
                // Purchase
                Button("Buy") {
                    if skinManager.purchase(skin: skin) {
                        purchaseResult = .success
                        _ = skinManager.equip(skin: skin)
                    } else {
                        purchaseResult = .insufficientFunds
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    @ViewBuilder
    private var purchaseAlertMessage: some View {
        if let skin = selectedSkin {
            if skinManager.owns(skinId: skin.id) {
                Text("Equip \(skin.name)?")
            } else if let requirement = skin.unlockRequirement {
                Text("\(skin.name)\n\nUnlock requirement: \(requirement.description)")
            } else if skin.price.coins > 0 || skin.price.feathers > 0 {
                let priceText = formatPrice(skin.price)
                Text("Purchase \(skin.name) for \(priceText)?")
            } else {
                Text(skin.name)
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleSkinTap(_ skin: BirdSkin) {
        selectedSkin = skin
        showPurchaseAlert = true
    }
    
    private func formatPrice(_ price: SkinPrice) -> String {
        var parts: [String] = []
        if price.coins > 0 {
            parts.append("🪙\(price.coins)")
        }
        if price.feathers > 0 {
            parts.append("🪶\(price.feathers)")
        }
        return parts.joined(separator: " + ")
    }
}

// MARK: - Purchase Result

enum PurchaseResult {
    case success
    case equipped
    case insufficientFunds
}

// MARK: - Currency Badge

struct CurrencyBadge: View {
    let icon: String
    let amount: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(icon)
                .font(.title3)
            Text("\(amount)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

// MARK: - Bird Type Tab

struct BirdTypeTab: View {
    let birdType: BirdType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(birdType.emoji)
                    .font(.title)
                Text(birdType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.4) : Color.gray.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

// --- Replace the SkinCard struct in ShopView.swift with this implementation ---

struct SkinCard: View {
    let skin: BirdSkin
    let isOwned: Bool
    let isEquipped: Bool
    let onTap: () -> Void

    var body: some View {
        // Break complex expressions into local values to help the type checker
        let primaryColor: Color = {
            if let c = Color(hex: skin.colorScheme.primary) { return c }
            return Color.gray
        }()

        let secondaryColor: Color = {
            if let c = Color(hex: skin.colorScheme.secondary) { return c }
            return Color(UIColor.darkGray)
        }()

        let bgGradient = LinearGradient(
            colors: [primaryColor, secondaryColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        return Button(action: onTap) {
            VStack(spacing: 8) {
                // Skin preview
                ZStack {
                    // Rarity glow
                    RoundedRectangle(cornerRadius: 16)
                        .fill(skin.rarity.glowColor)
                        .blur(radius: 10)

                    RoundedRectangle(cornerRadius: 16)
                        .fill(bgGradient)
                        .frame(height: 120)

                    // Optionally an image/emoji placeholder
                    Text(BirdType(rawValue: skin.birdType)?.emoji ?? "🐦")
                        .font(.system(size: 48))
                }
                .frame(height: 120)
                .cornerRadius(16)
                
                // Name and status
                VStack(alignment: .leading, spacing: 4) {
                    Text(skin.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    HStack(spacing: 8) {
                        if isOwned {
                            Text("Owned")
                                .font(.caption2)
                                .foregroundColor(.green)
                                .padding(4)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(6)
                        }
                        if isEquipped {
                            Text("Equipped")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                                .padding(4)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(6)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.25)))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ShopView()
        .environmentObject(GameState())
}
