//
//  LobbyView.swift
//  BirdGame3
//
//  Fortnite-style party lobby with squad management
//

import SwiftUI

struct LobbyView: View {
    @EnvironmentObject var gameState: GameState
    @ObservedObject var multiplayer = MultiplayerManager.shared
    @ObservedObject var voiceChat = LiveVoiceChatManager.shared
    @ObservedObject var account = AccountManager.shared
    @ObservedObject var itemShop = ItemShopManager.shared
    
    @State private var showInviteSheet = false
    @State private var showGameModeSelector = false
    @State private var showItemShop = false
    @State private var showFriendsList = false
    @State private var joinPartyCode = ""
    @State private var showJoinParty = false
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            VStack(spacing: 0) {
                // Top bar
                topBar
                
                // Main content
                HStack(spacing: 0) {
                    // Left side - Party members
                    partyMembersSection
                    
                    Spacer()
                    
                    // Right side - Game mode & Play button
                    gameModeSection
                }
                .padding()
                
                Spacer()
                
                // Bottom bar - Voice chat & quick actions
                bottomBar
            }
            
            // Voice chat overlay
            VoiceChatOverlay()
        }
        .onAppear {
            if multiplayer.currentParty == nil {
                multiplayer.createParty()
            }
            if voiceChat.settings.autoJoinPartyVoice && !voiceChat.isConnected {
                voiceChat.joinPartyVoice()
            }
        }
        .sheet(isPresented: $showInviteSheet) {
            InvitePlayersSheet()
        }
        .sheet(isPresented: $showGameModeSelector) {
            GameModeSelectorSheet(selectedMode: Binding(
                get: { multiplayer.currentParty?.gameMode ?? .squadBattle },
                set: { multiplayer.setGameMode($0) }
            ))
        }
        .sheet(isPresented: $showItemShop) {
            ItemShopView()
        }
        .sheet(isPresented: $showFriendsList) {
            FriendsListSheet()
        }
        .alert("Join Party", isPresented: $showJoinParty) {
            TextField("Party Code", text: $joinPartyCode)
                .textInputAutocapitalization(.characters)
            Button("Cancel", role: .cancel) { }
            Button("Join") {
                multiplayer.joinParty(code: joinPartyCode) { success, error in
                    if !success {
                        // Show error
                    }
                }
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.1, blue: 0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Animated particles (birds flying in background)
            ForEach(0..<8) { i in
                Text(["🐦", "🦅", "🕊️", "🦆"][i % 4])
                    .font(.system(size: CGFloat.random(in: 20...40)))
                    .opacity(0.2)
                    .offset(
                        x: CGFloat.random(in: -200...200),
                        y: CGFloat.random(in: -300...300)
                    )
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            // Back button
            Button(action: { gameState.navigateTo(.mainMenu) }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Party code
            if let party = multiplayer.currentParty {
                VStack(spacing: 2) {
                    Text("PARTY CODE")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 4) {
                        Text(party.partyCode)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Button(action: copyPartyCode) {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
            
            Spacer()
            
            // Online count
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("\(multiplayer.fakeOnlineCount.formatted()) online")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.3))
            .cornerRadius(20)
        }
        .padding()
    }
    
    // MARK: - Party Members Section
    
    private var partyMembersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("🦅 SQUAD")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(multiplayer.currentParty?.memberCount ?? 0)/4")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Party members grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<4) { index in
                    if let party = multiplayer.currentParty,
                       index < party.members.count {
                        PartyMemberCard(member: party.members[index])
                    } else {
                        EmptyPartySlot(action: { showInviteSheet = true })
                    }
                }
            }
            
            // Invite buttons
            HStack(spacing: 12) {
                Button(action: { showInviteSheet = true }) {
                    Label("Invite", systemImage: "person.badge.plus")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(8)
                }
                
                Button(action: { showJoinParty = true }) {
                    Label("Join", systemImage: "arrow.right.circle")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.3))
                        .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: 350)
    }
    
    // MARK: - Game Mode Section
    
    private var gameModeSection: some View {
        VStack(spacing: 20) {
            // Selected character display
            if let party = multiplayer.currentParty,
               let localMember = party.members.first(where: { $0.isLocalPlayer }) {
                VStack(spacing: 8) {
                    Text(localMember.birdType.emoji)
                        .font(.system(size: 100))
                    
                    Text(localMember.birdType.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Button(action: { gameState.navigateTo(.characterSelect) }) {
                        Text("Change Character")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Game mode selector
            Button(action: { showGameModeSelector = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(multiplayer.currentParty?.gameMode.emoji ?? "⚔️")
                            .font(.title)
                        Text(multiplayer.currentParty?.gameMode.displayName ?? "Squad Battle")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(multiplayer.currentParty?.gameMode.description ?? "")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
            .frame(maxWidth: 280)
            
            // Play button
            playButton
        }
    }
    
    // MARK: - Play Button
    
    private var playButton: some View {
        Button(action: startMatchmaking) {
            HStack(spacing: 12) {
                if case .searching = multiplayer.matchmakingState {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if case .found(let countdown) = multiplayer.matchmakingState {
                    Text("\(countdown)")
                        .font(.title)
                        .fontWeight(.bold)
                } else {
                    Image(systemName: "play.fill")
                        .font(.title2)
                }
                
                Text(playButtonText)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(width: 250, height: 60)
            .background(playButtonGradient)
            .cornerRadius(16)
            .shadow(color: playButtonShadowColor.opacity(0.5), radius: 10)
        }
        .disabled(!canStartMatchmaking)
    }
    
    private var playButtonText: String {
        switch multiplayer.matchmakingState {
        case .idle:
            return "PLAY"
        case .searching(let found, let max):
            return "Searching... \(found)/\(max)"
        case .found:
            return "MATCH FOUND!"
        case .joining:
            return "JOINING..."
        case .failed(let error):
            return error
        }
    }
    
    private var playButtonGradient: LinearGradient {
        switch multiplayer.matchmakingState {
        case .found:
            return LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing)
        case .searching:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
        default:
            return LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    private var playButtonShadowColor: Color {
        switch multiplayer.matchmakingState {
        case .found: return .green
        case .searching: return .orange
        default: return .purple
        }
    }
    
    private var canStartMatchmaking: Bool {
        guard multiplayer.matchmakingState == .idle else { return false }
        return true
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBar: some View {
        HStack {
            // Voice chat controls
            VoiceChatControlsView()
            
            Spacer()
            
            // Quick action buttons
            HStack(spacing: 16) {
                QuickActionButton(icon: "cart.fill", label: "Shop") {
                    showItemShop = true
                }
                
                QuickActionButton(icon: "person.2.fill", label: "Friends") {
                    showFriendsList = true
                }
                
                QuickActionButton(icon: "gearshape.fill", label: "Settings") {
                    gameState.navigateTo(.settings)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Actions
    
    private func copyPartyCode() {
        guard let code = multiplayer.currentParty?.partyCode else { return }
        UIPasteboard.general.string = code
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func startMatchmaking() {
        if case .searching = multiplayer.matchmakingState {
            multiplayer.cancelMatchmaking()
        } else {
            multiplayer.startMatchmaking()
        }
    }
}

// MARK: - Party Member Card

struct PartyMemberCard: View {
    let member: PartyMember
    @ObservedObject var voiceChat = LiveVoiceChatManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Text(member.birdType.emoji)
                    .font(.system(size: 40))
                
                // Leader crown
                if member.isLeader {
                    Text("👑")
                        .font(.title3)
                        .offset(y: -40)
                }
                
                // Speaking indicator
                if isSpeaking {
                    Circle()
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 85, height: 85)
                }
                
                // Ready indicator
                if member.isReady && !member.isLeader {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .background(Circle().fill(.white).padding(2))
                        .offset(x: 30, y: 30)
                }
            }
            
            // Name
            Text(member.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Level
            Text(levelDisplay)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(member.isLocalPlayer ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
    
    private var isSpeaking: Bool {
        voiceChat.speakingParticipants.contains(member.id)
    }
    
    private var levelDisplay: String {
        if member.prestigeLevel > 0 {
            return "⭐\(member.prestigeLevel) Lv.\(member.level)"
        }
        return "Lv.\(member.level)"
    }
}

// MARK: - Empty Party Slot

struct EmptyPartySlot: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                        .foregroundColor(.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "plus")
                        .font(.title)
                        .foregroundColor(.gray.opacity(0.5))
                }
                
                Text("Invite")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.02))
            .cornerRadius(16)
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(.white)
            .frame(width: 60)
        }
    }
}

// MARK: - Invite Players Sheet

struct InvitePlayersSheet: View {
    @ObservedObject var account = AccountManager.shared
    @ObservedObject var multiplayer = MultiplayerManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Online friends section
                Section("Online Friends") {
                    ForEach(account.friends.filter { $0.isOnline }) { friend in
                        FriendInviteRow(friend: friend) {
                            // Invite friend
                            let member = PartyMember(
                                id: friend.id,
                                displayName: friend.displayName,
                                birdType: .pigeon,
                                skinId: "pigeon_default",
                                isReady: false,
                                isLeader: false,
                                level: 1,
                                prestigeLevel: 0
                            )
                            multiplayer.invitePlayer(member)
                        }
                    }
                }
                
                // Recent players section
                Section("Recent Players") {
                    ForEach(multiplayer.recentPlayers) { player in
                        FriendInviteRow(friend: Friend(
                            id: player.id,
                            username: player.displayName.lowercased(),
                            displayName: player.displayName,
                            avatarURL: nil,
                            isOnline: true,
                            lastSeen: nil,
                            currentActivity: nil,
                            friendshipDate: Date()
                        )) {
                            multiplayer.invitePlayer(player)
                        }
                    }
                }
            }
            .navigationTitle("Invite Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct FriendInviteRow: View {
    let friend: Friend
    let onInvite: () -> Void
    
    var body: some View {
        HStack {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text("🐦")
                )
            
            VStack(alignment: .leading) {
                Text(friend.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let activity = friend.currentActivity {
                    Text(activity)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Button("Invite") {
                onInvite()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }
}

// MARK: - Game Mode Selector Sheet

struct GameModeSelectorSheet: View {
    @Binding var selectedMode: MultiplayerGameMode
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(MultiplayerGameMode.allCases) { mode in
                    Button(action: {
                        selectedMode = mode
                        dismiss()
                    }) {
                        HStack {
                            Text(mode.emoji)
                                .font(.title)
                            
                            VStack(alignment: .leading) {
                                Text(mode.displayName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            if selectedMode == mode {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Select Game Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Friends List Sheet

struct FriendsListSheet: View {
    @ObservedObject var account = AccountManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Friend requests
                if !account.pendingRequests.isEmpty {
                    Section("Friend Requests (\(account.pendingRequests.count))") {
                        ForEach(account.pendingRequests) { request in
                            FriendRequestRow(request: request)
                        }
                    }
                }
                
                // Online friends
                Section("Online (\(account.friends.filter { $0.isOnline }.count))") {
                    ForEach(account.friends.filter { $0.isOnline }) { friend in
                        FriendRow(friend: friend)
                    }
                }
                
                // Offline friends
                Section("Offline") {
                    ForEach(account.friends.filter { !$0.isOnline }) { friend in
                        FriendRow(friend: friend)
                    }
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct FriendRequestRow: View {
    let request: FriendRequest
    @ObservedObject var account = AccountManager.shared
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.orange.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(Text("🐦"))
            
            VStack(alignment: .leading) {
                Text(request.fromDisplayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let message = request.message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: { account.acceptFriendRequest(request) }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
                
                Button(action: { account.declineFriendRequest(request) }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                }
            }
        }
    }
}

struct FriendRow: View {
    let friend: Friend
    
    var body: some View {
        HStack {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(Text("🐦"))
                
                Circle()
                    .fill(friend.isOnline ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
            
            VStack(alignment: .leading) {
                Text(friend.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if friend.isOnline, let activity = friend.currentActivity {
                    Text(activity)
                        .font(.caption)
                        .foregroundColor(.green)
                } else if let lastSeen = friend.lastSeen {
                    Text("Last seen \(lastSeen.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    LobbyView()
        .environmentObject(GameState())
}
