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

// MARK: - Skin Card

struct SkinCard: View {
    let skin: BirdSkin
    let isOwned: Bool
    let isEquipped: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Skin preview
                ZStack {
                    // Rarity glow
                    RoundedRectangle(cornerRadius: 16)
                        .fill(skin.rarity.glowColor)
                        .blur(radius: 10)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: skin.colorScheme.primary) ?? .gray,
                                    Color(hex: skin.colorScheme.secondary) ?? .darkGray
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Bird emoji
                    if let birdType = BirdType(rawValue: skin.birdType) {
                        Text(birdType.emoji)
                            .font(.system(size: 50))
                    }
                    
                    // Effect indicator
                    if let effect = skin.colorScheme.effect {
                        effectOverlay(effect)
                    }
                    
                    // Equipped badge
                    if isEquipped {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .background(Circle().fill(.white).padding(2))
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                    
                    // Lock overlay if not owned
                    if !isOwned {
                        Color.black.opacity(0.5)
                        Image(systemName: "lock.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Skin info
                VStack(spacing: 4) {
                    Text(skin.name)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // Rarity
                    Text(skin.rarity.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(skin.rarity.color)
                    
                    // Price or status
                    if isOwned {
                        Text(isEquipped ? "EQUIPPED" : "OWNED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(isEquipped ? .green : .gray)
                    } else if let requirement = skin.unlockRequirement {
                        Text("🔒 \(requirement.description)")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .lineLimit(1)
                    } else {
                        priceLabel
                    }
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(skin.rarity.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var priceLabel: some View {
        HStack(spacing: 4) {
            if skin.price.coins > 0 {
                Text("🪙\(skin.price.coins)")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
            if skin.price.feathers > 0 {
                Text("🪶\(skin.price.feathers)")
                    .font(.caption)
                    .foregroundColor(.cyan)
            }
        }
    }
    
    @ViewBuilder
    private func effectOverlay(_ effect: SkinColorScheme.SkinEffect) -> some View {
        switch effect {
        case .sparkle:
            Image(systemName: "sparkles")
                .foregroundColor(.yellow.opacity(0.5))
                .font(.title)
        case .fire:
            Image(systemName: "flame.fill")
                .foregroundColor(.orange.opacity(0.5))
                .font(.title)
        case .ice:
            Image(systemName: "snowflake")
                .foregroundColor(.cyan.opacity(0.5))
                .font(.title)
        case .electric:
            Image(systemName: "bolt.fill")
                .foregroundColor(.yellow.opacity(0.5))
                .font(.title)
        case .shadow:
            Image(systemName: "moon.fill")
                .foregroundColor(.purple.opacity(0.5))
                .font(.title)
        case .glow:
            EmptyView()
        case .rainbow:
            Image(systemName: "rainbow")
                .foregroundColor(.white.opacity(0.5))
                .font(.title)
        }
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
