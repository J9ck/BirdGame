//
//  LegalManager.swift
//  BirdGame3
//
//  App Store compliance - Privacy Policy, Terms of Service, EULA
//

import Foundation
import SwiftUI

// MARK: - Legal Document Type

enum LegalDocumentType: String, CaseIterable {
    case privacyPolicy = "privacy_policy"
    case termsOfService = "terms_of_service"
    case eula = "eula"
    case communityGuidelines = "community_guidelines"
    
    var title: String {
        switch self {
        case .privacyPolicy: return "Privacy Policy"
        case .termsOfService: return "Terms of Service"
        case .eula: return "End User License Agreement"
        case .communityGuidelines: return "Community Guidelines"
        }
    }
    
    var icon: String {
        switch self {
        case .privacyPolicy: return "lock.shield"
        case .termsOfService: return "doc.text"
        case .eula: return "signature"
        case .communityGuidelines: return "person.3"
        }
    }
    
    var url: URL? {
        switch self {
        case .privacyPolicy:
            return URL(string: "https://birdgame3.com/privacy")
        case .termsOfService:
            return URL(string: "https://birdgame3.com/terms")
        case .eula:
            return URL(string: "https://birdgame3.com/eula")
        case .communityGuidelines:
            return URL(string: "https://birdgame3.com/guidelines")
        }
    }
}

// MARK: - Legal Manager

class LegalManager: ObservableObject {
    static let shared = LegalManager()
    
    // MARK: - Published Properties
    
    @Published var hasAcceptedTerms: Bool = false
    @Published var hasAcceptedPrivacy: Bool = false
    @Published var privacyConsentDate: Date?
    @Published var termsAcceptDate: Date?
    
    // MARK: - Constants
    
    private let termsVersion = "1.0"
    private let privacyVersion = "1.0"
    
    // MARK: - Private Properties
    
    private let termsKey = "birdgame3_termsAccepted"
    private let privacyKey = "birdgame3_privacyAccepted"
    private let termsVersionKey = "birdgame3_termsVersion"
    private let privacyVersionKey = "birdgame3_privacyVersion"
    private let termsDateKey = "birdgame3_termsDate"
    private let privacyDateKey = "birdgame3_privacyDate"
    
    // MARK: - Initialization
    
    private init() {
        loadConsentStatus()
    }
    
    // MARK: - Consent Management
    
    var needsConsent: Bool {
        !hasAcceptedTerms || !hasAcceptedPrivacy || needsReConsent
    }
    
    var needsReConsent: Bool {
        // Check if terms/privacy versions have been updated
        let savedTermsVersion = UserDefaults.standard.string(forKey: termsVersionKey) ?? ""
        let savedPrivacyVersion = UserDefaults.standard.string(forKey: privacyVersionKey) ?? ""
        
        return savedTermsVersion != termsVersion || savedPrivacyVersion != privacyVersion
    }
    
    func acceptTerms() {
        hasAcceptedTerms = true
        termsAcceptDate = Date()
        
        UserDefaults.standard.set(true, forKey: termsKey)
        UserDefaults.standard.set(termsVersion, forKey: termsVersionKey)
        UserDefaults.standard.set(termsAcceptDate, forKey: termsDateKey)
        
        AnalyticsManager.shared.trackEvent("terms_accepted", category: .ui)
    }
    
    func acceptPrivacy() {
        hasAcceptedPrivacy = true
        privacyConsentDate = Date()
        
        UserDefaults.standard.set(true, forKey: privacyKey)
        UserDefaults.standard.set(privacyVersion, forKey: privacyVersionKey)
        UserDefaults.standard.set(privacyConsentDate, forKey: privacyDateKey)
        
        AnalyticsManager.shared.trackEvent("privacy_accepted", category: .ui)
    }
    
    func acceptAll() {
        acceptTerms()
        acceptPrivacy()
    }
    
    func revokeConsent() {
        hasAcceptedTerms = false
        hasAcceptedPrivacy = false
        
        UserDefaults.standard.removeObject(forKey: termsKey)
        UserDefaults.standard.removeObject(forKey: privacyKey)
        
        AnalyticsManager.shared.trackEvent("consent_revoked", category: .ui)
    }
    
    private func loadConsentStatus() {
        hasAcceptedTerms = UserDefaults.standard.bool(forKey: termsKey)
        hasAcceptedPrivacy = UserDefaults.standard.bool(forKey: privacyKey)
        termsAcceptDate = UserDefaults.standard.object(forKey: termsDateKey) as? Date
        privacyConsentDate = UserDefaults.standard.object(forKey: privacyDateKey) as? Date
    }
    
    // MARK: - Document Content
    
    func getDocument(_ type: LegalDocumentType) -> String {
        switch type {
        case .privacyPolicy:
            return privacyPolicyContent
        case .termsOfService:
            return termsOfServiceContent
        case .eula:
            return eulaContent
        case .communityGuidelines:
            return communityGuidelinesContent
        }
    }
    
    // MARK: - Contact
    
    let supportEmail = "support@birdgame3.com"
    let privacyEmail = "privacy@birdgame3.com"
    
    func openSupport() {
        if let url = URL(string: "mailto:\(supportEmail)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Document Content

private let privacyPolicyContent = """
BIRD GAME 3 PRIVACY POLICY

Last Updated: December 2024

1. INTRODUCTION
Welcome to Bird Game 3. We respect your privacy and are committed to protecting your personal data.

2. DATA WE COLLECT
- Account Information: Username, email (if provided), friend code
- Gameplay Data: Statistics, achievements, purchases, preferences
- Device Information: Device type, OS version, app version
- Usage Data: How you interact with the game, crash logs

3. HOW WE USE YOUR DATA
- To provide and maintain the game service
- To personalize your experience
- To improve our game and services
- To communicate with you about updates and offers
- To detect and prevent cheating or fraud

4. DATA SHARING
We do not sell your personal data. We may share data with:
- Service providers who help us operate the game
- Law enforcement when required by law
- Other players (only your public profile information)

5. DATA RETENTION
We retain your data while your account is active. You may request deletion at any time.

6. YOUR RIGHTS
You have the right to:
- Access your personal data
- Correct inaccurate data
- Delete your data
- Object to processing
- Data portability

7. CHILDREN'S PRIVACY
Bird Game 3 is not intended for children under 13. We do not knowingly collect data from children.

8. SECURITY
We use industry-standard security measures to protect your data.

9. CHANGES
We may update this policy. Significant changes will be notified in-game.

10. CONTACT
For privacy concerns: privacy@birdgame3.com
"""

private let termsOfServiceContent = """
BIRD GAME 3 TERMS OF SERVICE

Last Updated: December 2024

1. ACCEPTANCE
By using Bird Game 3, you agree to these Terms of Service.

2. ACCOUNT
- You must be 13+ to create an account
- You are responsible for your account security
- One account per person
- Account sharing is prohibited

3. VIRTUAL ITEMS
- Virtual currency and items have no real-world value
- Purchases are non-refundable except as required by law
- We may modify virtual item prices or availability

4. USER CONDUCT
You agree NOT to:
- Cheat, hack, or exploit bugs
- Harass, abuse, or threaten other players
- Use offensive usernames or content
- Engage in real-money trading
- Impersonate others

5. INTELLECTUAL PROPERTY
Bird Game 3 and all content are owned by us. You may not copy, modify, or distribute any game content.

6. TERMINATION
We may suspend or terminate accounts that violate these terms.

7. DISCLAIMERS
The game is provided "as is" without warranties. We are not liable for:
- Service interruptions
- Lost progress or items
- Actions of other players

8. CHANGES
We may modify these terms. Continued use constitutes acceptance.

9. GOVERNING LAW
These terms are governed by applicable law.

10. CONTACT
For support: support@birdgame3.com
"""

private let eulaContent = """
END USER LICENSE AGREEMENT (EULA)

BIRD GAME 3

This End User License Agreement ("Agreement") is between you and the Bird Game 3 development team.

1. LICENSE GRANT
We grant you a limited, non-exclusive, non-transferable license to use Bird Game 3 for personal, non-commercial purposes.

2. RESTRICTIONS
You may not:
- Reverse engineer or decompile the game
- Create derivative works
- Remove any copyright notices
- Use the game for commercial purposes
- Distribute or sublicense the game

3. OWNERSHIP
We retain all rights to Bird Game 3 and its content.

4. UPDATES
We may update the game at any time. Continued use after updates constitutes acceptance.

5. TERMINATION
This license terminates if you breach this Agreement.

6. NO WARRANTY
The game is provided "as is" without warranty.

7. LIMITATION OF LIABILITY
We are not liable for any indirect, incidental, or consequential damages.

8. ENTIRE AGREEMENT
This is the complete agreement between you and us regarding the game.
"""

private let communityGuidelinesContent = """
BIRD GAME 3 COMMUNITY GUIDELINES

Welcome to the Bird Game 3 community! These guidelines help keep our game fun and safe for everyone.

🐦 BE RESPECTFUL
- Treat other players with kindness
- No harassment, bullying, or hate speech
- Respect players of all skill levels

💬 CHAT RESPONSIBLY
- Keep language appropriate for all ages
- No spam or excessive caps
- No sharing personal information

⚔️ PLAY FAIR
- No cheating, hacking, or exploiting
- Report bugs instead of abusing them
- Accept wins and losses gracefully

🪺 PROTECT THE COMMUNITY
- Report violations you witness
- Help new players learn the game
- Contribute positively to discussions

🚫 ZERO TOLERANCE
These actions result in immediate bans:
- Threats of violence
- Hate speech
- Child exploitation
- Real-money trading
- Account selling

📢 REPORTING
Use the in-game report function or email: support@birdgame3.com

Violations may result in warnings, temporary bans, or permanent account termination.

Let's keep Bird Game 3 fun for everyone! 🐦🎮
"""
