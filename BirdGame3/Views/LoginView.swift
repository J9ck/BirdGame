//
//  LoginView.swift
//  BirdGame3
//
//  User authentication and account management
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @ObservedObject var account = AccountManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.15, green: 0.1, blue: 0.25)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo
                        VStack(spacing: 8) {
                            Text("🐦")
                                .font(.system(size: 80))
                            
                            Text("BIRD GAME 3")
                                .font(.title)
                                .fontWeight(.heavy)
                                .foregroundColor(.white)
                            
                            Text(showSignUp ? "Create Account" : "Welcome Back")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 40)
                        
                        // Form
                        VStack(spacing: 16) {
                            if showSignUp {
                                // Username field
                                CustomTextField(
                                    placeholder: "Username",
                                    text: $username,
                                    icon: "person.fill"
                                )
                            }
                            
                            // Email field
                            CustomTextField(
                                placeholder: "Email",
                                text: $email,
                                icon: "envelope.fill",
                                keyboardType: .emailAddress
                            )
                            
                            // Password field
                            CustomSecureField(
                                placeholder: "Password",
                                text: $password,
                                icon: "lock.fill"
                            )
                            
                            if showSignUp {
                                // Confirm password
                                CustomSecureField(
                                    placeholder: "Confirm Password",
                                    text: $confirmPassword,
                                    icon: "lock.fill"
                                )
                            }
                            
                            // Error message
                            if let error = account.authError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                            }
                            
                            // Submit button
                            Button(action: submitForm) {
                                HStack {
                                    if account.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text(showSignUp ? "Create Account" : "Sign In")
                                            .fontWeight(.bold)
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                            .disabled(account.isLoading)
                        }
                        .padding(.horizontal)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("OR")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal)
                        
                        // Social sign in
                        VStack(spacing: 12) {
                            // Sign in with Apple
                            SignInWithAppleButton(
                                .signIn,
                                onRequest: { request in
                                    request.requestedScopes = [.fullName, .email]
                                },
                                onCompletion: { result in
                                    switch result {
                                    case .success(let authResults):
                                        if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                                            account.signInWithApple(credential: appleIDCredential)
                                        }
                                    case .failure(let error):
                                        account.authError = error.localizedDescription
                                    }
                                }
                            )
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 50)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Guest sign in
                            Button(action: { account.signInAsGuest() }) {
                                HStack {
                                    Image(systemName: "person.fill.questionmark")
                                    Text("Continue as Guest")
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Toggle sign up / sign in
                        Button(action: { showSignUp.toggle() }) {
                            Text(showSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EmptyView()
                }
            }
        }
        .onChange(of: account.isLoggedIn) { isLoggedIn in
            if isLoggedIn {
                dismiss()
            }
        }
    }
    
    private func submitForm() {
        if showSignUp {
            guard password == confirmPassword else {
                account.authError = "Passwords don't match"
                return
            }
            account.signUp(email: email, password: password, username: username)
        } else {
            account.signInWithEmail(email: email, password: password)
        }
    }
}

// MARK: - Custom Text Field

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CustomSecureField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            if isVisible {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            } else {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
            }
            
            Button(action: { isVisible.toggle() }) {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Account Profile View

struct AccountProfileView: View {
    @ObservedObject var account = AccountManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showEditProfile = false
    @State private var showDeleteConfirmation = false
    @State private var deleteConfirmationText = ""
    @State private var showPrivacySettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.1)
                    .ignoresSafeArea()
                
                if let user = account.currentAccount {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Profile header
                            profileHeader(user: user)
                            
                            // Stats
                            statsSection(user: user)
                            
                            // Account info
                            accountInfoSection(user: user)
                            
                            // Actions
                            actionsSection
                        }
                        .padding()
                    }
                } else {
                    Text("Not logged in")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showPrivacySettings) {
            PrivacySettingsView()
        }
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            TextField("Type DELETE to confirm", text: $deleteConfirmationText)
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                account.deleteAccount(confirmation: deleteConfirmationText) { _, _ in }
            }
        } message: {
            Text("This action cannot be undone. All your progress, purchases, and data will be permanently deleted.")
        }
    }
    
    private func profileHeader(user: UserAccount) -> some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Text("🐦")
                    .font(.system(size: 50))
                
                // Premium badge
                if user.isPremium {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .offset(x: 35, y: -35)
                }
            }
            
            // Name
            VStack(spacing: 4) {
                Text(user.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Friend code
            HStack {
                Text("Friend Code:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(user.friendCode)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Button(action: {
                    UIPasteboard.general.string = user.friendCode
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(20)
        }
    }
    
    private func statsSection(user: UserAccount) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stats")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                StatCard(title: "Wins", value: "\(user.totalWins)", color: .green)
                StatCard(title: "Matches", value: "\(user.totalMatches)", color: .blue)
                StatCard(title: "Win Rate", value: String(format: "%.1f%%", user.winRate), color: .purple)
            }
            
            HStack(spacing: 20) {
                StatCard(title: "Rank", value: user.seasonRank, color: .yellow)
                StatCard(title: "Friends", value: "\(user.friendCount)", color: .cyan)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private func accountInfoSection(user: UserAccount) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account Info")
                .font(.headline)
                .foregroundColor(.white)
            
            InfoRow(label: "Email", value: user.email ?? "Not set")
            InfoRow(label: "Auth Provider", value: user.authProvider.displayName)
            InfoRow(label: "Member Since", value: user.createdAt.formatted(date: .abbreviated, time: .omitted))
            InfoRow(label: "Verified", value: user.isVerified ? "Yes ✓" : "No")
            
            if user.isPremium, let expires = user.premiumExpiresAt {
                InfoRow(label: "Premium Until", value: expires.formatted(date: .abbreviated, time: .omitted))
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Edit profile
            Button(action: { showEditProfile = true }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Profile")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue.opacity(0.3))
                .cornerRadius(12)
            }
            
            // Privacy settings
            Button(action: { showPrivacySettings = true }) {
                HStack {
                    Image(systemName: "hand.raised.fill")
                    Text("Privacy Settings")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.purple.opacity(0.3))
                .cornerRadius(12)
            }
            
            // Cloud sync
            Button(action: { account.saveToCloud() }) {
                HStack {
                    Image(systemName: "icloud.and.arrow.up")
                    Text("Sync to Cloud")
                    Spacer()
                    if account.isSyncing {
                        ProgressView()
                    } else if let lastSync = account.lastCloudSave {
                        Text(lastSync.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.cyan.opacity(0.3))
                .cornerRadius(12)
            }
            
            // Sign out
            Button(action: { account.signOut() }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .foregroundColor(.orange)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(12)
            }
            
            // Delete account
            Button(action: { showDeleteConfirmation = true }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete Account")
                }
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.2))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
        }
        .font(.subheadline)
    }
}

struct EditProfileView: View {
    @ObservedObject var account = AccountManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var displayName = ""
    @State private var username = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Display Name") {
                    TextField("Display Name", text: $displayName)
                }
                
                Section("Username") {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        _ = account.updateDisplayName(displayName)
                        account.updateUsername(username) { _, _ in }
                        dismiss()
                    }
                }
            }
            .onAppear {
                displayName = account.currentAccount?.displayName ?? ""
                username = account.currentAccount?.username ?? ""
            }
        }
    }
}

struct PrivacySettingsView: View {
    @ObservedObject var account = AccountManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var settings = PrivacySettings()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Visibility") {
                    Toggle("Show Online Status", isOn: $settings.showOnlineStatus)
                    Toggle("Show in Leaderboards", isOn: $settings.showInLeaderboards)
                    Toggle("Share Game Activity", isOn: $settings.shareGameActivity)
                }
                
                Section("Social") {
                    Toggle("Allow Friend Requests", isOn: $settings.allowFriendRequests)
                    Toggle("Allow Direct Messages", isOn: $settings.allowDirectMessages)
                    
                    Picker("Party Invites", selection: $settings.allowPartyInvites) {
                        Text("Anyone").tag(PartyInviteSetting.anyone)
                        Text("Friends Only").tag(PartyInviteSetting.friendsOnly)
                        Text("Nobody").tag(PartyInviteSetting.nobody)
                    }
                }
                
                Section("Voice Chat") {
                    Toggle("Allow Voice Chat", isOn: $settings.allowVoiceChat)
                }
            }
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        account.updatePrivacySettings(settings)
                        dismiss()
                    }
                }
            }
            .onAppear {
                settings = account.currentAccount?.privacySettings ?? PrivacySettings()
            }
        }
    }
}

#Preview {
    LoginView()
}

