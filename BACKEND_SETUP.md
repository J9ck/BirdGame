# Bird Game 3 - Backend Setup Guide

This guide explains how to set up the Supabase backend for Bird Game 3.

## Why Supabase?

Supabase is an excellent choice for Bird Game 3 because:

1. **Free Tier** - Generous free tier for development and small player bases
2. **Real-time** - Built-in WebSocket support for live multiplayer features
3. **Auth** - Easy Sign in with Apple, Google, and email authentication
4. **PostgreSQL** - Powerful database with JSON support
5. **Row Level Security** - Built-in security policies
6. **Swift-friendly** - Works great with native iOS development
7. **Scalable** - Easy to scale as player base grows

## Quick Start

### Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign up / Sign in
3. Click "New Project"
4. Enter project details:
   - **Name**: `birdgame3` (or your preferred name)
   - **Database Password**: Save this securely!
   - **Region**: Choose closest to your players

### Step 2: Get Your API Keys

1. In Supabase Dashboard, go to **Settings > API**
2. Copy your:
   - **Project URL** (e.g., `https://xyzcompany.supabase.co`)
   - **Anon/Public Key** (safe to use in client apps)

### Step 3: Configure Bird Game 3

Open `BirdGame3/Managers/SupabaseManager.swift` and update the configuration:

```swift
struct SupabaseConfig {
    static let projectURL = "YOUR_SUPABASE_PROJECT_URL"  // Replace this
    static let anonKey = "YOUR_SUPABASE_ANON_KEY"        // Replace this
}
```

### Step 4: Create Database Schema

1. In Supabase Dashboard, go to **SQL Editor**
2. Click "New Query"
3. Copy and paste the SQL schema from the bottom of `SupabaseManager.swift`
4. Click "Run" to create all tables

## Database Schema Overview

| Table | Purpose |
|-------|---------|
| `player_profiles` | User accounts, stats, currency |
| `player_inventory` | Owned skins, emotes, equipped items |
| `friend_relations` | Friend requests and relationships |
| `nests` | Player nest data for open world |
| `matches` | Game match history |
| `player_match_stats` | Per-player stats for each match |
| `flocks` | Clans/Guilds |
| `flock_members` | Clan membership |
| `chat_messages` | In-game chat history |
| `reports` | Player reports for moderation |

## Authentication Setup

### Sign in with Apple

1. In Supabase Dashboard, go to **Authentication > Providers**
2. Enable "Apple"
3. In Apple Developer Portal:
   - Create a Services ID
   - Configure Sign in with Apple
   - Add your redirect URL from Supabase
4. Enter your Apple credentials in Supabase

### Email Authentication

Email auth is enabled by default. To customize:

1. Go to **Authentication > Email Templates**
2. Customize confirmation and password reset emails
3. Update sender name to "Bird Game 3"

## Real-time Features

For live multiplayer, enable Realtime on key tables:

1. Go to **Database > Replication**
2. Enable for tables:
   - `player_profiles` (online status)
   - `chat_messages` (live chat)
   - `friend_relations` (friend updates)

## Security

Row Level Security (RLS) is enabled by the schema. Key policies:

- Players can only update their own profile
- Players can view all public profiles (for leaderboards)
- Chat messages are public but only insertable by sender
- Nests are public (for raiding) but only editable by owner

## Scaling Considerations

### Free Tier Limits
- 500 MB database
- 2 GB bandwidth/month
- 50,000 monthly active users

### Pro Tier ($25/month)
- 8 GB database
- 250 GB bandwidth/month
- Unlimited MAUs
- Daily backups

### When to Upgrade
- 10,000+ daily active players
- Need database backups
- Need faster support

## Future: PlayFab for Cross-Platform

If you want to expand to PC/Xbox later:

1. **Keep Supabase** for:
   - Web/iOS players
   - Chat and social features
   - Player profiles

2. **Add PlayFab** for:
   - Xbox Live integration
   - PC achievements
   - Cross-platform matchmaking

You can run both backends and sync player data between them.

## Troubleshooting

### "Not Configured" Error
Make sure you've replaced the placeholder values in `SupabaseConfig`.

### "Unauthorized" Error
Check that your anon key is correct and Row Level Security policies are set up.

### "Network Error"
Ensure the device has internet access and your Supabase project is active.

## Support

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Discord](https://discord.supabase.com)
- [Bird Game 3 Issues](https://github.com/J9ck/BirdGame/issues)
