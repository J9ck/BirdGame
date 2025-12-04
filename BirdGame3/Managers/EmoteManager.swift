//
//  EmoteManager.swift
//  BirdGame3
//
//  Emotes and taunts system for player expression
//

import Foundation
import SwiftUI

// MARK: - Emote

struct Emote: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let icon: String
    let animation: EmoteAnimation
    let category: EmoteCategory
    let rarity: EmoteRarity
    var isUnlocked: Bool
    let price: Int // In feathers, 0 if not purchasable
    
    static func == (lhs: Emote, rhs: Emote) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Emote Animation

enum EmoteAnimation: String, Codable {
    case wave
    case laugh
    case dance
    case flex
    case cry
    case taunt
    case bow
    case spin
    case fly
    case victory
    case angry
    case confused
    case love
    case sleep
    case eat
    
    var duration: TimeInterval {
        switch self {
        case .wave, .bow: return 1.5
        case .laugh, .cry, .angry: return 2.0
        case .dance, .spin: return 3.0
        case .flex, .victory: return 2.5
        case .taunt, .confused: return 2.0
        case .fly: return 3.5
        case .love, .sleep, .eat: return 2.0
        }
    }
}

// MARK: - Emote Category

enum EmoteCategory: String, Codable, CaseIterable {
    case greeting
    case celebration
    case taunt
    case reaction
    case special
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .greeting: return "👋"
        case .celebration: return "🎉"
        case .taunt: return "😏"
        case .reaction: return "😮"
        case .special: return "⭐"
        }
    }
}

// MARK: - Emote Rarity

enum EmoteRarity: String, Codable, CaseIterable {
    case common
    case rare
    case epic
    case legendary
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    var priceMultiplier: Int {
        switch self {
        case .common: return 1
        case .rare: return 2
        case .epic: return 4
        case .legendary: return 8
        }
    }
}

// MARK: - Emote Wheel Slot

struct EmoteWheelSlot: Identifiable, Codable {
    let id: Int
    var emoteId: String?
}

// MARK: - Emote Manager

class EmoteManager: ObservableObject {
    static let shared = EmoteManager()
    
    // MARK: - Published Properties
    
    @Published var emotes: [Emote] = []
    @Published var emoteWheel: [EmoteWheelSlot] = []
    @Published var currentlyPlaying: Emote?
    @Published var recentlyUsed: [String] = []
    
    // MARK: - Private Properties
    
    private let saveKey = "birdgame3_emotes"
    private let wheelSaveKey = "birdgame3_emoteWheel"
    private let maxRecentEmotes = 6
    private let wheelSlotCount = 8
    
    // MARK: - Initialization
    
    private init() {
        loadEmotes()
        loadEmoteWheel()
    }
    
    // MARK: - Emote Unlocking
    
    func unlockEmote(_ emoteId: String) {
        guard let index = emotes.firstIndex(where: { $0.id == emoteId && !$0.isUnlocked }) else { return }
        
        emotes[index].isUnlocked = true
        saveEmotes()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func purchaseEmote(_ emote: Emote) -> Bool {
        guard !emote.isUnlocked && emote.price > 0 else { return false }
        
        if CurrencyManager.shared.spendFeathers(emote.price, reason: "Emote: \(emote.name)") {
            unlockEmote(emote.id)
            return true
        }
        
        return false
    }
    
    // MARK: - Emote Wheel Management
    
    func assignToWheel(emoteId: String, slot: Int) {
        guard slot >= 0 && slot < wheelSlotCount else { return }
        guard let emote = emotes.first(where: { $0.id == emoteId && $0.isUnlocked }) else { return }
        
        // Remove from any existing slot
        for i in emoteWheel.indices {
            if emoteWheel[i].emoteId == emoteId {
                emoteWheel[i].emoteId = nil
            }
        }
        
        // Assign to new slot
        emoteWheel[slot].emoteId = emoteId
        saveEmoteWheel()
    }
    
    func removeFromWheel(slot: Int) {
        guard slot >= 0 && slot < wheelSlotCount else { return }
        emoteWheel[slot].emoteId = nil
        saveEmoteWheel()
    }
    
    func getEmoteForSlot(_ slot: Int) -> Emote? {
        guard slot >= 0 && slot < wheelSlotCount,
              let emoteId = emoteWheel[slot].emoteId else { return nil }
        return emotes.first { $0.id == emoteId }
    }
    
    // MARK: - Playing Emotes
    
    func playEmote(_ emote: Emote) {
        guard emote.isUnlocked else { return }
        guard currentlyPlaying == nil else { return } // Already playing
        
        currentlyPlaying = emote
        
        // Add to recently used
        recentlyUsed.removeAll { $0 == emote.id }
        recentlyUsed.insert(emote.id, at: 0)
        if recentlyUsed.count > maxRecentEmotes {
            recentlyUsed.removeLast()
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Clear after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + emote.animation.duration) { [weak self] in
            self?.currentlyPlaying = nil
        }
        
        // Post notification for game scene
        NotificationCenter.default.post(
            name: .emoteTriggered,
            object: nil,
            userInfo: ["emote": emote]
        )
    }
    
    func playEmoteFromWheel(slot: Int) {
        guard let emote = getEmoteForSlot(slot) else { return }
        playEmote(emote)
    }
    
    // MARK: - Queries
    
    var unlockedEmotes: [Emote] {
        emotes.filter { $0.isUnlocked }
    }
    
    func emotes(for category: EmoteCategory) -> [Emote] {
        emotes.filter { $0.category == category }
    }
    
    func unlockedEmotes(for category: EmoteCategory) -> [Emote] {
        emotes.filter { $0.category == category && $0.isUnlocked }
    }
    
    var recentEmotes: [Emote] {
        recentlyUsed.compactMap { id in
            emotes.first { $0.id == id && $0.isUnlocked }
        }
    }
    
    // MARK: - Persistence
    
    private func saveEmotes() {
        if let data = try? JSONEncoder().encode(emotes) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
    
    private func loadEmotes() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let saved = try? JSONDecoder().decode([Emote].self, from: data) {
            emotes = saved
        } else {
            emotes = createDefaultEmotes()
            saveEmotes()
        }
    }
    
    private func saveEmoteWheel() {
        if let data = try? JSONEncoder().encode(emoteWheel) {
            UserDefaults.standard.set(data, forKey: wheelSaveKey)
        }
    }
    
    private func loadEmoteWheel() {
        if let data = UserDefaults.standard.data(forKey: wheelSaveKey),
           let saved = try? JSONDecoder().decode([EmoteWheelSlot].self, from: data) {
            emoteWheel = saved
        } else {
            // Initialize empty wheel
            emoteWheel = (0..<wheelSlotCount).map { EmoteWheelSlot(id: $0, emoteId: nil) }
            
            // Pre-assign default emotes
            if let wave = emotes.first(where: { $0.id == "emote_wave" }) {
                emoteWheel[0].emoteId = wave.id
            }
            saveEmoteWheel()
        }
    }
    
    // MARK: - Default Emotes
    
    private func createDefaultEmotes() -> [Emote] {
        return [
            // Greetings (some free)
            Emote(id: "emote_wave", name: "Wave", icon: "👋", animation: .wave, category: .greeting, rarity: .common, isUnlocked: true, price: 0),
            Emote(id: "emote_bow", name: "Bow", icon: "🙇", animation: .bow, category: .greeting, rarity: .common, isUnlocked: false, price: 50),
            
            // Celebrations
            Emote(id: "emote_dance", name: "Dance", icon: "💃", animation: .dance, category: .celebration, rarity: .rare, isUnlocked: false, price: 100),
            Emote(id: "emote_victory", name: "Victory", icon: "✌️", animation: .victory, category: .celebration, rarity: .rare, isUnlocked: false, price: 100),
            Emote(id: "emote_flex", name: "Flex", icon: "💪", animation: .flex, category: .celebration, rarity: .epic, isUnlocked: false, price: 200),
            
            // Taunts
            Emote(id: "emote_laugh", name: "Laugh", icon: "😂", animation: .laugh, category: .taunt, rarity: .common, isUnlocked: true, price: 0),
            Emote(id: "emote_taunt", name: "Taunt", icon: "😏", animation: .taunt, category: .taunt, rarity: .rare, isUnlocked: false, price: 150),
            Emote(id: "emote_spin", name: "Spin", icon: "🌀", animation: .spin, category: .taunt, rarity: .epic, isUnlocked: false, price: 200),
            
            // Reactions
            Emote(id: "emote_cry", name: "Cry", icon: "😢", animation: .cry, category: .reaction, rarity: .common, isUnlocked: false, price: 50),
            Emote(id: "emote_angry", name: "Angry", icon: "😠", animation: .angry, category: .reaction, rarity: .common, isUnlocked: false, price: 50),
            Emote(id: "emote_confused", name: "Confused", icon: "😕", animation: .confused, category: .reaction, rarity: .common, isUnlocked: false, price: 50),
            Emote(id: "emote_love", name: "Love", icon: "😍", animation: .love, category: .reaction, rarity: .rare, isUnlocked: false, price: 100),
            
            // Special
            Emote(id: "emote_fly", name: "Fly Away", icon: "🦅", animation: .fly, category: .special, rarity: .epic, isUnlocked: false, price: 300),
            Emote(id: "emote_sleep", name: "Sleep", icon: "😴", animation: .sleep, category: .special, rarity: .rare, isUnlocked: false, price: 100),
            Emote(id: "emote_eat", name: "Nom Nom", icon: "🍖", animation: .eat, category: .special, rarity: .rare, isUnlocked: false, price: 100),
            
            // Legendary (Battle Pass or special events)
            Emote(id: "emote_phoenix", name: "Phoenix Rise", icon: "🔥", animation: .fly, category: .special, rarity: .legendary, isUnlocked: false, price: 0), // Not purchasable
            Emote(id: "emote_champion", name: "Champion", icon: "🏆", animation: .victory, category: .celebration, rarity: .legendary, isUnlocked: false, price: 0),
        ]
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let emoteTriggered = Notification.Name("birdgame3_emoteTriggered")
}
