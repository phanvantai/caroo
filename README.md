# Caroo - Infinite Tic-Tac-Toe 🎮

A modern iOS game that takes the classic tic-tac-toe to the next level with an infinite scrollable grid and beautiful themes.

## 🎯 Game Features

### Core Gameplay

- **Infinite Grid**: Play on an unlimited scrollable grid - no more ties!
- **Win Condition**: Get 5 in a row (horizontal, vertical, or diagonal) to win
- **Two Game Modes**:
  - 🤖 **Single Player**: vs Basic AI (AI improvements coming soon!)
  - 👥 **Two Players**: Local multiplayer on the same device

### Visual & Audio

- **3 Beautiful Themes**:
  - 🌟 **Neon**: Cyberpunk-inspired with glowing effects
  - 📚 **Classic**: Clean, traditional tic-tac-toe look
  - 🌌 **Cosmic**: Dark space theme with stellar effects
- **Smooth Animations**: Enhanced placement effects and transitions
- **Sound Effects**: Audio feedback for moves, wins, and theme changes
- **Interactive UI**: Animated backgrounds and particle effects

### Controls & Navigation

- **Tap to Play**: Touch any empty cell to place your mark
- **Drag to Scroll**: Navigate the infinite grid with smooth panning
- **Theme Switching**: Change themes on-the-fly with the theme button
- **Easy Navigation**: Back button to return to menu anytime

## 🛠 Technical Details

### Built With

- **Swift 5**
- **SpriteKit Framework** - For 2D graphics and animations
- **iOS 13.0+** - Minimum deployment target
- **Xcode Project** - Ready to build and run

### Architecture

- **MVC Pattern**: Clean separation of game logic and presentation
- **Component-Based**: Modular design with reusable components
  - `GameScene.swift` - Main game logic and rendering
  - `MenuScene.swift` - Main menu and navigation
  - `ThemeManager.swift` - Theme system and persistence
  - `SoundManager.swift` - Audio management
  - `WinPopup.swift` - Victory celebration UI

### Performance Features

- **Optimized Rendering**: Only draws visible grid cells
- **Node Pooling**: Efficient memory management for grid elements
- **Smooth Scrolling**: Responsive camera system with dynamic updates

## 🚀 Getting Started

### Prerequisites

- Xcode 12.0 or later
- iOS 13.0+ device or simulator
- macOS 10.15+ for development

### Installation

1. Clone the repository:

   ```bash
   git clone [repository-url]
   cd Caroo
   ```

2. Open the project in Xcode:

   ```bash
   open Caroo.xcodeproj
   ```

3. Select your target device or simulator

4. Build and run the project (⌘+R)

## 🎮 How to Play

1. **Launch the game** and choose your mode from the main menu
2. **Tap any cell** on the grid to place your mark (X or O)
3. **Drag to scroll** and explore the infinite playing field
4. **Get 5 in a row** (any direction) to win!
5. **Switch themes** anytime using the 🎨 button
6. **Use the back button** (‹) to return to the main menu

## 🔧 Project Structure

```bash
Caroo/
├── Caroo/
│   ├── GameScene.swift          # Main game logic
│   ├── MenuScene.swift          # Main menu
│   ├── GameViewController.swift # View controller
│   ├── AppDelegate.swift        # App lifecycle
│   ├── Components/
│   │   ├── ThemeManager.swift   # Theme system
│   │   ├── SoundManager.swift   # Audio management
│   │   └── WinPopup.swift       # Victory UI
│   ├── Assets.xcassets/         # Game assets
│   └── Base.lproj/              # Storyboards
├── CarooTests/                  # Unit tests
├── CarooUITests/               # UI tests
└── Caroo.xcodeproj/            # Xcode project
```

## 🔮 Upcoming Features

- 🤖 **Advanced AI**: Smarter AI opponent with multiple difficulty levels
- 🏆 **Game Statistics**: Track wins, games played, and streaks
- 🎵 **Music & Enhanced Audio**: Background music and improved sound effects
- 📱 **Online Multiplayer**: Play with friends remotely
- 🎨 **More Themes**: Additional visual themes and customization options
- ⚡ **Power-ups**: Special abilities and game modifiers
- 🏅 **Achievements**: Unlock rewards for various accomplishments

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Authors

- **Tai Phan Van** - *Initial development* - Created January 14, 2025

## 🙏 Acknowledgments

- Inspired by the classic tic-tac-toe game
- Built with Apple's SpriteKit framework
- UI/UX inspired by modern mobile game design patterns

---

### **Enjoy playing Caroo! 🎉**

*For questions or support, please open an issue in the repository.*
