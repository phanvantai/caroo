# GitHub Copilot Instructions for Caroo Project

## Project Overview
Caroo is an infinite tic-tac-toe iOS game built with Swift and SpriteKit. The game features an unlimited scrollable grid where players need to get 5 in a row to win.

## Key Project Context

### Architecture
- **Framework**: SpriteKit for 2D graphics and game engine
- **Pattern**: MVC with component-based design
- **Platform**: iOS 13.0+ 
- **Language**: Swift 5

### Core Game Logic
- **Grid System**: Infinite scrollable grid using dictionary storage `[String: String]` where key is "row,col"
- **Win Condition**: 5 consecutive marks in any direction (horizontal, vertical, diagonal)
- **Cell Size**: 44pt constant used throughout for grid calculations
- **Coordinate System**: World coordinates with camera-based scrolling

### Main Components

#### GameScene.swift
- Main game logic and rendering
- Handles touch input, scrolling, and mark placement
- Camera-based infinite scrolling with performance optimization
- AI logic for single player mode
- Grid coordinate calculations: `gridKey(row, col) -> "row,col"`

#### MenuScene.swift  
- Main menu with game mode selection
- Theme switching interface
- Animated backgrounds and UI elements

#### ThemeManager.swift
- Singleton pattern for theme management
- Three themes: neon, classic, cosmic
- Persists theme selection to UserDefaults
- Provides colors and styling for entire app

#### Components/
- **SoundManager.swift**: Audio management singleton
- **WinPopup.swift**: Victory celebration UI component

### Coding Patterns & Conventions

#### Performance Optimizations
- **Node Pooling**: Reuse SKNodes to avoid constant allocation
- **Visible Area Rendering**: Only create grid cells in visible camera bounds
- **Batch Updates**: Limit grid updates using time thresholds

#### Coordinate Calculations
```swift
// World to grid conversion
let row = Int(floor(worldY / cellSize))
let col = Int(floor(worldX / cellSize))

// Grid to world conversion  
let worldX = CGFloat(col) * cellSize
let worldY = CGFloat(row) * cellSize
```

#### Theme Integration
- Always use `currentTheme` property from ThemeManager
- Apply theme colors to new UI elements
- Listen for theme change notifications

### Key Methods & Functions

#### Game Logic
- `placeMark(at:col:player:)` - Place X/O on grid with animation
- `checkForWin(at:col:player:)` - Check 5-in-a-row in all directions
- `aiMove()` - Basic AI logic for single player
- `gridKey(_:_:)` - Convert row/col to dictionary key

#### Rendering & UI
- `setupGrid()` - Create visible grid cells and borders
- `updateUIForTheme()` - Apply current theme to UI elements
- `addParticleEffect(at:color:)` - Visual effects for actions

### Common Patterns

#### Node Creation
```swift
// Always set name for easy lookup
node.name = "NodeType-\(identifier)"
node.zPosition = appropriateLayer
```

#### Animation Sequences
```swift
let animation = SKAction.sequence([
    SKAction.scale(to: 1.2, duration: 0.1),
    SKAction.scale(to: 1.0, duration: 0.1)
])
node.run(animation)
```

#### Camera Management
```swift
// Always check camera exists
guard let camera = self.camera else { return }
// Use camera position for world calculations
```

### Development Guidelines

#### When Adding Features
1. Consider theme integration from the start
2. Add appropriate sound effects via SoundManager
3. Use existing animation patterns for consistency
4. Follow the component-based architecture
5. Optimize for performance with large grids

#### Code Style
- Use descriptive variable names
- Add performance comments for complex calculations
- Follow Swift naming conventions
- Use guard statements for early returns
- Prefer computed properties for theme-dependent values

#### Testing Considerations
- Test with different themes
- Verify scrolling performance with large grids
- Test both single player and two player modes
- Check edge cases in win detection algorithm

### Future Enhancements (Roadmap)
- Advanced AI with multiple difficulty levels
- Online multiplayer functionality
- Game statistics and achievements
- Additional themes and customization
- Power-ups and special game modes

## AI Assistant Guidelines
When helping with this project:
1. Always consider the infinite grid nature of the game
2. Maintain performance optimizations for scrolling
3. Integrate new features with the existing theme system
4. Follow the established patterns for animations and UI
5. Consider both single player and multiplayer implications
6. Use the existing component architecture when adding features