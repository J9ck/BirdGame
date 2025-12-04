# BirdGame

Bird Game iOS App with "The Wolf" style controls.

## Bird Game 3 - Control System

This update implements a control scheme mirroring **"The Wolf: Animal Game MMORPG"** iOS app controls for the Bird Game 3 combat system.

### Features

#### Movement Controls
- **Virtual Joystick** (Left Side): On-screen joystick for controlling bird movement
  - Smooth 360-degree directional control
  - Semi-transparent when idle, more visible when touched
  - Spring animation when released

#### Action Buttons (Right Side)
- **Primary Attack Button**: Large red button for basic peck/attack
- **4 Special Skill Buttons**: Arranged in a 2x2 grid
  - Each bird's unique abilities mapped to these slots
  - Visual cooldown timers on buttons
  - Skill icons representing each ability
- **Sprint/Dash Button**: Orange button for quick movement bursts (with cooldown)
- **Lock-On/Target Button**: Blue/yellow button to lock onto enemy bird

### UI Layout

```
┌─────────────────────────────────────────────────┐
│  [Health Bar]              [Enemy Health Bar]   │
│  [Bird Name]                [Enemy Bird Name]   │
│                                                 │
│           [GAME ARENA / COMBAT AREA]            │
│                                                 │
│                                                 │
│  ┌───┐                          [Skill1][Skill2]│
│  │ J │  <-- Joystick            [Skill3][Skill4]│
│  │ O │                      [TARGET][SPRINT]    │
│  │ Y │                              [ATTACK]    │
│  └───┘                                          │
└─────────────────────────────────────────────────┘
```

### Project Structure

```
BirdGame3/
├── Package.swift                    # Swift Package Manager config
├── Sources/
│   ├── App/
│   │   └── BirdGame3App.swift      # App entry point
│   ├── Models/
│   │   ├── Bird.swift              # Bird character model
│   │   ├── BirdSkill.swift         # Skill definitions
│   │   └── ControlInput.swift      # Control input state
│   ├── Views/
│   │   ├── ContentView.swift       # Main game view
│   │   ├── GameControlsView.swift  # Control overlay (Wolf-style)
│   │   └── Controls/
│   │       ├── VirtualJoystick.swift   # Joystick component
│   │       ├── SkillButton.swift       # Skill button with cooldown
│   │       ├── ActionButton.swift      # Attack/Sprint/Target buttons
│   │       └── HealthBar.swift         # Health bar display
│   └── Managers/
│       └── ControlManager.swift    # Input handling & game state
└── Tests/
    ├── ModelTests.swift            # Unit tests for models
    └── ControlManagerTests.swift   # Tests for control manager
```

### Components

#### VirtualJoystick
```swift
struct VirtualJoystick: View {
    @Binding var direction: CGVector
    // Returns normalized vector (-1 to 1) for movement
}
```

#### SkillButton
```swift
struct SkillButton: View {
    let skill: BirdSkill
    let cooldownRemaining: TimeInterval
    let action: () -> Void
    // Shows skill icon with cooldown overlay
}
```

#### ControlManager
- Processes joystick input and translates to bird movement
- Handles skill button presses and triggers abilities
- Manages sprint/dash with cooldown system
- Provides haptic feedback on button presses

### Building

**Requirements:**
- Xcode 15+ on macOS
- iOS 17+ deployment target

```bash
# Using Swift Package Manager (syntax check on Linux)
cd BirdGame3
swift build

# Run tests
swift test

# For full iOS build, use Xcode
```

### Polish Features

- ✅ Haptic feedback on button presses (UIImpactFeedbackGenerator)
- ✅ Visual feedback when buttons are pressed (scale/glow effect)
- ✅ Joystick returns to center with spring animation
- ✅ Responsive controls for action game feel
- ✅ Cooldown visualization on skill buttons
- ✅ Health bar with color-coded status
