//
//  ItemShopView.swift
//  BirdGame3
//
//  Fortnite-style rotating item shop
//

import SwiftUI

struct ItemShopView: View {
    @ObservedObject var itemShop = ItemShopManager.shared
    @ObservedObject var currency = CurrencyManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedItem: ShopItem?
    @State private var showPurchaseConfirmation = false
    @State private var purchaseResult: (success: Bool, message: String)?
    @State private var showPurchaseResult = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.05, blue: 0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Currency display
                        currencyHeader
                        
                        // Shop sections
                        ForEach(itemShop.allSections) { section in
                            ShopSectionView(
                                section: section,
                                onItemTap: { item in
                                    selectedItem = item
                                    showPurchaseConfirmation = true
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("🛒 ITEM SHOP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .confirmationDialog("Purchase Item", isPresented: $showPurchaseConfirmation, titleVisibility: .visible) {
            if let item = selectedItem {
                Button("Buy for \(item.price.displayString)") {
                    purchaseItem(item)
                }
                Button("Cancel", role: .cancel) { }
            }
        } message: {
            if let item = selectedItem {
                Text("Purchase \(item.name)?")
            }
        }
        .alert(
            purchaseResult?.success == true ? "Success!" : "Error",
            isPresented: $showPurchaseResult
        ) {
            Button("OK") { }
        } message: {
            Text(purchaseResult?.message ?? "")
        }
    }
    
    // MARK: - Currency Header
    
    private var currencyHeader: some View {
        HStack(spacing: 20) {
            // Coins
            HStack(spacing: 6) {
                Text("🪙")
                    .font(.title2)
                Text("\(currency.coins)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.yellow.opacity(0.15))
            .cornerRadius(20)
            
            // Feathers
            HStack(spacing: 6) {
                Text("🪶")
                    .font(.title2)
                Text("\(currency.feathers)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.cyan.opacity(0.15))
            .cornerRadius(20)
            
            Spacer()
            
            // Buy currency button
            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                    Text("Get More")
                }
                .font(.subheadline)
                .foregroundColor(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.15))
                .cornerRadius(20)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Actions
    
    private func purchaseItem(_ item: ShopItem) {
        purchaseResult = itemShop.purchase(item: item)
        showPurchaseResult = true
    }
}

// MARK: - Shop Section View

struct ShopSectionView: View {
    let section: ShopSection
    let onItemTap: (ShopItem) -> Void
    @ObservedObject var itemShop = ItemShopManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text(section.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Refresh timer
                if let refreshTime = section.refreshTime {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(itemShop.timeUntilRefresh(refreshTime))
                            .font(.caption)
                    }
                    .foregroundColor(.gray)
                }
            }
            
            // Items grid
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(section.items) { item in
                    ShopItemCard(item: item, onTap: { onItemTap(item) })
                }
            }
        }
    }
    
    private var gridColumns: [GridItem] {
        switch section.sectionType {
        case .featured:
            return [GridItem(.flexible()), GridItem(.flexible())]
        default:
            return [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        }
    }
}

// MARK: - Shop Item Card

struct ShopItemCard: View {
    let item: ShopItem
    let onTap: () -> Void
    @ObservedObject var itemShop = ItemShopManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Item preview
                ZStack {
                    // Rarity background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [item.rarity.color.opacity(0.3), item.rarity.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Item preview (emoji/icon)
                    Text(item.previewImage)
                        .font(.system(size: 50))
                    
                    // Badges
                    VStack {
                        HStack {
                            // New badge
                            if item.isNew {
                                Text("NEW")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .cornerRadius(4)
                            }
                            
                            Spacer()
                            
                            // Discount badge
                            if let discount = item.discountPercent {
                                Text("-\(discount)%")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(6)
                    
                    // Owned overlay
                    if itemShop.owns(itemId: item.id) {
                        Color.black.opacity(0.5)
                        
                        Text("OWNED")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Item info
                VStack(spacing: 4) {
                    // Name
                    Text(item.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // Type & rarity
                    HStack(spacing: 4) {
                        Text(item.type.emoji)
                            .font(.caption2)
                        Text(item.rarity.displayName)
                            .font(.caption2)
                            .foregroundColor(item.rarity.color)
                    }
                    
                    // Price
                    HStack(spacing: 4) {
                        if let originalPrice = item.originalPrice {
                            Text("\(originalPrice)")
                                .font(.caption2)
                                .strikethrough()
                                .foregroundColor(.gray)
                        }
                        
                        Text(item.price.displayString)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(priceColor)
                    }
                }
            }
            .padding(8)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(item.rarity.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(itemShop.owns(itemId: item.id))
    }
    
    private var priceColor: Color {
        switch item.price.currency {
        case .coins: return .yellow
        case .feathers: return .cyan
        case .realMoney: return .green
        }
    }
}

// MARK: - Preview

#Preview {
    ItemShopView()
}
