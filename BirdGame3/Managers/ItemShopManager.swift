//
//  ItemShopManager.swift
//  BirdGame3
//
//  Fortnite-style rotating item shop with daily/weekly items
//

import Foundation
import SwiftUI

// MARK: - Shop Item

struct ShopItem: Identifiable, Codable {
    let id: String
    let type: ShopItemType
    let name: String
    let description: String
    let rarity: SkinRarity
    let price: ShopPrice
    let previewImage: String // SF Symbol or emoji
    let featuredUntil: Date?
    let isNew: Bool
    let discountPercent: Int?
    
    var originalPrice: Int? {
        guard let discount = discountPercent else { return nil }
        return Int(Double(price.amount) / (1.0 - Double(discount) / 100.0))
    }
    
    var isFeatured: Bool {
        featuredUntil != nil && featuredUntil! > Date()
    }
}

// MARK: - Shop Item Type

enum ShopItemType: String, Codable {
    case skin
    case emote
    case trail
    case nestDecor
    case banner
    case title
    case bundle
    
    var displayName: String {
        switch self {
        case .skin: return "Skin"
        case .emote: return "Emote"
        case .trail: return "Flight Trail"
        case .nestDecor: return "Nest Decoration"
        case .banner: return "Banner"
        case .title: return "Title"
        case .bundle: return "Bundle"
        }
    }
    
    var emoji: String {
        switch self {
        case .skin: return "🎨"
        case .emote: return "💃"
        case .trail: return "✨"
        case .nestDecor: return "🪺"
        case .banner: return "🚩"
        case .title: return "📛"
        case .bundle: return "📦"
        }
    }
}

// MARK: - Shop Price

struct ShopPrice: Codable {
    let amount: Int
    let currency: ShopCurrency
    
    var displayString: String {
        switch currency {
        case .coins: return "🪙 \(amount)"
        case .feathers: return "🪶 \(amount)"
        case .realMoney: return "$\(String(format: "%.2f", Double(amount) / 100.0))"
        }
    }
}

enum ShopCurrency: String, Codable {
    case coins
    case feathers
    case realMoney
}

// MARK: - Shop Section

struct ShopSection: Identifiable {
    let id: String
    let title: String
    let items: [ShopItem]
    let refreshTime: Date?
    let sectionType: ShopSectionType
}

enum ShopSectionType {
    case featured
    case daily
    case weekly
    case special
    case bundles
}

// MARK: - Item Shop Manager

class ItemShopManager: ObservableObject {
    static let shared = ItemShopManager()
    
    // MARK: - Published Properties
    
    @Published var featuredItems: [ShopItem] = []
    @Published var dailyItems: [ShopItem] = []
    @Published var weeklyItems: [ShopItem] = []
    @Published var specialItems: [ShopItem] = []
    @Published var bundles: [ShopItem] = []
    @Published var purchasedItems: Set<String> = []
    
    @Published var dailyRefreshTime: Date = Date()
    @Published var weeklyRefreshTime: Date = Date()
    
    // MARK: - Persistence Keys
    
    private let purchasedKey = "birdgame3_shopPurchased"
    private let lastRefreshKey = "birdgame3_shopLastRefresh"
    
    // MARK: - Initialization
    
    private init() {
        loadPurchasedItems()
        refreshShop()
        scheduleAutoRefresh()
    }
    
    // MARK: - Shop Sections
    
    var allSections: [ShopSection] {
        [
            ShopSection(id: "featured", title: "🔥 FEATURED", items: featuredItems, refreshTime: weeklyRefreshTime, sectionType: .featured),
            ShopSection(id: "daily", title: "📅 DAILY ITEMS", items: dailyItems, refreshTime: dailyRefreshTime, sectionType: .daily),
            ShopSection(id: "bundles", title: "📦 BUNDLES", items: bundles, refreshTime: nil, sectionType: .bundles),
            ShopSection(id: "special", title: "⭐ SPECIAL OFFERS", items: specialItems, refreshTime: nil, sectionType: .special),
        ]
    }
    
    // MARK: - Shop Refresh
    
    func refreshShop() {
        // Set refresh times
        dailyRefreshTime = nextDailyReset()
        weeklyRefreshTime = nextWeeklyReset()
        
        generateFeaturedItems()
        generateDailyItems()
        generateBundles()
        generateSpecialItems()
    }
    
    private func nextDailyReset() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 0
        components.minute = 0
        components.second = 0
        guard let today = calendar.date(from: components) else { return Date() }
        return calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
    }
    
    private func nextWeeklyReset() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = 1 // Sunday
        guard let thisWeek = calendar.date(from: components) else { return Date() }
        return calendar.date(byAdding: .weekOfYear, value: 1, to: thisWeek) ?? Date()
    }
    
    private func scheduleAutoRefresh() {
        // Check every hour if refresh is needed
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            if Date() > self?.dailyRefreshTime ?? Date() {
                self?.generateDailyItems()
                self?.dailyRefreshTime = self?.nextDailyReset() ?? Date()
            }
            if Date() > self?.weeklyRefreshTime ?? Date() {
                self?.generateFeaturedItems()
                self?.weeklyRefreshTime = self?.nextWeeklyReset() ?? Date()
            }
        }
    }
    
    // MARK: - Item Generation
    
    private func generateFeaturedItems() {
        featuredItems = [
            ShopItem(
                id: "featured_legendary_skin",
                type: .skin,
                name: "Phoenix Inferno",
                description: "Rise from the ashes with burning wings",
                rarity: .legendary,
                price: ShopPrice(amount: 2000, currency: .coins),
                previewImage: "🔥",
                featuredUntil: weeklyRefreshTime,
                isNew: true,
                discountPercent: nil
            ),
            ShopItem(
                id: "featured_mythic_trail",
                type: .trail,
                name: "Rainbow Contrail",
                description: "Leave a trail of pure awesomeness",
                rarity: .mythic,
                price: ShopPrice(amount: 50, currency: .feathers),
                previewImage: "🌈",
                featuredUntil: weeklyRefreshTime,
                isNew: true,
                discountPercent: nil
            ),
            ShopItem(
                id: "featured_epic_emote",
                type: .emote,
                name: "Victory Caw",
                description: "Assert dominance after every win",
                rarity: .epic,
                price: ShopPrice(amount: 800, currency: .coins),
                previewImage: "🗣️",
                featuredUntil: weeklyRefreshTime,
                isNew: false,
                discountPercent: 20
            ),
        ]
    }
    
    private func generateDailyItems() {
        let possibleItems: [ShopItem] = [
            ShopItem(id: "daily_skin_1", type: .skin, name: "Neon Pigeon", description: "Cyberpunk coo coo", rarity: .rare, price: ShopPrice(amount: 500, currency: .coins), previewImage: "🐦", featuredUntil: nil, isNew: false, discountPercent: nil),
            ShopItem(id: "daily_skin_2", type: .skin, name: "Golden Eagle", description: "Majestic and shiny", rarity: .epic, price: ShopPrice(amount: 1200, currency: .coins), previewImage: "🦅", featuredUntil: nil, isNew: false, discountPercent: nil),
            ShopItem(id: "daily_emote_1", type: .emote, name: "Wing Flap", description: "Flap excitedly", rarity: .common, price: ShopPrice(amount: 200, currency: .coins), previewImage: "👐", featuredUntil: nil, isNew: false, discountPercent: nil),
            ShopItem(id: "daily_trail_1", type: .trail, name: "Feather Storm", description: "Leave feathers everywhere", rarity: .rare, price: ShopPrice(amount: 400, currency: .coins), previewImage: "🪶", featuredUntil: nil, isNew: false, discountPercent: nil),
            ShopItem(id: "daily_nest_1", type: .nestDecor, name: "Cozy Blanket", description: "For your nest", rarity: .common, price: ShopPrice(amount: 150, currency: .coins), previewImage: "🛏️", featuredUntil: nil, isNew: false, discountPercent: nil),
            ShopItem(id: "daily_banner_1", type: .banner, name: "Bird Skull", description: "Intimidating banner", rarity: .rare, price: ShopPrice(amount: 300, currency: .coins), previewImage: "💀", featuredUntil: nil, isNew: false, discountPercent: nil),
            ShopItem(id: "daily_title_1", type: .title, name: "The Pecking Order", description: "Show your rank", rarity: .epic, price: ShopPrice(amount: 600, currency: .coins), previewImage: "👑", featuredUntil: nil, isNew: false, discountPercent: nil),
        ]
        
        // Select 4-6 random daily items
        dailyItems = Array(possibleItems.shuffled().prefix(Int.random(in: 4...6)))
    }
    
    private func generateBundles() {
        bundles = [
            ShopItem(
                id: "bundle_starter",
                type: .bundle,
                name: "Starter Pack",
                description: "Pigeon skin, emote, and 500 coins",
                rarity: .rare,
                price: ShopPrice(amount: 499, currency: .realMoney),
                previewImage: "📦",
                featuredUntil: nil,
                isNew: false,
                discountPercent: 40
            ),
            ShopItem(
                id: "bundle_legendary",
                type: .bundle,
                name: "Legendary Bundle",
                description: "3 legendary skins, emotes, trails",
                rarity: .legendary,
                price: ShopPrice(amount: 1999, currency: .realMoney),
                previewImage: "🎁",
                featuredUntil: nil,
                isNew: true,
                discountPercent: 50
            ),
            ShopItem(
                id: "bundle_feathers",
                type: .bundle,
                name: "Feather Frenzy",
                description: "100 Premium Feathers",
                rarity: .epic,
                price: ShopPrice(amount: 999, currency: .realMoney),
                previewImage: "🪶",
                featuredUntil: nil,
                isNew: false,
                discountPercent: nil
            ),
        ]
    }
    
    private func generateSpecialItems() {
        specialItems = [
            ShopItem(
                id: "special_battle_pass",
                type: .bundle,
                name: "Season Pass",
                description: "Unlock 100 tiers of rewards",
                rarity: .mythic,
                price: ShopPrice(amount: 950, currency: .coins),
                previewImage: "🎫",
                featuredUntil: nil,
                isNew: true,
                discountPercent: nil
            ),
        ]
    }
    
    // MARK: - Purchase
    
    func purchase(item: ShopItem) -> (success: Bool, message: String) {
        guard !purchasedItems.contains(item.id) else {
            return (false, "You already own this item!")
        }
        
        let currency = CurrencyManager.shared
        
        switch item.price.currency {
        case .coins:
            guard currency.spendCoins(item.price.amount) else {
                return (false, "Not enough coins!")
            }
        case .feathers:
            guard currency.spendFeathers(item.price.amount) else {
                return (false, "Not enough feathers!")
            }
        case .realMoney:
            // In a real app, this would trigger IAP
            return (false, "In-app purchases coming soon!")
        }
        
        // Mark as purchased
        purchasedItems.insert(item.id)
        savePurchasedItems()
        
        // If it's a skin, unlock it in SkinManager
        if item.type == .skin {
            SkinManager.shared.unlock(skinId: item.id)
        }
        
        return (true, "Purchase successful! 🎉")
    }
    
    func owns(itemId: String) -> Bool {
        purchasedItems.contains(itemId)
    }
    
    // MARK: - Persistence
    
    private func loadPurchasedItems() {
        if let data = UserDefaults.standard.data(forKey: purchasedKey),
           let items = try? JSONDecoder().decode(Set<String>.self, from: data) {
            purchasedItems = items
        }
    }
    
    private func savePurchasedItems() {
        if let data = try? JSONEncoder().encode(purchasedItems) {
            UserDefaults.standard.set(data, forKey: purchasedKey)
        }
    }
    
    // MARK: - Time Formatting
    
    func timeUntilRefresh(_ date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        guard interval > 0 else { return "Refreshing..." }
        
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
