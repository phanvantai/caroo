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
│   │   ├── WinPopup.swift       # Victory UI
│   │   └── AI/
│   │       └── AIBot.swift      # AI base class & protocol
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

## 🤖 AI Implementation Status

### ✅ Completed Features

#### **Core AI Infrastructure** (Step 1.1) - *COMPLETED*

- ✅ **AIBot Base Class**: Protocol-based architecture with `AIBotProtocol`
- ✅ **Difficulty System**: 5 levels (Novice, Intermediate, Advanced, Master, Adaptive)
- ✅ **AI Personalities**: 4 types (Balanced, Aggressive, Defensive, Unpredictable)
- ✅ **Smart Move Evaluation**: Threat detection, positional analysis, pattern recognition
- ✅ **Infinite Grid Optimization**: Smart search areas and memory management
- ✅ **State Management**: Move history, performance metrics, game state tracking

#### **Advanced Strategy Foundation** (Step 1.2) - *COMPLETED*

- ✅ **Minimax Algorithm**: Full recursive minimax with alpha-beta pruning for optimal move calculation
- ✅ **Enhanced Position Evaluation**: Multi-factor scoring system with territorial control and mobility analysis
- ✅ **Advanced Threat Detection**: Immediate win/block detection, multi-step threat recognition, fork analysis
- ✅ **Pattern Recognition**: Comprehensive 2-3-4-5 in-a-row pattern evaluation and strategic positioning
- ✅ **Tactical Analysis**: Double threats, spaced patterns, and complex formation recognition
- ✅ **Performance Optimization**: Alpha-beta pruning, bounded search areas, efficient line analysis

#### **Key Technical Features**

- **Protocol-Based Design**: Clean, extensible architecture following Swift best practices
- **Performance Optimized**: Memory-efficient for large infinite grid games with alpha-beta pruning
- **Advanced Threat System**: Multi-level threat detection with fork opportunities and pattern analysis
- **Strategic Positioning**: Territory control evaluation, mobility analysis, and clustering strategies
- **Adaptive Difficulty**: Framework for dynamic difficulty adjustment with player skill assessment
- **Factory Pattern**: Easy AI instance creation and management with multiple difficulty levels

### 🚧 In Progress

- Integration with existing GameScene.swift
- Difficulty-specific AI implementations
- Menu UI for difficulty selection

## 🤖 Bot Implementation Roadmap

### Overview

Enhance the current basic AI with intelligent bot opponents featuring multiple difficulty levels and advanced strategies for the infinite tic-tac-toe gameplay.

### Phase 1: Core AI Infrastructure (Week 1-2)

#### Step 1.1: AI Architecture Setup

- [x] Create `AIBot` base class with protocol-based design
- [x] Implement difficulty levels enum (`Novice`, `Intermediate`, `Advanced`, `Master`, `Adaptive`)
- [x] Add AI player state management
- [x] Create AI move evaluation system

#### Step 1.2: Basic Strategy Foundation

- [x] Implement minimax algorithm foundation
- [x] Add position evaluation scoring system
- [x] Create threat detection system (immediate wins/blocks)
- [x] Implement basic pattern recognition for 2-3-4 in a row

#### Step 1.3: Integration with Game Engine

- [x] ~~Modify `GameScene.swift` to support AI difficulty selection~~ **COMPLETED** - Implemented difficulty selection UI in `MenuScene.swift` with popup interface
- [x] **Add AI move delay/animation for better UX** - **COMPLETED** - Implemented configurable AI delay with visual feedback and smooth animations
- [x] **Update game state management for AI turns** - **COMPLETED** - Enhanced with comprehensive state validation, error handling, and robust turn management
- [x] **Implement AI move validation and error handling** - **COMPLETED** - Added comprehensive move validation, state consistency checks, and automatic error recovery

### Phase 2: Intelligent Move Algorithms (Week 2-3)

#### Step 2.1: Threat Analysis System

- [x] **Immediate Win Detection**: Find winning moves in 1 turn **COMPLETED** ✅
- [ ] **Block Critical Threats**: Prevent opponent wins in 1 turn
- [ ] **Multi-Step Threat Recognition**: Detect 2-3 move winning sequences
- [ ] **Fork Detection**: Identify and create/block multiple win threats

#### Step 2.2: Strategic Position Evaluation

- [ ] **Center Control**: Prioritize central positions for influence
- [ ] **Line Development**: Evaluate potential 5-in-a-row formations
- [ ] **Spacing Strategy**: Optimal spacing for infinite grid play
- [ ] **Territory Control**: Area influence and board control metrics

#### Step 2.3: Advanced Pattern Recognition

- [ ] **Offensive Patterns**: Recognize 22, 33, 44 formations
- [ ] **Defensive Patterns**: Counter common attacking strategies
- [ ] **Formation Analysis**: Evaluate L-shapes, diagonals, crosses
- [ ] **Pattern Database**: Store and learn from successful patterns

### Phase 3: Difficulty Implementation (Week 3-4)

#### Step 3.1: Novice Bot (Learning-Friendly)

- [ ] Random move selection with 60% chance
- [ ] Block immediate wins 75% of the time
- [ ] Basic threat recognition (1-step ahead)
- [ ] Makes occasional obvious mistakes for teaching opportunities
- [ ] No long-term strategy planning

#### Step 3.2: Intermediate Bot (Balanced Challenge)

- [ ] Minimax with depth 4-5 moves
- [ ] 90% threat blocking accuracy
- [ ] Basic pattern recognition and formation building
- [ ] Simple positional play preferences
- [ ] Moderate strategic thinking

#### Step 3.3: Advanced Bot (Skilled Player)

- [ ] Minimax with alpha-beta pruning (depth 6-8)
- [ ] 98% threat blocking accuracy
- [ ] Advanced pattern recognition system
- [ ] Multi-step strategy planning
- [ ] Complex tactical combinations

#### Step 3.4: Master Bot (Expert Level)

- [ ] Deep minimax search (depth 10+) with optimizations
- [ ] Perfect threat detection and blocking
- [ ] Machine learning from game history
- [ ] Advanced positional evaluation
- [ ] Counter-strategy development
- [ ] Near-optimal play in most positions

#### Step 3.5: Adaptive Bot (Dynamic Difficulty)

- [ ] **Player Skill Assessment**: Analyze player moves and patterns
- [ ] **Real-time Difficulty Adjustment**: Modify bot strength during gameplay
- [ ] **Performance Tracking**: Monitor win/loss ratios and adjust accordingly
- [ ] **Adaptive Algorithm Selection**: Switch between different AI strategies
- [ ] **Learning Player Preferences**: Adapt to player's style over time
- [ ] **Dynamic Search Depth**: Adjust minimax depth based on player skill
- [ ] **Mistake Injection**: Intentionally make mistakes to balance difficulty
- [ ] **Progressive Challenge**: Gradually increase difficulty as player improves

### Phase 4: Performance Optimization (Week 4-5)

#### Step 4.1: Algorithm Optimization

- [ ] Implement alpha-beta pruning for minimax
- [ ] Add transposition tables for position caching
- [ ] Optimize evaluation functions for infinite grid
- [ ] Implement iterative deepening search

#### Step 4.2: Infinite Grid Adaptations

- [ ] **Bounded Search Areas**: Limit AI search to relevant regions
- [ ] **Dynamic Depth Adjustment**: Vary search depth based on position
- [ ] **Memory Management**: Efficient handling of large game states
- [ ] **Performance Profiling**: Ensure smooth gameplay on all devices

#### Step 4.3: Response Time Management

- [ ] Implement move time limits (1-3 seconds max)
- [ ] Add progressive difficulty ramping
- [ ] Background processing for AI calculations
- [ ] Smooth AI move animations and feedback

### Phase 5: User Experience & Polish (Week 5-6)

#### Step 5.1: UI/UX Improvements

- [ ] Add difficulty selection in menu
- [ ] Implement AI "thinking" indicators
- [ ] Add AI personality traits (aggressive/defensive/balanced)
- [ ] Create AI move prediction visualization

#### Step 5.2: Game Balance & Testing

- [ ] Extensive playtesting for each difficulty level
- [ ] Win rate analysis and balance adjustments
- [ ] Performance testing on various devices
- [ ] User feedback integration and iterative improvements

#### Step 5.3: Analytics & Learning

- [ ] Track AI performance metrics
- [ ] Implement basic machine learning for pattern improvement
- [ ] Add game analysis and move suggestion features
- [ ] Create difficulty auto-adjustment based on player skill
- [ ] **Adaptive Mode Analytics**: Track player skill progression
- [ ] **Real-time Performance Monitoring**: Analyze game flow and difficulty balance

### Phase 6: Advanced Features (Week 6+)

#### Step 6.1: Enhanced Adaptive AI

- [ ] **Advanced Player Skill Assessment**: Multi-dimensional skill evaluation
- [ ] **Dynamic Difficulty Curves**: Smooth transitions between difficulty levels
- [ ] **Learning from Player Patterns**: Adapt to individual playing styles
- [ ] **Personalized AI Opponents**: Create unique AI personalities for each player
- [ ] **Emotional Intelligence**: Respond to player frustration or boredom
- [ ] **Contextual Difficulty**: Adjust based on game situation and player state

#### Step 6.2: AI Personalities

- [ ] **Aggressive**: Focuses on attacking and creating threats
- [ ] **Defensive**: Prioritizes blocking and counter-play
- [ ] **Balanced**: Mix of offensive and defensive strategies
- [ ] **Unpredictable**: Introduces controlled randomness

#### Step 6.3: Tournament Mode

- [ ] AI vs AI battles for testing
- [ ] Player vs multiple AI difficulty progression
- [ ] AI coaching mode with move suggestions
- [ ] Replay system with AI analysis

### Technical Implementation Details

#### Key Files to Modify/Create

```swift
// New files to create:
Components/
├── AI/
│   ├── AIBot.swift              // Base AI class
│   ├── AIBotNovice.swift        // Novice difficulty
│   ├── AIBotIntermediate.swift  // Intermediate difficulty  
│   ├── AIBotAdvanced.swift      // Advanced difficulty
│   ├── AIBotMaster.swift        // Master difficulty
│   ├── AIBotAdaptive.swift      // Adaptive difficulty
│   ├── MoveEvaluator.swift      // Position evaluation
│   ├── PatternRecognizer.swift  // Pattern detection
│   ├── ThreatAnalyzer.swift     // Threat assessment
│   ├── PlayerSkillAssessor.swift // Skill assessment for adaptive mode
│   └── DifficultyManager.swift  // Dynamic difficulty adjustment

// Files to modify:
GameScene.swift                  // AI integration
MenuScene.swift                  // Difficulty selection
GameViewController.swift         // AI mode handling
```

#### Core Algorithms to Implement

1. **Minimax with Alpha-Beta Pruning**
2. **Threat Detection Matrix**
3. **Pattern Recognition Engine**
4. **Position Evaluation Function**
5. **Move Ordering Optimization**
6. **Player Skill Assessment Algorithm**
7. **Dynamic Difficulty Adjustment System**

### Success Metrics

- [ ] **Novice Bot**: 20-35% win rate against average players
- [ ] **Intermediate Bot**: 45-60% win rate against average players  
- [ ] **Advanced Bot**: 70-85% win rate against average players
- [ ] **Master Bot**: 90%+ win rate against average players
- [ ] **Adaptive Bot**: Maintains 50-60% win rate against all player skill levels
- [ ] **Response Time**: All AI moves complete within 2-3 seconds
- [ ] **Memory Usage**: Efficient performance on iPhone 8+ devices
- [ ] **User Satisfaction**: Engaging and appropriately challenging gameplay
- [ ] **Adaptive Accuracy**: Successfully adjusts difficulty within 5-10 moves
- [ ] **Player Retention**: Increased engagement through balanced challenge

### Development Notes

- Leverage existing `ThemeManager` and `SoundManager` for consistency
- Maintain infinite grid performance optimizations
- Follow established animation and UI patterns
- Ensure AI works seamlessly with current two-player mode
- Add comprehensive unit tests for AI algorithms
- Consider future online multiplayer compatibility
- **Adaptive Mode Considerations**: Store player data securely and respect privacy
- **Performance Monitoring**: Ensure adaptive adjustments don't impact game smoothness
- **Fallback Mechanisms**: Handle edge cases when adaptive assessment fails

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
