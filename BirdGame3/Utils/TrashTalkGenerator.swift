//
//  TrashTalkGenerator.swift
//  BirdGame3
//
//  The sacred art of bird game banter
//

import Foundation

class TrashTalkGenerator {
    
    static let shared = TrashTalkGenerator()
    
    // MARK: - In-Game Messages
    
    private let battleMessages = [
        "PIGEON MAINS RISE UP! 🐦",
        "just spam pecks bro",
        "nerf hummingbird pls",
        "skill issue tbh",
        "L + ratio + you fell off",
        "imagine losing to a pigeon lmao",
        "my grandma pecks harder than that",
        "built different fr fr",
        "touch grass (bird edition)",
        "gg ez no re",
        "why is this bird so broken??",
        "report for hacking",
        "lag diff 100%",
        "that's not even a real bird",
        "where's the nerf patch???",
        "bruh that hitbox",
        "devs sleeping on balance",
        "that was my little brother",
        "1v1 me in Bird Game 4",
        "controller died mid-peck",
        "I wasn't even trying",
        "you're sweating in BIRD GAME?",
        "eagle mains are compensating for something",
        "crow players are built different (weird)",
        "pelican pouch is pay to win",
        "this game is rigged",
        "nice peck loser",
        "get good scrub",
        "imagine being a ground bird lol",
        "wings diff",
        "beak diff",
        "feather density check failed",
        "you call that flying?",
        "birds aren't even real",
        "government drone detected",
        "cope + seethe + mald",
        "skill gap = grand canyon",
        "nice air",
        "absolutely cooked 🔥",
        "that bird got BODIED",
        "free win honestly",
        "bird game diff"
    ]
    
    // MARK: - Usernames
    
    private let usernames = [
        "xX_PigeonLord_Xx",
        "EagleFan2024",
        "HummingbirdOPPls",
        "CrowMaster420",
        "PelicanEnjoyer",
        "BirdGame3Pro",
        "FlyingRat69",
        "TalonTerror",
        "FeatherFury",
        "BeakBoss",
        "WingWarrior",
        "PeckMaster",
        "SkyDominator",
        "NestDestroyer",
        "EggBreaker",
        "SeedStealer",
        "WormHunter",
        "TreeTopKing",
        "CloudChaser",
        "WindRider",
        "TTVBirdGamer",
        "NotADrone",
        "GovernmentSpy",
        "RealBirdTrust",
        "CooCooCrew",
        "BreadcrumbBandit",
        "ParkBenchPro",
        "StatuePoopr",
        "CarWindshield",
        "BirdIsTheWord"
    ]
    
    // MARK: - Victory Messages
    
    private let victoryMessages = [
        "GG EZ NO RE",
        "That bird got absolutely COOKED 🔥",
        "The prophecy has been fulfilled",
        "Your opponent has left the chat",
        "Built different fr fr",
        "Skill diff tbh",
        "Get pecked on 🐦💨",
        "They weren't ready for the bird meta",
        "Report opponent for feeding",
        "Another one for the highlight reel",
        "That's what peak performance looks like",
        "Natural selection in action",
        "Darwin would be proud",
        "Evolution of a winner",
        "Sigma bird grindset"
    ]
    
    // MARK: - Defeat Messages
    
    private let defeatMessages = [
        "gg go next",
        "Lag diff 100%",
        "My little brother was playing",
        "Controller died mid-match",
        "Just warming up tbh",
        "Nerf that bird pls devs",
        "I wasn't even trying",
        "You're sweating in a bird game??",
        "Mom made me stop playing",
        "That was just practice",
        "Rematch or you're scared",
        "Lucky pecks don't count",
        "My wings were clipped",
        "Unfair matchmaking",
        "Wait for the balance patch"
    ]
    
    // MARK: - Loading Tips
    
    static let loadingTips = [
        "Pro tip: Just spam pecks",
        "Hummingbird has been nerfed 47 times and is still OP",
        "Remember: Blocking is for cowards (but also smart)",
        "Pelican mains are built different",
        "If you lose, it's definitely lag",
        "Eagle mains are just pigeon mains in denial",
        "Crow players are legally required to be mysterious",
        "Did you know? Pigeons can't actually fly. They just fall with style.",
        "Loading actual bird facts... ERROR: No real facts found",
        "The devs are still trying to nerf hummingbird. They can't.",
        "Fun fact: This game was balanced by a goldfish",
        "Your rank means nothing. It's all about the pecks.",
        "Server hamster is running at maximum speed 🐹",
        "Tip: Birds aren't real. You're fighting government drones.",
        "The crow knows your search history",
        "Pelican's pouch is bigger on the inside",
        "Eagle's special move costs $4.99 (not really)",
        "Pigeon has been S-tier since Bird Game 1",
        "There is no Bird Game 1 or 2. Only 3.",
        "The numbers on the leaderboard are made up",
        "Patch 3.47 removed Herobrine (and added him back)",
        "Your MMR is calculated using bird law",
        "Feather density is actually meaningless",
        "Coo Power has never been explained by devs"
    ]
    
    // MARK: - Fake Patch Notes
    
    static let fakePatchNotes = [
        "v3.47.2: Nerfed Hummingbird (again)",
        "v3.47.1: Buffed Pigeon's coo radius",
        "v3.47.0: Fixed bug where Pelican could eat the sun",
        "v3.46.9: Crow's shinies now 13% shinier",
        "v3.46.8: Eagle screech now causes existential dread",
        "v3.46.7: Removed unfair advantage for players who can fly",
        "v3.46.6: Pigeon's bread consumption rate increased",
        "v3.46.5: Fixed Hummingbird being able to divide by zero",
        "v3.46.4: Pelican can no longer swallow the entire map",
        "v3.46.3: Added more pixels to Eagle's majestic gaze"
    ]
    
    // MARK: - Public Methods
    
    func getRandomMessage() -> String {
        return battleMessages.randomElement() ?? "..."
    }
    
    func getRandomUsername() -> String {
        return usernames.randomElement() ?? "Anonymous"
    }
    
    func getVictoryMessage() -> String {
        return victoryMessages.randomElement() ?? "You win!"
    }
    
    func getDefeatMessage() -> String {
        return defeatMessages.randomElement() ?? "You lose..."
    }
    
    func getLoadingTip() -> String {
        return TrashTalkGenerator.loadingTips.randomElement() ?? "Loading..."
    }
    
    func getFakePatchNote() -> String {
        return TrashTalkGenerator.fakePatchNotes.randomElement() ?? "No patches today"
    }
    
    // MARK: - Character-Specific Trash Talk
    
    func getTrashTalkFor(bird: BirdType) -> String {
        switch bird {
        case .pigeon:
            return [
                "Coo coo mothercooo",
                "Bread acquired. Victory imminent.",
                "Park bench champion incoming",
                "You're about to get statue'd"
            ].randomElement()!
            
        case .hummingbird:
            return [
                "*vibrates menacingly*",
                "You can't hit what you can't see",
                "Speed is a flat circle. I am the circle.",
                "47 nerfs and still goated"
            ].randomElement()!
            
        case .eagle:
            return [
                "FREEDOM SCREEEECH",
                "Talons of liberty incoming",
                "I'm not locked in here with you...",
                "MURICA"
            ].randomElement()!
            
        case .crow:
            return [
                "Caw caw (this means you're doomed)",
                "I've memorized your credit card number",
                "The shinies told me your weakness",
                "Nothing personal, kid"
            ].randomElement()!
            
        case .pelican:
            return [
                "*ominous gulping sounds*",
                "My pouch holds your defeat",
                "Thicc thighs take lives",
                "I've swallowed worse than you"
            ].randomElement()!
        }
    }
}

// MARK: - Static Access

extension TrashTalkGenerator {
    static func getRandomMessage() -> String {
        return shared.getRandomMessage()
    }
}
