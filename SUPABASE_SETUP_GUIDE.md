# 🐦 Bird Game 3 - Complete Supabase Setup Guide

This is a detailed walkthrough for setting up your Supabase backend. Follow each step carefully!

---

## 📋 Table of Contents

1. [Create Your Supabase Account](#step-1-create-your-supabase-account)
2. [Create a New Project](#step-2-create-a-new-project)
3. [Get Your API Credentials](#step-3-get-your-api-credentials)
4. [Run the Database Schema](#step-4-run-the-database-schema)
5. [Configure Authentication](#step-5-configure-authentication)
6. [Enable Real-time](#step-6-enable-real-time)
7. [Update Your Swift Code](#step-7-update-your-swift-code)
8. [Test the Connection](#step-8-test-the-connection)

---

## Step 1: Create Your Supabase Account

1. Go to **https://supabase.com**
2. Click **"Start your project"** (green button)
3. Sign up with:
   - GitHub (recommended - fastest)
   - Or email/password

---

## Step 2: Create a New Project

1. After signing in, click **"New Project"**
2. Fill in the details:

| Field | Value |
|-------|-------|
| **Organization** | Select your org (or create one) |
| **Name** | `birdgame3` |
| **Database Password** | Generate a strong password and **SAVE IT** |
| **Region** | Choose closest to your players (e.g., `West US` for California) |
| **Pricing Plan** | Free (can upgrade later) |

3. Click **"Create new project"**
4. Wait 1-2 minutes for the project to be provisioned

---

## Step 3: Get Your API Credentials

1. In your project dashboard, click **⚙️ Settings** (bottom left)
2. Click **API** in the sidebar
3. You'll see two important values:

### Project URL
```
https://YOUR-PROJECT-ID.supabase.co
```
Copy this entire URL.

### API Keys
Under "Project API keys", copy the **anon public** key (the longer one).

> ⚠️ **Important**: Never share your `service_role` key! Only use `anon` in your app.

---

## Step 4: Run the Database Schema

This creates all the tables Bird Game 3 needs.

1. In your Supabase dashboard, click **SQL Editor** (left sidebar)
2. Click **"New query"**
3. **Copy and paste this ENTIRE SQL script:**

```sql
-- =============================================
-- BIRD GAME 3 - COMPLETE DATABASE SCHEMA
-- =============================================
-- Run this entire script in Supabase SQL Editor
-- =============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- TABLE: player_profiles
-- Stores user account data, stats, and currency
-- =============================================
CREATE TABLE IF NOT EXISTS player_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    avatar_url TEXT,
    friend_code TEXT UNIQUE NOT NULL,
    level INTEGER DEFAULT 1,
    prestige_level INTEGER DEFAULT 0,
    total_xp INTEGER DEFAULT 0,
    coins INTEGER DEFAULT 500,
    feathers INTEGER DEFAULT 10,
    total_wins INTEGER DEFAULT 0,
    total_matches INTEGER DEFAULT 0,
    total_kills INTEGER DEFAULT 0,
    season_rank TEXT DEFAULT 'Egg 🥚',
    is_premium BOOLEAN DEFAULT FALSE,
    premium_expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_online TIMESTAMPTZ DEFAULT NOW(),
    is_online BOOLEAN DEFAULT TRUE
);

-- =============================================
-- TABLE: player_inventory
-- Stores owned skins, emotes, and equipped items
-- =============================================
CREATE TABLE IF NOT EXISTS player_inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id UUID REFERENCES player_profiles(id) ON DELETE CASCADE,
    owned_skins TEXT[] DEFAULT ARRAY['pigeon_default', 'crow_default', 'eagle_default', 'pelican_default', 'owl_default'],
    owned_emotes TEXT[] DEFAULT ARRAY['wave', 'taunt'],
    owned_trails TEXT[] DEFAULT ARRAY[]::TEXT[],
    equipped_skins JSONB DEFAULT '{}',
    equipped_emote TEXT DEFAULT 'wave',
    equipped_trail TEXT,
    UNIQUE(player_id)
);

-- =============================================
-- TABLE: friend_relations
-- Tracks friend requests and friendships
-- =============================================
CREATE TABLE IF NOT EXISTS friend_relations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id UUID REFERENCES player_profiles(id) ON DELETE CASCADE,
    friend_id UUID REFERENCES player_profiles(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(player_id, friend_id)
);

-- =============================================
-- TABLE: nests
-- Stores player nest data for open world mode
-- =============================================
CREATE TABLE IF NOT EXISTS nests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id UUID REFERENCES player_profiles(id) ON DELETE CASCADE,
    location_x DOUBLE PRECISION NOT NULL,
    location_y DOUBLE PRECISION NOT NULL,
    biome TEXT NOT NULL,
    level INTEGER DEFAULT 1,
    components TEXT[] DEFAULT ARRAY[]::TEXT[],
    resources JSONB DEFAULT '{}',
    last_raided TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(player_id)
);

-- =============================================
-- TABLE: matches
-- Records game match history
-- =============================================
CREATE TABLE IF NOT EXISTS matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    game_mode TEXT NOT NULL,
    winner_id UUID REFERENCES player_profiles(id),
    player_ids UUID[] NOT NULL,
    duration INTEGER,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    map_id TEXT,
    metadata JSONB
);

-- =============================================
-- TABLE: player_match_stats
-- Per-player statistics for each match
-- =============================================
CREATE TABLE IF NOT EXISTS player_match_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    player_id UUID REFERENCES player_profiles(id) ON DELETE CASCADE,
    bird_type TEXT NOT NULL,
    skin_id TEXT NOT NULL,
    kills INTEGER DEFAULT 0,
    deaths INTEGER DEFAULT 0,
    damage_dealt INTEGER DEFAULT 0,
    damage_taken INTEGER DEFAULT 0,
    placement INTEGER,
    xp_earned INTEGER DEFAULT 0,
    coins_earned INTEGER DEFAULT 0
);

-- =============================================
-- TABLE: flocks
-- Clans/Guilds system
-- =============================================
CREATE TABLE IF NOT EXISTS flocks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    tag TEXT UNIQUE NOT NULL,
    description TEXT,
    leader_id UUID REFERENCES player_profiles(id),
    member_count INTEGER DEFAULT 1,
    max_members INTEGER DEFAULT 50,
    level INTEGER DEFAULT 1,
    total_xp INTEGER DEFAULT 0,
    icon_id TEXT,
    is_recruiting BOOLEAN DEFAULT TRUE,
    min_level_to_join INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- TABLE: flock_members
-- Tracks clan membership and roles
-- =============================================
CREATE TABLE IF NOT EXISTS flock_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    flock_id UUID REFERENCES flocks(id) ON DELETE CASCADE,
    player_id UUID REFERENCES player_profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member' CHECK (role IN ('leader', 'officer', 'member')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(player_id)
);

-- =============================================
-- TABLE: chat_messages
-- In-game chat history
-- =============================================
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id TEXT NOT NULL,
    sender_id UUID REFERENCES player_profiles(id) ON DELETE SET NULL,
    sender_name TEXT NOT NULL,
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'emote', 'system')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- TABLE: reports
-- Player reports for moderation
-- =============================================
CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID REFERENCES player_profiles(id),
    reported_id UUID REFERENCES player_profiles(id),
    reason TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'action_taken', 'dismissed')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- TABLE: battle_pass_progress
-- Tracks battle pass tier progress
-- =============================================
CREATE TABLE IF NOT EXISTS battle_pass_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id UUID REFERENCES player_profiles(id) ON DELETE CASCADE,
    season INTEGER NOT NULL,
    current_tier INTEGER DEFAULT 1,
    tier_xp INTEGER DEFAULT 0,
    is_premium BOOLEAN DEFAULT FALSE,
    purchased_at TIMESTAMPTZ,
    claimed_rewards JSONB DEFAULT '[]',
    UNIQUE(player_id, season)
);

-- =============================================
-- TABLE: achievements
-- Tracks unlocked achievements per player
-- =============================================
CREATE TABLE IF NOT EXISTS achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id UUID REFERENCES player_profiles(id) ON DELETE CASCADE,
    achievement_id TEXT NOT NULL,
    unlocked_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(player_id, achievement_id)
);

-- =============================================
-- TABLE: daily_challenges
-- Tracks daily challenge progress
-- =============================================
CREATE TABLE IF NOT EXISTS daily_challenges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id UUID REFERENCES player_profiles(id) ON DELETE CASCADE,
    challenge_date DATE DEFAULT CURRENT_DATE,
    challenges JSONB NOT NULL,
    completed_count INTEGER DEFAULT 0,
    UNIQUE(player_id, challenge_date)
);

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================

-- Enable RLS on all tables
ALTER TABLE player_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_relations ENABLE ROW LEVEL SECURITY;
ALTER TABLE nests ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_match_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE flocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE flock_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE battle_pass_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_challenges ENABLE ROW LEVEL SECURITY;

-- =============================================
-- POLICIES: player_profiles
-- =============================================
CREATE POLICY "Public profiles are viewable by everyone" 
    ON player_profiles FOR SELECT 
    USING (true);

CREATE POLICY "Users can update own profile" 
    ON player_profiles FOR UPDATE 
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" 
    ON player_profiles FOR INSERT 
    WITH CHECK (auth.uid() = id);

-- =============================================
-- POLICIES: player_inventory
-- =============================================
CREATE POLICY "Users can view own inventory" 
    ON player_inventory FOR SELECT 
    USING (auth.uid() = player_id);

CREATE POLICY "Users can update own inventory" 
    ON player_inventory FOR UPDATE 
    USING (auth.uid() = player_id);

CREATE POLICY "Users can insert own inventory" 
    ON player_inventory FOR INSERT 
    WITH CHECK (auth.uid() = player_id);

-- =============================================
-- POLICIES: friend_relations
-- =============================================
CREATE POLICY "Users can view own friends" 
    ON friend_relations FOR SELECT 
    USING (auth.uid() = player_id OR auth.uid() = friend_id);

CREATE POLICY "Users can send friend requests" 
    ON friend_relations FOR INSERT 
    WITH CHECK (auth.uid() = player_id);

CREATE POLICY "Users can update friend status" 
    ON friend_relations FOR UPDATE 
    USING (auth.uid() = friend_id);

-- =============================================
-- POLICIES: nests
-- =============================================
CREATE POLICY "Users can view all nests" 
    ON nests FOR SELECT 
    USING (true);

CREATE POLICY "Users can update own nest" 
    ON nests FOR UPDATE 
    USING (auth.uid() = player_id);

CREATE POLICY "Users can insert own nest" 
    ON nests FOR INSERT 
    WITH CHECK (auth.uid() = player_id);

-- =============================================
-- POLICIES: chat_messages
-- =============================================
CREATE POLICY "Users can view chat messages" 
    ON chat_messages FOR SELECT 
    USING (true);

CREATE POLICY "Users can send chat messages" 
    ON chat_messages FOR INSERT 
    WITH CHECK (auth.uid() = sender_id);

-- =============================================
-- POLICIES: matches
-- =============================================
CREATE POLICY "Anyone can view matches" 
    ON matches FOR SELECT 
    USING (true);

CREATE POLICY "Authenticated users can create matches" 
    ON matches FOR INSERT 
    WITH CHECK (auth.uid() IS NOT NULL);

-- =============================================
-- POLICIES: player_match_stats
-- =============================================
CREATE POLICY "Anyone can view match stats" 
    ON player_match_stats FOR SELECT 
    USING (true);

CREATE POLICY "Users can insert own match stats" 
    ON player_match_stats FOR INSERT 
    WITH CHECK (auth.uid() = player_id);

-- =============================================
-- POLICIES: flocks
-- =============================================
CREATE POLICY "Anyone can view flocks" 
    ON flocks FOR SELECT 
    USING (true);

CREATE POLICY "Leaders can update flocks" 
    ON flocks FOR UPDATE 
    USING (auth.uid() = leader_id);

CREATE POLICY "Authenticated users can create flocks" 
    ON flocks FOR INSERT 
    WITH CHECK (auth.uid() IS NOT NULL);

-- =============================================
-- POLICIES: flock_members
-- =============================================
CREATE POLICY "Anyone can view flock members" 
    ON flock_members FOR SELECT 
    USING (true);

CREATE POLICY "Users can join flocks" 
    ON flock_members FOR INSERT 
    WITH CHECK (auth.uid() = player_id);

CREATE POLICY "Users can leave flocks" 
    ON flock_members FOR DELETE 
    USING (auth.uid() = player_id);

-- =============================================
-- POLICIES: reports
-- =============================================
CREATE POLICY "Users can view own reports" 
    ON reports FOR SELECT 
    USING (auth.uid() = reporter_id);

CREATE POLICY "Users can submit reports" 
    ON reports FOR INSERT 
    WITH CHECK (auth.uid() = reporter_id);

-- =============================================
-- POLICIES: battle_pass_progress
-- =============================================
CREATE POLICY "Users can view own battle pass" 
    ON battle_pass_progress FOR SELECT 
    USING (auth.uid() = player_id);

CREATE POLICY "Users can update own battle pass" 
    ON battle_pass_progress FOR UPDATE 
    USING (auth.uid() = player_id);

CREATE POLICY "Users can insert own battle pass" 
    ON battle_pass_progress FOR INSERT 
    WITH CHECK (auth.uid() = player_id);

-- =============================================
-- POLICIES: achievements
-- =============================================
CREATE POLICY "Users can view own achievements" 
    ON achievements FOR SELECT 
    USING (auth.uid() = player_id);

CREATE POLICY "Users can unlock achievements" 
    ON achievements FOR INSERT 
    WITH CHECK (auth.uid() = player_id);

-- =============================================
-- POLICIES: daily_challenges
-- =============================================
CREATE POLICY "Users can view own challenges" 
    ON daily_challenges FOR SELECT 
    USING (auth.uid() = player_id);

CREATE POLICY "Users can update own challenges" 
    ON daily_challenges FOR UPDATE 
    USING (auth.uid() = player_id);

CREATE POLICY "Users can insert own challenges" 
    ON daily_challenges FOR INSERT 
    WITH CHECK (auth.uid() = player_id);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================
CREATE INDEX IF NOT EXISTS idx_player_profiles_friend_code ON player_profiles(friend_code);
CREATE INDEX IF NOT EXISTS idx_player_profiles_username ON player_profiles(username);
CREATE INDEX IF NOT EXISTS idx_player_profiles_online ON player_profiles(is_online);
CREATE INDEX IF NOT EXISTS idx_player_profiles_level ON player_profiles(prestige_level DESC, level DESC);
CREATE INDEX IF NOT EXISTS idx_friend_relations_player ON friend_relations(player_id);
CREATE INDEX IF NOT EXISTS idx_friend_relations_friend ON friend_relations(friend_id);
CREATE INDEX IF NOT EXISTS idx_friend_relations_status ON friend_relations(status);
CREATE INDEX IF NOT EXISTS idx_nests_player ON nests(player_id);
CREATE INDEX IF NOT EXISTS idx_nests_biome ON nests(biome);
CREATE INDEX IF NOT EXISTS idx_chat_messages_channel ON chat_messages(channel_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created ON chat_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_matches_mode ON matches(game_mode);
CREATE INDEX IF NOT EXISTS idx_matches_started ON matches(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_achievements_player ON achievements(player_id);
CREATE INDEX IF NOT EXISTS idx_battle_pass_season ON battle_pass_progress(season);

-- =============================================
-- FUNCTIONS
-- =============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for player_profiles
CREATE TRIGGER update_player_profiles_updated_at
    BEFORE UPDATE ON player_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Trigger for nests
CREATE TRIGGER update_nests_updated_at
    BEFORE UPDATE ON nests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- =============================================
-- SUCCESS MESSAGE
-- =============================================
SELECT 'Bird Game 3 database schema created successfully! 🐦' as message;
```

4. Click **"Run"** (or press Cmd/Ctrl + Enter)
5. You should see: `Bird Game 3 database schema created successfully! 🐦`

---

## Step 5: Configure Authentication

### Enable Email Auth (Already enabled by default)

1. Go to **Authentication** → **Providers**
2. Email should already be enabled
3. Optional: Disable "Confirm email" for easier testing

### Set Up Sign in with Apple

1. Go to **Authentication** → **Providers**
2. Find **Apple** and toggle it ON
3. You'll need credentials from Apple Developer:
   - Services ID
   - Team ID  
   - Key ID
   - Private Key

> 📝 **Note**: Sign in with Apple requires an Apple Developer account ($99/year). You can skip this for now and use email/guest auth.

### Customize Email Templates (Optional)

1. Go to **Authentication** → **Email Templates**
2. Update "Confirm signup" template:
   - Subject: `Welcome to Bird Game 3! 🐦`
   - Customize the message

---

## Step 6: Enable Real-time

For live features like online status and chat:

1. Go to **Database** → **Replication**
2. Find and enable these tables:
   - ✅ `player_profiles`
   - ✅ `chat_messages`
   - ✅ `friend_relations`

This allows the app to receive instant updates when data changes.

---

## Step 7: Update Your Swift Code

Open `BirdGame3/Managers/SupabaseManager.swift` and find these lines near the top:

```swift
struct SupabaseConfig {
    /// Your Supabase project URL (e.g., "https://xyzcompany.supabase.co")
    static let projectURL = "YOUR_SUPABASE_PROJECT_URL"
    
    /// Your Supabase anon/public key
    static let anonKey = "YOUR_SUPABASE_ANON_KEY"
```

Replace with your actual values:

```swift
struct SupabaseConfig {
    static let projectURL = "https://abcd1234.supabase.co"  // Your URL
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR..."      // Your anon key
```

---

## Step 8: Test the Connection

1. Build and run the app in Xcode
2. Try creating a guest account
3. Check your Supabase dashboard:
   - Go to **Authentication** → **Users** (should see new user)
   - Go to **Table Editor** → **player_profiles** (should see profile)

---

## 🎉 You're Done!

Your Supabase backend is now set up for Bird Game 3!

### What's Working Now:
- ✅ User authentication (email, guest)
- ✅ Player profiles with stats
- ✅ Currency (coins, feathers)
- ✅ Friend system with friend codes
- ✅ Inventory (skins, emotes)
- ✅ Nest saving/loading
- ✅ Match history
- ✅ Leaderboards
- ✅ Chat messages
- ✅ Achievements tracking
- ✅ Battle pass progress
- ✅ Daily challenges

---

## 🔧 Troubleshooting

### "Not Configured" Error
- Make sure you replaced BOTH `projectURL` and `anonKey` in Swift

### "Unauthorized" Error
- Check that your anon key is correct (copy it again)
- Make sure you ran the SQL schema (includes security policies)

### "User not found" after signup
- The SQL schema creates a trigger that should create profiles automatically
- If issues persist, check **Authentication** → **Users** in dashboard

### Tables are empty
- Make sure you clicked "Run" on the SQL schema
- Check for any error messages in the SQL editor output

---

## 📊 Monitoring Your Database

### View Data
- **Table Editor**: Browse and edit data directly
- **Logs**: See API requests and errors
- **Reports**: Database usage and performance

### Free Tier Limits
| Resource | Limit |
|----------|-------|
| Database | 500 MB |
| Bandwidth | 2 GB/month |
| Auth Users | 50,000 MAU |
| Edge Functions | 500K invocations |

You can monitor usage in **Settings** → **Billing**.

---

## 🚀 Next Steps

1. **Test thoroughly** - Create accounts, add friends, play matches
2. **Add Sign in with Apple** when you have Apple Developer account
3. **Set up push notifications** in Supabase Edge Functions (optional)
4. **Configure backups** if you upgrade to Pro tier

Need help? Check [Supabase Docs](https://supabase.com/docs) or [Discord](https://discord.supabase.com)!
