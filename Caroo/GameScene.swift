//
//  GameScene.swift
//  Caroo
//
//  Created by Tai Phan Van on 14/1/25.
//

import SpriteKit
import GameplayKit
import AVFoundation

// Add this at the top of the file, after the imports
extension CGPoint {
  static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
  }
}

class GameScene: SKScene {
  
  let cellSize: CGFloat = 44
  
  var grid: [String: String] = [:] // Format: "row,col": player
  var currentPlayer: String = "X"
  var gameEnded = false
  var isSinglePlayer: Bool = true
  
  // MARK: - Enhanced Game State Management
  private var gameState: GameState = .waitingForPlayerMove
  private var lastValidGameState: GameState = .waitingForPlayerMove
  private var moveValidationEnabled: Bool = true
  private var turnLockEnabled: Bool = true
  
  enum GameState: Equatable {
    case waitingForPlayerMove
    case playerMoving
    case waitingForAIMove
    case aiThinking
    case aiMoving
    case gameEnded
    case paused
    case error(String)
    
    var canAcceptPlayerInput: Bool {
      switch self {
      case .waitingForPlayerMove:
        return true
      default:
        return false
      }
    }
    
    var canExecuteAIMove: Bool {
      switch self {
      case .waitingForAIMove, .aiThinking, .aiMoving:
        return true
      default:
        return false
      }
    }
    
    var isGameActive: Bool {
      switch self {
      case .gameEnded, .paused, .error:
        return false
      default:
        return true
      }
    }
  }
  
  // MARK: - AI Properties
  var aiDifficulty: AIDifficulty = .intermediate
  private var aiBot: AIBot?
  private var isAIThinking: Bool = false
  private var aiThinkingIndicator: SKNode?
  private var aiMoveQueue: [AIMove] = []
  private var aiStateHistory: [AIGameState] = []
  
  // UI Theme properties
  private var currentTheme: ThemeManager.Theme {
    return ThemeManager.shared.currentTheme
  }
  private var backgroundGradient: SKShapeNode?
  
  // Add strong reference to camera
  private var cameraNode: SKCameraNode?
  
  // Add new property to track scrolling
  private var isScrolling = false
  
  // Add property to track last camera position
  private var lastCameraPosition: CGPoint = .zero
  
  // Add property to batch node for borders
  private var gridContainer: SKNode?
  
  // Add node pools for recycling
  private var borderNodePool: [SKShapeNode] = []
  private var markNodePool: [SKLabelNode] = []
  
  // Turn tracking for adaptive difficulty
  private var totalTurns = 0
  
  // Add visible rect tracking
  private var lastVisibleRect: CGRect = .zero
  
  // Add these properties at the top of the class
  private var updateThreshold: TimeInterval = 0.3
  private var lastUpdateTime: TimeInterval = 0
  private var isDragging = false
  
  // MARK: - AI Configuration
  
  /// Configure AI difficulty for single player mode
  /// - Parameter difficulty: The desired AI difficulty level
  func configureAI(difficulty: AIDifficulty) {
    aiDifficulty = difficulty
    aiBot = AIBot(difficulty: difficulty, personality: .balanced, playerSymbol: "O")
  }
  
  /// Initialize GameScene with AI difficulty
  /// - Parameters:
  ///   - size: Scene size
  ///   - singlePlayer: Whether this is single player mode
  ///   - aiDifficulty: AI difficulty level (only used if singlePlayer is true)
  convenience init(size: CGSize, singlePlayer: Bool, aiDifficulty: AIDifficulty = .intermediate) {
    self.init(size: size)
    self.isSinglePlayer = singlePlayer
    if singlePlayer {
      configureAI(difficulty: aiDifficulty)
    }
  }
  
  // Add property to track all created nodes
//  private var allCreatedNodes = Set<SKNode>()
//  

  
  override func didMove(to view: SKView) {
    // Set up camera for scrolling
    cameraNode = SKCameraNode()
    if let camera = cameraNode {
        addChild(camera)
        self.camera = camera
        camera.position = CGPoint(x: 0, y: 0)
    }
    
    // Listen for theme changes
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleThemeChange),
        name: .themeDidChange,
        object: nil
    )
    
    // Create container for grid borders
    gridContainer = SKNode()
    if let container = gridContainer {
        addChild(container)
    }
    
    // Set dynamic background based on theme
    backgroundColor = currentTheme.backgroundColor
    
    // Add animated background gradient
    createAnimatedBackground()
    
    setupGrid()
    addThemeButton()
    addTurnIndicator()
    addBackButton()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc private func handleThemeChange() {
    // Update background
    backgroundColor = currentTheme.backgroundColor
    
    // Remove old background elements
    camera?.children.filter { $0.name == "star" }.forEach { $0.removeFromParent() }
    
    // Recreate background if needed
    createAnimatedBackground()
    
    // Update existing UI elements
    updateUIForTheme()
    
    // Refresh grid
    setupGrid()
  }
  
  func addTurnIndicator() {
    let indicator = SKNode()
    indicator.name = "TurnIndicator"
    indicator.position = CGPoint(x: frame.width/2 - 40, y: frame.height/2 - 100) // Below theme button
    indicator.zPosition = 100
    
    // Background
    let background = SKShapeNode(rectOf: CGSize(width: 120, height: 35), cornerRadius: 17.5)
    background.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.3)
    background.strokeColor = currentTheme.gridColor
    background.lineWidth = 1
    background.alpha = 0.8
    
    // Turn text
    let turnText = SKLabelNode(text: getTurnDisplayText())
    turnText.fontName = "AvenirNext-Bold"
    turnText.fontSize = 16
    turnText.fontColor = currentPlayer == "X" ? currentTheme.playerXColor : currentTheme.playerOColor
    turnText.verticalAlignmentMode = .center
    turnText.name = "TurnText"
    
    indicator.addChild(background)
    indicator.addChild(turnText)
    
    camera?.addChild(indicator)
  }
  
  private func getTurnDisplayText() -> String {
    switch gameState {
    case .waitingForPlayerMove:
      return "Turn: \(currentPlayer)"
    case .playerMoving:
      return "\(currentPlayer) Moving..."
    case .waitingForAIMove:
      return "AI Turn"
    case .aiThinking:
      return "AI Thinking..."
    case .aiMoving:
      return "AI Moving..."
    case .gameEnded:
      return "Game Ended"
    case .paused:
      return "Game Paused"
    case .error(let message):
      return "Error: \(message)"
    }
  }
  
  func updateTurnIndicator() {
    if let indicator = camera?.childNode(withName: "TurnIndicator"),
       let turnText = indicator.childNode(withName: "TurnText") as? SKLabelNode {
        turnText.text = getTurnDisplayText()
        turnText.fontColor = currentPlayer == "X" ? currentTheme.playerXColor : currentTheme.playerOColor
        
        // Enhanced animation based on AI state
        if isAIThinking {
            // Add continuous thinking animation
            addAIThinkingAnimation(to: indicator)
        } else {
            // Stop thinking animation and add turn change pulse
            stopAIThinkingAnimation(on: indicator)
            turnText.run(SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
        }
    }
  }
  
  private func addAIThinkingAnimation(to indicator: SKNode) {
    // Remove any existing thinking animations
    indicator.removeAction(forKey: "thinkingAnimation")
    
    if let turnText = indicator.childNode(withName: "TurnText") as? SKLabelNode {
        // Pulsing text animation
        let pulseAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.6),
            SKAction.fadeAlpha(to: 1.0, duration: 0.6)
        ])
        let repeatPulse = SKAction.repeatForever(pulseAction)
        turnText.run(repeatPulse, withKey: "thinkingPulse")
        
        // Add dots animation for thinking
        let addDot = SKAction.run { [weak turnText] in
            guard let text = turnText?.text else { return }
            if text.hasSuffix("...") {
                turnText?.text = "AI Thinking"
            } else {
                turnText?.text = text + "."
            }
        }
        let dotSequence = SKAction.sequence([
            addDot,
            SKAction.wait(forDuration: 0.5)
        ])
        let repeatDots = SKAction.repeatForever(dotSequence)
        indicator.run(repeatDots, withKey: "thinkingDots")
    }
    
    // Add subtle background animation
    if let background = indicator.children.first(where: { $0 is SKShapeNode }) as? SKShapeNode {
        let glowAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.6, duration: 0.8),
            SKAction.fadeAlpha(to: 0.8, duration: 0.8)
        ])
        let repeatGlow = SKAction.repeatForever(glowAction)
        background.run(repeatGlow, withKey: "thinkingGlow")
    }
  }
  
  private func stopAIThinkingAnimation(on indicator: SKNode) {
    // Remove all thinking animations
    indicator.removeAction(forKey: "thinkingAnimation")
    indicator.removeAction(forKey: "thinkingDots")
    
    if let turnText = indicator.childNode(withName: "TurnText") as? SKLabelNode {
        turnText.removeAction(forKey: "thinkingPulse")
        turnText.alpha = 1.0 // Reset alpha
    }
    
    if let background = indicator.children.first(where: { $0 is SKShapeNode }) as? SKShapeNode {
        background.removeAction(forKey: "thinkingGlow")
        background.alpha = 0.8 // Reset to normal
    }
  }
  
  func createAnimatedBackground() {
    // Create animated background particles for cosmic theme
    if currentTheme == .cosmic {
      for _ in 0..<50 {
        let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...2.0))
        star.fillColor = .white
        star.alpha = CGFloat.random(in: 0.3...0.8)
        star.position = CGPoint(
          x: CGFloat.random(in: -frame.width...frame.width),
          y: CGFloat.random(in: -frame.height...frame.height)
        )
        star.zPosition = -100
        
        let twinkle = SKAction.sequence([
          SKAction.fadeAlpha(to: 0.2, duration: Double.random(in: 1...3)),
          SKAction.fadeAlpha(to: 0.8, duration: Double.random(in: 1...3))
        ])
        star.run(SKAction.repeatForever(twinkle))
        
        camera?.addChild(star)
      }
    }
  }
  
  func addThemeButton() {
    let themeButton = SKNode()
    themeButton.name = "ThemeButton"
    themeButton.position = CGPoint(x: frame.width/2 - 40, y: frame.height/2 - 40) // Top-right corner
    themeButton.zPosition = 100
    
    let background = SKShapeNode(circleOfRadius: 20)
    background.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.3)
    background.strokeColor = currentTheme.playerOColor
    background.lineWidth = 1
    background.name = "ThemeButton"
    
    let icon = SKLabelNode(text: "🎨")
    icon.fontSize = 25
    icon.verticalAlignmentMode = .center
    icon.horizontalAlignmentMode = .center
    icon.name = "ThemeButton"
    
    themeButton.addChild(background)
    themeButton.addChild(icon)
    
    let rotation = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 4.0)
    background.run(SKAction.repeatForever(rotation))
    
    camera?.addChild(themeButton)
  }
  
  func addBackButton() {
    let backButton = SKNode()
    backButton.name = "BackButton"
    backButton.position = CGPoint(x: -frame.width/2 + 40, y: frame.height/2 - 40) // Top-left corner like nav bar
    backButton.zPosition = 100
    
    // Create a simple circular background
    let background = SKShapeNode(circleOfRadius: 20)
    background.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.3)
    background.strokeColor = UIColor(white: 1.0, alpha: 0.3)
    background.lineWidth = 1
    background.name = "BackButton"
    
    // Create back arrow with chevron style - centered
    let chevron = SKLabelNode(text: "‹")
    chevron.fontSize = 28
    chevron.fontName = "AvenirNext-Bold"
    chevron.fontColor = .white
    chevron.verticalAlignmentMode = .center
    chevron.horizontalAlignmentMode = .center
    chevron.position = CGPoint(x: 0, y: 0)
    chevron.name = "BackButton"
    
    backButton.addChild(background)
    backButton.addChild(chevron)
    
    // Add subtle hover effect
    let hover = SKAction.sequence([
        SKAction.fadeAlpha(to: 0.8, duration: 2.0),
        SKAction.fadeAlpha(to: 1.0, duration: 2.0)
    ])
    background.run(SKAction.repeatForever(hover))
    
    camera?.addChild(backButton)
  }
  
  func navigateToMenu() {
    // Create transition effect
    let transition = SKTransition.fade(withDuration: 0.8)
    
    // Create MenuScene
    let menuScene = MenuScene(size: self.size)
    menuScene.scaleMode = .aspectFill
    
    // Present the menu scene
    self.view?.presentScene(menuScene, transition: transition)
  }
  
  override func update(_ currentTime: TimeInterval) {
    guard let camera = camera,
          isDragging else { return }
    
    // Only update if enough time has passed
    if currentTime - lastUpdateTime > updateThreshold {
        let currentVisibleRect = CGRect(x: camera.position.x - frame.width/2,
                                      y: camera.position.y - frame.height/2,
                                      width: frame.width,
                                      height: frame.height)
        
        // Only update if moved more than two cells
        if abs(currentVisibleRect.minX - lastVisibleRect.minX) > cellSize * 2 ||
           abs(currentVisibleRect.minY - lastVisibleRect.minY) > cellSize * 2 ||
           lastVisibleRect == .zero {
            setupGrid()
            lastVisibleRect = currentVisibleRect
            lastUpdateTime = currentTime
        }
    }
  }
  
  func isNodeVisible(_ position: CGPoint) -> Bool {
    let visibleRect = CGRect(x: camera!.position.x - frame.width / 2,
                             y: camera!.position.y - frame.height / 2,
                             width: frame.width,
                             height: frame.height)
    return visibleRect.contains(position)
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    
    let currentLocation = touch.location(in: self)
    let previousLocation = touch.previousLocation(in: self)
    let delta = CGPoint(x: currentLocation.x - previousLocation.x,
                       y: currentLocation.y - previousLocation.y)
    
    // Move camera in opposite direction of touch movement
    camera?.position.x -= delta.x
    camera?.position.y -= delta.y
    
    isDragging = true
    isScrolling = true
  }
  
  func recycleNode(_ node: SKNode) {
    node.removeFromParent()
    if let borderNode = node as? SKShapeNode {
        borderNodePool.append(borderNode)
    } else if let markNode = node as? SKLabelNode {
        markNodePool.append(markNode)
    }
  }
  
  func getBorderNode() -> SKShapeNode {
    if let node = borderNodePool.popLast() {
        return node
    }
    return createBorderNode()
  }
  
  func getMarkNode() -> SKLabelNode {
    if let node = markNodePool.popLast() {
        return node
    }
    return createMarkNode()
  }
  
  func drawCellBorder(at row: Int, col: Int) -> SKNode {
    let x = CGFloat(col) * cellSize
    let y = CGFloat(row) * cellSize
    
    let cell = SKShapeNode(rect: CGRect(x: x, y: y, width: cellSize, height: cellSize))
    cell.strokeColor = currentTheme.gridColor
    cell.lineWidth = currentTheme == .neon ? 1.0 : 0.8
    cell.fillColor = .clear
    cell.name = "Border-\(row)-\(col)"
    cell.zPosition = -1
    
    // Add glow effect for neon theme
    if currentTheme == .neon {
      cell.glowWidth = 2.0
    }
    
    gridContainer?.addChild(cell)
    return cell
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    isDragging = false
    isScrolling = false
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first,
          let camera = self.camera else { return }
    
    let touchLocation = touch.location(in: camera)
    let touchedNodes = camera.nodes(at: touchLocation)
    
    for node in touchedNodes {
        if node.name == "ThemeButton" || node.parent?.name == "ThemeButton" {
            // Don't allow theme button interaction when game has ended
            if gameEnded { return }
            
            // Handle theme switching
            let buttonContainer = node.name == "ThemeButton" ? (node.parent ?? node) : node.parent!
            
            // Add press animation
            buttonContainer.run(SKAction.sequence([
                SKAction.scale(to: 0.8, duration: 0.1),
                SKAction.scale(to: 1.2, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
            
            // Play theme switch sound
            SoundManager.shared.playThemeSwitchSound()
            
            switchTheme()
            return
        } else if node.name == "PopupRestartButton" || node.parent?.name == "PopupRestartButton" {
            // Find the WinPopup node by traversing up the node tree
            var currentNode = node
            while currentNode.parent != nil && !(currentNode.parent is WinPopup) {
                currentNode = currentNode.parent!
            }
            
            if let popup = currentNode.parent as? WinPopup {
                // Enhanced dismiss animation
                let dismissSequence = SKAction.group([
                    SKAction.scale(to: 0.3, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.rotate(byAngle: CGFloat.pi, duration: 0.3)
                ])
                
                popup.run(SKAction.sequence([
                    dismissSequence,
                    SKAction.removeFromParent()
                ]))
                
                restartGame()
            }
            return
        } else if node.name == "BackButton" || node.parent?.name == "BackButton" {
            // Don't allow back button interaction when game has ended
            if gameEnded { return }
            
            // Handle back button press
            let buttonContainer = node.name == "BackButton" ? (node.parent ?? node) : node.parent!
            
            // Add press animation
            buttonContainer.run(SKAction.sequence([
                SKAction.scale(to: 0.8, duration: 0.1),
                SKAction.scale(to: 1.2, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
            
            // Play back sound
            SoundManager.shared.playButtonSound()
            
            // Navigate back to menu
            navigateToMenu()
            return
        }
    }
    
    // Enhanced move validation with state management
    if !isScrolling {
        let location = touch.location(in: self)
        
        // Convert touch location to world coordinates using camera position
        let worldX = location.x + camera.position.x
        let worldY = location.y + camera.position.y
        
        // Calculate grid position from world coordinates
        let row = Int(floor((worldY - camera.position.y) / cellSize))
        let col = Int(floor((worldX - camera.position.x) / cellSize))
        
        // Enhanced move validation
        let validation = canPlaceMove(at: row, col: col, by: currentPlayer)
        if !validation.canPlace {
            #if DEBUG
            print("🚫 Move rejected: \(validation.reason)")
            #endif
            return
        }
        
        // Update state to indicate player is making a move
        updateGameState(to: .playerMoving, reason: "Player placing move at (\(row), \(col))")
        
        // Place the move
        executePlayerMove(at: row, col: col)
    }
    
    // Reset scrolling flag
    isScrolling = false
  }
  
  /// Execute a player move with enhanced state management
  private func executePlayerMove(at row: Int, col: Int) {
    let key = gridKey(row, col)
    let player = currentPlayer
    
    // Place the move in the grid
    grid[key] = player
    let markNode = placeMark(at: row, col: col, player: player)
    
    // Increment turn counter
    totalTurns += 1
    
    // Play sound effect
    SoundManager.shared.playPlaceMarkSound()
    
    // Add placement animation
    markNode.setScale(0)
    markNode.run(SKAction.sequence([
        SKAction.scale(to: 1.3, duration: 0.2),
        SKAction.scale(to: 1.0, duration: 0.1)
    ])) { [weak self] in
        // Animation complete, check for win
        self?.completePlayerMove(at: row, col: col, player: player)
    }
    
    // Add particle effect
    addParticleEffect(at: markNode.position, color: player == "X" ? currentTheme.playerXColor : currentTheme.playerOColor)
  }
  
  /// Complete player move processing after animation
  private func completePlayerMove(at row: Int, col: Int, player: String) {
    // Check for win condition
    if checkForWin(at: row, col: col, player: player) {
        updateGameState(to: .gameEnded, reason: "Player \(player) won")
        showWinAlert(for: player)
        return
    }
    
    // Switch players
    currentPlayer = (currentPlayer == "X") ? "O" : "X"
    
    // Determine next game state
    if isSinglePlayer && currentPlayer == "O" {
        updateGameState(to: .waitingForAIMove, reason: "AI turn after player move")
    } else {
        updateGameState(to: .waitingForPlayerMove, reason: "Next player's turn")
    }
    
    updateTurnIndicator()
  }
  
  func switchTheme() {
    ThemeManager.shared.switchToNextTheme()
  }
  
  func updateUIForTheme() {
    // Update theme button colors
    if let themeButton = camera?.childNode(withName: "ThemeButton") {
        for child in themeButton.children {
            if let shapeNode = child as? SKShapeNode, child.name == "ThemeButton" {
                shapeNode.fillColor = currentTheme.playerOColor
            }
        }
    }
    
    // Update turn indicator
    if let indicator = camera?.childNode(withName: "TurnIndicator") {
        for child in indicator.children {
            if let shapeNode = child as? SKShapeNode {
                shapeNode.strokeColor = currentTheme.gridColor
            } else if let labelNode = child as? SKLabelNode, child.name == "TurnText" {
                labelNode.text = getTurnDisplayText()
                labelNode.fontColor = currentPlayer == "X" ? currentTheme.playerXColor : currentTheme.playerOColor
            }
        }
    }
    
    // Update existing marks on the grid
    updateExistingMarks()
  }
  
  func updateExistingMarks() {
    // Iterate through all existing marks and update their colors
    for (key, player) in grid {
        let components = key.split(separator: ",")
        let row = Int(components[0])!
        let col = Int(components[1])!
        
        if let markNode = childNode(withName: "Cell-\(row)-\(col)") {
            // Update the mark colors based on current theme
            for child in markNode.children {
                if let shapeNode = child as? SKShapeNode {
                    if player == "X" {
                        shapeNode.strokeColor = currentTheme.playerXColor
                        // Update glow effect for neon theme
                        if currentTheme == .neon {
                            shapeNode.glowWidth = 4
                        } else {
                            shapeNode.glowWidth = 0
                        }
                    } else if player == "O" {
                        shapeNode.strokeColor = currentTheme.playerOColor
                        // Update glow effect for neon theme
                        if currentTheme == .neon {
                            shapeNode.glowWidth = 4
                        } else {
                            shapeNode.glowWidth = 0
                        }
                    }
                }
            }
        }
    }
  }
  
  func addParticleEffect(at position: CGPoint, color: UIColor) {
    for _ in 0..<8 {
        let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3))
        particle.fillColor = color
        particle.position = position
        particle.zPosition = 50
        
        let randomDirection = CGVector(
            dx: CGFloat.random(in: -100...100),
            dy: CGFloat.random(in: -100...100)
        )
        
        let moveAction = SKAction.move(by: randomDirection, duration: 0.8)
        let fadeAction = SKAction.fadeOut(withDuration: 0.8)
        let scaleAction = SKAction.scale(to: 0, duration: 0.8)
        
        particle.run(SKAction.group([moveAction, fadeAction, scaleAction])) {
            particle.removeFromParent()
        }
        
        addChild(particle)
    }
  }
  
  // MARK: - Enhanced Game State Management Methods
  
  /// Update game state with validation and logging
  private func updateGameState(to newState: GameState, reason: String = "") {
    let previousState = gameState
    lastValidGameState = gameState
    gameState = newState
    
    // Debug logging for state transitions
    #if DEBUG
    print("🎮 Game State: \(previousState) -> \(newState) | Reason: \(reason)")
    #endif
    
    // Handle state-specific logic
    handleGameStateTransition(from: previousState, to: newState)
    
    // Validate state consistency
    validateGameState()
  }
  
  /// Handle logic that should run when transitioning between states
  private func handleGameStateTransition(from oldState: GameState, to newState: GameState) {
    switch newState {
    case .waitingForPlayerMove:
      // Enable player input
      turnLockEnabled = false
      
    case .playerMoving:
      // Disable input during player move processing
      turnLockEnabled = true
      
    case .waitingForAIMove:
      // Setup for AI move
      if isSinglePlayer && currentPlayer == "O" {
        scheduleAIMove()
      }
      
    case .aiThinking:
      // Update UI to show AI thinking
      isAIThinking = true
      updateTurnIndicator()
      
    case .aiMoving:
      // AI is executing move
      break
      
    case .gameEnded:
      // Game over state
      turnLockEnabled = true
      isAIThinking = false
      gameEnded = true
      
    case .paused:
      // Game paused state
      turnLockEnabled = true
      
    case .error(let message):
      // Handle error state
      handleGameError(message)
    }
  }
  
  /// Validate current game state for consistency
  private func validateGameState() {
    guard moveValidationEnabled else { return }
    
    // Check for inconsistent states
    if gameState.isGameActive && gameEnded {
      updateGameState(to: .error("Game state inconsistency: active state but game marked as ended"))
      return
    }
    
    if gameState == .aiThinking && !isSinglePlayer {
      updateGameState(to: .error("AI thinking in multiplayer mode"))
      return
    }
    
    if gameState == .waitingForAIMove && currentPlayer != "O" {
      updateGameState(to: .error("Waiting for AI move but current player is not O"))
      return
    }
    
    // Validate AI state consistency
    if isSinglePlayer && gameState.canExecuteAIMove && aiBot == nil {
      updateGameState(to: .error("AI bot not initialized in single player mode"))
      return
    }
  }
  
  /// Handle game errors
  private func handleGameError(_ message: String) {
    #if DEBUG
    print("❌ Game Error: \(message)")
    #endif
    
    // Try to recover to last valid state
    gameState = lastValidGameState
    
    // If recovery fails, reset to safe state
    if !gameState.isGameActive {
      resetToSafeState()
    }
  }
  
  /// Reset game to a safe, known state
  private func resetToSafeState() {
    gameState = .waitingForPlayerMove
    isAIThinking = false
    turnLockEnabled = false
    
    // Update UI to reflect safe state
    updateTurnIndicator()
  }
  
  /// Schedule AI move with state management
  private func scheduleAIMove() {
    guard isSinglePlayer && currentPlayer == "O" && !gameEnded else {
      updateGameState(to: .error("Invalid conditions for AI move"))
      return
    }
    
    updateGameState(to: .aiThinking, reason: "AI turn started")
    
    // Use existing performAIMove with state integration
    performAIMove()
  }
  
  /// Enhanced move validation with state checking
  private func canPlaceMove(at row: Int, col: Int, by player: String) -> (canPlace: Bool, reason: String) {
    // Check game state
    if !gameState.canAcceptPlayerInput {
      return (false, "Game state does not allow player input")
    }
    
    // Check if game has ended
    if gameEnded {
      return (false, "Game has ended")
    }
    
    // Check if cell is occupied
    let key = gridKey(row, col)
    if grid[key] != nil {
      return (false, "Cell already occupied")
    }
    
    // Check if it's the correct player's turn
    if player != currentPlayer {
      return (false, "Not \(player)'s turn")
    }
    
    // Check single player mode restrictions
    if isSinglePlayer && currentPlayer != "X" {
      return (false, "Only human player can make moves in single player mode")
    }
    
    // Check if AI is thinking
    if isAIThinking {
      return (false, "AI is currently thinking")
    }
    
    return (true, "Move is valid")
  }
  
  /// AI-specific move validation
  private func canPlaceAIMove(at row: Int, col: Int, by player: String) -> (canPlace: Bool, reason: String) {
    // Check if game has ended
    if gameEnded {
      return (false, "Game has ended")
    }
    
    // Check if cell is occupied
    let key = gridKey(row, col)
    if grid[key] != nil {
      return (false, "Cell already occupied")
    }
    
    // Check if it's the correct player's turn
    if player != currentPlayer {
      return (false, "Not \(player)'s turn")
    }
    
    // Check single player mode - AI should only move as "O"
    if isSinglePlayer && player != "O" {
      return (false, "AI can only play as O in single player mode")
    }
    
    // Check if we're in a valid AI move state
    if !gameState.canExecuteAIMove && gameState != .aiMoving {
      return (false, "Game state does not allow AI moves")
    }
    
    return (true, "AI move is valid")
  }
  
  /// Enhanced AI state tracking
  private func trackAIState(_ move: AIMove, gameState: AIGameState) {
    // Add to move queue for potential rollback
    aiMoveQueue.append(move)
    
    // Keep move queue size manageable
    if aiMoveQueue.count > 10 {
      aiMoveQueue.removeFirst()
    }
    
    // Track game state history
    aiStateHistory.append(gameState)
    
    // Keep history size manageable
    if aiStateHistory.count > 20 {
      aiStateHistory.removeFirst()
    }
  }
  
  /// Get current game state validation summary
  private func getGameStateValidation() -> (isValid: Bool, issues: [String]) {
    var issues: [String] = []
    
    // Check basic consistency
    if gameState.isGameActive && gameEnded {
      issues.append("Game state active but game marked as ended")
    }
    
    if isAIThinking && !isSinglePlayer {
      issues.append("AI thinking in multiplayer mode")
    }
    
    if currentPlayer != "X" && currentPlayer != "O" {
      issues.append("Invalid current player: \(currentPlayer)")
    }
    
    if isSinglePlayer && aiBot == nil {
      issues.append("Single player mode but no AI bot")
    }
    
    // Check AI-specific issues
    if gameState == .aiThinking && !isAIThinking {
      issues.append("State is aiThinking but isAIThinking is false")
    }
    
    if gameState.canExecuteAIMove && !isSinglePlayer {
      issues.append("State allows AI move but not in single player mode")
    }
    
    return (issues.isEmpty, issues)
  }
  
  // MARK: - Game State Monitoring and Recovery
  
  /// Monitor game state for inconsistencies and auto-recovery
  private func monitorGameState() {
    let validation = getGameStateValidation()
    
    if !validation.isValid {
      #if DEBUG
      print("⚠️ Game state validation failed: \(validation.issues)")
      #endif
      
      // Attempt automatic recovery
      attemptGameStateRecovery(issues: validation.issues)
    }
  }
  
  /// Attempt to automatically recover from game state issues
  private func attemptGameStateRecovery(issues: [String]) {
    var recoverySuccess = true
    
    for issue in issues {
      switch issue {
      case let issue where issue.contains("AI thinking in multiplayer"):
        isAIThinking = false
        updateGameState(to: .waitingForPlayerMove, reason: "Recovery: Fixed AI thinking in multiplayer")
        
      case let issue where issue.contains("State is aiThinking but isAIThinking is false"):
        isAIThinking = true
        updateTurnIndicator()
        
      case let issue where issue.contains("Invalid current player"):
        currentPlayer = totalTurns % 2 == 0 ? "X" : "O"
        updateTurnIndicator()
        
      case let issue where issue.contains("Game state active but game marked as ended"):
        if gameEnded {
          updateGameState(to: .gameEnded, reason: "Recovery: Sync state with gameEnded flag")
        } else {
          updateGameState(to: .waitingForPlayerMove, reason: "Recovery: Reset to active state")
        }
        
      default:
        recoverySuccess = false
        #if DEBUG
        print("❌ Cannot auto-recover from: \(issue)")
        #endif
      }
    }
    
    if !recoverySuccess {
      // Last resort: reset to safe state
      resetToSafeState()
    }
  }
  
  /// Enhanced pause functionality with state management
  func pauseGame() {
    guard gameState.isGameActive else { return }
    
    lastValidGameState = gameState
    updateGameState(to: .paused, reason: "Game paused by user")
    
    // Stop any ongoing AI operations
    if isAIThinking {
      removeAllActions()
      isAIThinking = false
    }
    
    updateTurnIndicator()
  }
  
  /// Resume game from paused state
  func resumeGame() {
    guard gameState == .paused else { return }
    
    updateGameState(to: lastValidGameState, reason: "Game resumed")
    
    // If it was AI's turn, restart AI thinking
    if isSinglePlayer && currentPlayer == "O" && gameState == .waitingForAIMove {
      scheduleAIMove()
    }
    
    updateTurnIndicator()
  }
  
  /// Debug method to print current game state
  func debugPrintGameState() {
    #if DEBUG
    print("=== GAME STATE DEBUG ===")
    print("Current State: \(gameState)")
    print("Last Valid State: \(lastValidGameState)")
    print("Current Player: \(currentPlayer)")
    print("Game Ended: \(gameEnded)")
    print("AI Thinking: \(isAIThinking)")
    print("Turn Lock: \(turnLockEnabled)")
    print("Single Player: \(isSinglePlayer)")
    print("Total Turns: \(totalTurns)")
    print("AI Move Queue: \(aiMoveQueue.count) moves")
    print("AI State History: \(aiStateHistory.count) states")
    
    let validation = getGameStateValidation()
    print("State Valid: \(validation.isValid)")
    if !validation.isValid {
      print("Issues: \(validation.issues)")
    }
    print("========================")
    #endif
  }
  
  func restartGame() {
    // Reset core game data
    grid.removeAll()
    totalTurns = 0
    currentPlayer = "X"
    gameEnded = false
    
    // Reset AI state
    isAIThinking = false
    aiMoveQueue.removeAll()
    aiStateHistory.removeAll()
    aiBot?.resetState()
    
    // Reset game state management
    updateGameState(to: .waitingForPlayerMove, reason: "Game restarted")
    lastValidGameState = .waitingForPlayerMove
    moveValidationEnabled = true
    turnLockEnabled = false
    
    // Remove all nodes except camera and its children
    children.forEach { node in
        if node != camera {
            node.removeFromParent()
        }
    }
    
    // Clear camera children except UI elements
    camera?.children.forEach { node in
        if node.name != "ThemeButton" && node.name != "BackButton" {
            node.removeFromParent()
        }
    }
    
    // Re-create grid container
    gridContainer = SKNode()
    if let container = gridContainer {
        addChild(container)
    }
    
    // Recreate background
    backgroundColor = currentTheme.backgroundColor
    createAnimatedBackground()
    
    setupGrid()
    lastVisibleRect = .zero  // Reset last visible rect to force grid update
    
    // Recreate turn indicator
    addTurnIndicator()
    
    // Play restart sound
    SoundManager.shared.playButtonSound()
    
    #if DEBUG
    print("🔄 Game restarted successfully")
    #endif
  }
  
  func placeMark(at row: Int, col: Int, player: String) -> SKNode {
    if player.isEmpty { return SKNode() }
    
    let x = CGFloat(col) * cellSize
    let y = CGFloat(row) * cellSize
    
    // Create custom mark shapes instead of text
    let markContainer = SKNode()
    markContainer.position = CGPoint(x: x + cellSize/2, y: y + cellSize/2)
    markContainer.name = "Cell-\(row)-\(col)"
    
    if player == "X" {
        // Create custom X shape with two lines
        let line1 = SKShapeNode()
        let path1 = CGMutablePath()
        path1.move(to: CGPoint(x: -cellSize/3, y: -cellSize/3))
        path1.addLine(to: CGPoint(x: cellSize/3, y: cellSize/3))
        line1.path = path1
        line1.strokeColor = currentTheme.playerXColor
        line1.lineWidth = 4
        line1.lineCap = .round
        
        let line2 = SKShapeNode()
        let path2 = CGMutablePath()
        path2.move(to: CGPoint(x: cellSize/3, y: -cellSize/3))
        path2.addLine(to: CGPoint(x: -cellSize/3, y: cellSize/3))
        line2.path = path2
        line2.strokeColor = currentTheme.playerXColor
        line2.lineWidth = 4
        line2.lineCap = .round
        
        // Add glow effect for neon theme
        if currentTheme == .neon {
            line1.glowWidth = 4
            line2.glowWidth = 4
        }
        
        markContainer.addChild(line1)
        markContainer.addChild(line2)
        
    } else if player == "O" {
        // Create custom O shape with circle
        let circle = SKShapeNode(circleOfRadius: cellSize/3)
        circle.strokeColor = currentTheme.playerOColor
        circle.fillColor = .clear
        circle.lineWidth = 4
        
        // Add glow effect for neon theme
        if currentTheme == .neon {
            circle.glowWidth = 4
        }
        
        markContainer.addChild(circle)
    }
    
    addChild(markContainer)
    return markContainer
  }
  
  // MARK: - Check for win
  func checkForWin(at row: Int, col: Int, player: String) -> Bool {
    let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
    
    for direction in directions {
        var count = 1
        var winningCells: [(Int, Int)] = [(row, col)]
        
        // Check both directions
        for multiplier in [-1, 1] {
            var r = row + direction.0 * multiplier
            var c = col + direction.1 * multiplier
            
            while grid[gridKey(r, c)] == player {
                winningCells.append((r, c))
                count += 1
                r += direction.0 * multiplier
                c += direction.1 * multiplier
            }
        }
        
        if count >= 5 {
            highlightWinningLine(cells: winningCells)
            return true
        }
    }
    
    return false
  }
  
  func highlightWinningLine(cells: [(Int, Int)]) {
    // Add screen shake effect
    let shakeAmount: CGFloat = 10
    let shakeAction = SKAction.sequence([
        SKAction.moveBy(x: shakeAmount, y: 0, duration: 0.05),
        SKAction.moveBy(x: -shakeAmount * 2, y: 0, duration: 0.05),
        SKAction.moveBy(x: shakeAmount, y: 0, duration: 0.05)
    ])
    camera?.run(SKAction.repeat(shakeAction, count: 3))
    
    // Highlight winning cells with enhanced effects
    for (row, col) in cells {
      if let cellNode = childNode(withName: "Cell-\(row)-\(col)") {
        // Change color to gold/winner color
        for child in cellNode.children {
            if let shapeNode = child as? SKShapeNode {
                let originalColor = shapeNode.strokeColor
                
                // Flash effect
                let flashAction = SKAction.sequence([
                    SKAction.run { shapeNode.strokeColor = .systemYellow },
                    SKAction.wait(forDuration: 0.2),
                    SKAction.run { shapeNode.strokeColor = originalColor },
                    SKAction.wait(forDuration: 0.2)
                ])
                
                shapeNode.run(SKAction.repeat(flashAction, count: 3))
                
                // Add glow effect
                if currentTheme == .neon {
                    shapeNode.glowWidth = 8
                }
            }
        }
        
        // Add victory particles around winning line
        addVictoryParticles(at: cellNode.position)
      }
    }
  }
  
  func addVictoryParticles(at position: CGPoint) {
    for _ in 0..<15 {
        let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
        particle.fillColor = .systemYellow
        particle.position = position
        particle.zPosition = 100
        
        let randomDirection = CGVector(
            dx: CGFloat.random(in: -150...150),
            dy: CGFloat.random(in: -150...150)
        )
        
        let moveAction = SKAction.move(by: randomDirection, duration: 1.5)
        let fadeAction = SKAction.fadeOut(withDuration: 1.5)
        let scaleAction = SKAction.sequence([
            SKAction.scale(to: 1.5, duration: 0.3),
            SKAction.scale(to: 0, duration: 1.2)
        ])
        
        particle.run(SKAction.group([moveAction, fadeAction, scaleAction])) {
            particle.removeFromParent()
        }
        
        addChild(particle)
    }
  }
  
  func showWinAlert(for player: String) {
    // Update game state first
    updateGameState(to: .gameEnded, reason: "Player \(player) won")
    
    // Play win sound effect
    SoundManager.shared.playWinSound()
    
    let popup = WinPopup(size: self.size, winner: player, theme: currentTheme)
    popup.zPosition = 1000
    camera?.addChild(popup)
    
    // Add celebration particle burst
    addCelebrationEffect()
    
    #if DEBUG
    print("🎉 Game ended: Player \(player) wins!")
    let validation = getGameStateValidation()
    if !validation.isValid {
        print("⚠️ Game state validation issues: \(validation.issues)")
    }
    #endif
  }
  
  func addCelebrationEffect() {
    guard let camera = camera else { return }
    
    // Create firework-like celebration effect
    for _ in 0..<30 {
        let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...6))
        particle.fillColor = [currentTheme.playerXColor, currentTheme.playerOColor, .systemYellow].randomElement()!
        particle.position = CGPoint(x: 0, y: 0) // Center of screen
        particle.zPosition = 200
        
        let randomAngle = CGFloat.random(in: 0...CGFloat.pi * 2)
        let randomDistance = CGFloat.random(in: 200...400)
        let direction = CGVector(
            dx: cos(randomAngle) * randomDistance,
            dy: sin(randomAngle) * randomDistance
        )
        
        let moveAction = SKAction.move(by: direction, duration: 2.0)
        let fadeAction = SKAction.fadeOut(withDuration: 2.0)
        let scaleAction = SKAction.sequence([
            SKAction.scale(to: 1.5, duration: 0.5),
            SKAction.scale(to: 0, duration: 1.5)
        ])
        
        particle.run(SKAction.group([moveAction, fadeAction, scaleAction])) {
            particle.removeFromParent()
        }
        
        camera.addChild(particle)
    }
  }
  
  func gridKey(_ row: Int, _ col: Int) -> String {
    return "\(row),\(col)"
  }
  
  func setupGrid() {
    guard let camera = camera else { return }
    
    let visibleWidth = frame.width
    let visibleHeight = frame.height
    
    // Increase buffer zone
    let bufferMultiplier: CGFloat = 6.0
    let startX = Int((camera.position.x - visibleWidth/2 - cellSize * bufferMultiplier) / cellSize)
    let endX = Int((camera.position.x + visibleWidth/2 + cellSize * bufferMultiplier) / cellSize)
    let startY = Int((camera.position.y - visibleHeight/2 - cellSize * bufferMultiplier) / cellSize)
    let endY = Int((camera.position.y + visibleHeight/2 + cellSize * bufferMultiplier) / cellSize)
    
    // Create sets for existing nodes
    let existingBorders = Set(gridContainer?.children.compactMap { $0.name } ?? [])
    let existingCells = Set(children.compactMap { $0.name }.filter { $0.hasPrefix("Cell-") })
    
    // Create set for needed nodes
    var neededNodes = Set<String>()
    
    // First pass: collect needed nodes
    for row in startY...endY {
        for col in startX...endX {
            let cellKey = "Cell-\(row)-\(col)"
            let borderKey = "Border-\(row)-\(col)"
            neededNodes.insert(cellKey)
            neededNodes.insert(borderKey)
        }
    }
    
    // Remove unnecessary nodes
    for borderName in existingBorders where !neededNodes.contains(borderName) {
        gridContainer?.childNode(withName: borderName)?.removeFromParent()
    }
    
    for cellName in existingCells where !neededNodes.contains(cellName) {
        childNode(withName: cellName)?.removeFromParent()
    }
    
    // Add only necessary new nodes
    for row in startY...endY {
        for col in startX...endX {
            let cellKey = "Cell-\(row)-\(col)"
            let borderKey = "Border-\(row)-\(col)"
            
            if !existingCells.contains(cellKey) {
                let key = gridKey(row, col)
                if let player = grid[key] {
                    _ = placeMark(at: row, col: col, player: player)
                }
            }
            
            if !existingBorders.contains(borderKey) {
                _ = drawCellBorder(at: row, col: col)
            }
        }
    }
  }
  
  // Helper methods to create nodes without adding them immediately
  private func createMark(at row: Int, col: Int, player: String) -> SKNode {
    let x = CGFloat(col) * cellSize
    let y = CGFloat(row) * cellSize
    
    let label = getMarkNode()
    label.text = player
    label.position = CGPoint(x: x + cellSize/2, y: y + cellSize/2)
    label.name = "Cell-\(row)-\(col)"
    return label
  }
  
  private func createBorder(at row: Int, col: Int) -> SKNode {
    let x = CGFloat(col) * cellSize
    let y = CGFloat(row) * cellSize
    
    let cell = getBorderNode()
    cell.path = CGPath(rect: CGRect(x: x, y: y, width: cellSize, height: cellSize), transform: nil)
    cell.name = "Border-\(row)-\(col)"
    return cell
  }
  
  private func createBorderNode() -> SKShapeNode {
    let node = SKShapeNode()
    node.strokeColor = currentTheme.gridColor
    node.lineWidth = currentTheme == .neon ? 1.0 : 0.8
    node.zPosition = -1
    
    if currentTheme == .neon {
        node.glowWidth = 2.0
    }
    
    return node
  }
  
  private func createMarkNode() -> SKLabelNode {
    let node = SKLabelNode()
    node.fontName = "Arial-BoldMT"
    node.fontSize = cellSize * 0.8
    node.fontColor = .black
    node.verticalAlignmentMode = .center
    node.horizontalAlignmentMode = .center
    return node
  }
  
  // MARK: - Enhanced AI Move Logic
  
  private func performAIMove() {
    guard aiBot != nil else {
        updateGameState(to: .error("AI bot not available"))
        return
    }
    
    // Validate we can execute AI move
    if !gameState.canExecuteAIMove {
        updateGameState(to: .error("Invalid state for AI move: \(gameState)"))
        return
    }
    
    if gameEnded {
        updateGameState(to: .error("Cannot execute AI move: game has ended"))
        return
    }
    
    // Update state and UI
    updateGameState(to: .aiThinking, reason: "AI starting to calculate move")
    
    // Play thinking sound effect
    playAIThinkingSound()
    
    // Add dynamic thinking delay based on difficulty and game situation
    let thinkingDelay = getAIThinkingDelay()
    
    let delayAction = SKAction.wait(forDuration: thinkingDelay)
    let moveAction = SKAction.run { [weak self] in
      self?.executeAIMove()
    }
    
    run(SKAction.sequence([delayAction, moveAction]))
  }
  
  private func playAIThinkingSound() {
    // Play a subtle thinking sound - we can add this to SoundManager later
    // For now, we'll just use the existing button sound with lower volume
    SoundManager.shared.playButtonSound()
  }
  
  private func getAIThinkingDelay() -> TimeInterval {
    // Base delay varies by difficulty
    let baseDelay: TimeInterval
    switch aiDifficulty {
    case .novice:
      baseDelay = TimeInterval.random(in: 0.5...1.0)
    case .intermediate:
      baseDelay = TimeInterval.random(in: 0.8...1.5)
    case .advanced:
      baseDelay = TimeInterval.random(in: 1.0...2.0)
    case .master:
      baseDelay = TimeInterval.random(in: 1.5...2.5)
    case .adaptive:
      baseDelay = TimeInterval.random(in: 0.8...1.8)
    }
    
    // Adjust delay based on game situation for more realistic AI behavior
    var adjustedDelay = baseDelay
    
    // Longer thinking for critical moves (near wins/blocks)
    if isNearWinSituation() {
        adjustedDelay *= 1.3
    }
    
    // Slightly shorter thinking for early game moves
    if totalTurns < 5 {
        adjustedDelay *= 0.8
    }
    
    // Ensure minimum and maximum bounds
    return max(0.5, min(adjustedDelay, 3.0))
  }
  
  private func isNearWinSituation() -> Bool {
    // Simple check if there are any 3 or 4 in a row on the board
    for (_, player) in grid {
        for row in -5...5 {
            for col in -5...5 {
                if checkPatternLength(at: row, col: col, player: player) >= 3 {
                    return true
                }
            }
        }
    }
    return false
  }
  
  private func checkPatternLength(at row: Int, col: Int, player: String) -> Int {
    let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
    var maxLength = 0
    
    for direction in directions {
        var count = 0
        var r = row
        var c = col
        
        // Count in positive direction
        while grid[gridKey(r, c)] == player {
            count += 1
            r += direction.0
            c += direction.1
        }
        
        // Count in negative direction (excluding starting position)
        r = row - direction.0
        c = col - direction.1
        while grid[gridKey(r, c)] == player {
            count += 1
            r -= direction.0
            c -= direction.1
        }
        
        maxLength = max(maxLength, count)
    }
    
    return maxLength
  }
  
  private func executeAIMove() {
    guard let aiBot = aiBot else {
        updateGameState(to: .error("AI bot not available during execution"))
        return
    }
    
    if gameEnded {
        updateGameState(to: .error("Cannot execute AI move: game ended during thinking"))
        return
    }
    
    // Update state to indicate AI is now executing move
    updateGameState(to: .aiMoving, reason: "AI executing calculated move")
    
    // Create AI game state
    let currentGameState = AIGameState(
      grid: grid,
      currentPlayer: "O",
      opponentPlayer: "X",
      totalMoves: totalTurns,
      gamePhase: determineGamePhase()
    )
    
    // Calculate AI move
    if let aiMove = aiBot.calculateBestMove(for: currentGameState, timeLimit: 2.0) {
      // Validate the AI move using AI-specific validation
      let validation = canPlaceAIMove(at: aiMove.row, col: aiMove.col, by: "O")
      if !validation.canPlace {
        updateGameState(to: .error("AI calculated invalid move: \(validation.reason)"))
        return
      }
      
      // Track AI state for debugging
      trackAIState(aiMove, gameState: currentGameState)
      
      // Execute the AI move
      executeValidatedAIMove(aiMove, gameState: currentGameState)
    } else {
      updateGameState(to: .error("AI failed to calculate a move"))
    }
  }
  
  /// Execute a validated AI move
  private func executeValidatedAIMove(_ aiMove: AIMove, gameState: AIGameState) {
    let key = aiMove.gridKey
    
    // Place the AI move in grid
    grid[key] = "O"
    
    // Calculate world position for the AI move
    let worldX = CGFloat(aiMove.col) * cellSize
    let worldY = CGFloat(aiMove.row) * cellSize
    let movePosition = CGPoint(x: worldX, y: worldY)
    
    // Add anticipation effect before placing mark
    addAIAnticipationEffect(at: movePosition) { [weak self] in
      guard let self = self else { return }
      
      // Place the mark with enhanced animation
      let markNode = self.placeMark(at: aiMove.row, col: aiMove.col, player: "O")
      
      // Increment turn counter
      self.totalTurns += 1
      
      // Enhanced AI move animation sequence
      self.performAIMoveAnimation(markNode: markNode, position: movePosition) { [weak self] in
        guard let self = self else { return }
        
        // Update AI bot state
        self.aiBot?.updateState(with: aiMove, gameState: gameState)
        
        // Complete AI move processing
        self.completeAIMove(aiMove: aiMove)
      }
    }
  }
  
  /// Complete AI move processing
  private func completeAIMove(aiMove: AIMove) {
    // Check for AI win
    if checkForWin(at: aiMove.row, col: aiMove.col, player: "O") {
        updateGameState(to: .gameEnded, reason: "AI won the game")
        showWinAlert(for: "O")
        return
    }
    
    // Reset AI thinking state
    isAIThinking = false
    
    // Switch back to human player
    currentPlayer = "X"
    updateGameState(to: .waitingForPlayerMove, reason: "AI move completed, player's turn")
    updateTurnIndicator()
  }
  
  private func addAIAnticipationEffect(at position: CGPoint, completion: @escaping () -> Void) {
    // Create a subtle preview indicator
    let anticipationNode = SKShapeNode(circleOfRadius: cellSize * 0.3)
    anticipationNode.fillColor = .clear
    anticipationNode.strokeColor = currentTheme.playerOColor
    anticipationNode.lineWidth = 2
    anticipationNode.alpha = 0
    anticipationNode.position = position
    anticipationNode.zPosition = 5
    
    gridContainer?.addChild(anticipationNode)
    
    // Animate anticipation effect
    let fadeIn = SKAction.fadeIn(withDuration: 0.3)
    let pulse = SKAction.sequence([
        SKAction.scale(to: 1.2, duration: 0.2),
        SKAction.scale(to: 1.0, duration: 0.2)
    ])
    let anticipationSequence = SKAction.sequence([
        fadeIn,
        pulse,
        SKAction.wait(forDuration: 0.1),
        SKAction.fadeOut(withDuration: 0.2),
        SKAction.removeFromParent(),
        SKAction.run(completion)
    ])
    
    anticipationNode.run(anticipationSequence)
    
    // Optionally pan camera to show AI move if it's off-screen
    panCameraToPosition(position)
  }
  
  private func performAIMoveAnimation(markNode: SKNode, position: CGPoint, completion: @escaping () -> Void) {
    // Play enhanced sound effect
    SoundManager.shared.playPlaceMarkSound()
    
    // Enhanced placement animation with multiple phases
    markNode.setScale(0)
    markNode.alpha = 0
    
    let phase1 = SKAction.group([
        SKAction.fadeIn(withDuration: 0.15),
        SKAction.scale(to: 1.4, duration: 0.15)
    ])
    
    let phase2 = SKAction.scale(to: 0.9, duration: 0.1)
    let phase3 = SKAction.scale(to: 1.1, duration: 0.1)
    let phase4 = SKAction.scale(to: 1.0, duration: 0.1)
    
    let animationSequence = SKAction.sequence([
        phase1,
        phase2, 
        phase3,
        phase4,
        SKAction.run { [weak self] in
            // Add enhanced particle effect after animation
            self?.addEnhancedAIParticleEffect(at: position)
            completion()
        }
    ])
    
    markNode.run(animationSequence)
  }
  
  private func addEnhancedAIParticleEffect(at position: CGPoint) {
    // Create multiple particle bursts for AI moves
    for i in 0..<8 {
        let particle = SKShapeNode(circleOfRadius: 3)
        particle.fillColor = currentTheme.playerOColor
        particle.strokeColor = .clear
        particle.position = position
        particle.zPosition = 10
        
        let angle = CGFloat(i) * .pi / 4
        let distance: CGFloat = 40
        let targetX = position.x + cos(angle) * distance
        let targetY = position.y + sin(angle) * distance
        
        let moveAction = SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: 0.6)
        let fadeAction = SKAction.fadeOut(withDuration: 0.6)
        let scaleAction = SKAction.scale(to: 0.1, duration: 0.6)
        
        particle.run(SKAction.group([moveAction, fadeAction, scaleAction])) {
            particle.removeFromParent()
        }
        
        gridContainer?.addChild(particle)
    }
    
    // Add central glow effect
    addParticleEffect(at: position, color: currentTheme.playerOColor)
  }
  
  private func panCameraToPosition(_ position: CGPoint) {
    guard let camera = camera else { return }
    
    // Check if position is reasonably close to current view
    let currentCenter = camera.position
    let distance = sqrt(pow(position.x - currentCenter.x, 2) + pow(position.y - currentCenter.y, 2))
    
    // Only pan if the move is more than 2 cells away from current view center
    if distance > cellSize * 2 {
        let panAction = SKAction.move(to: position, duration: 0.8)
        panAction.timingMode = .easeInEaseOut
        camera.run(panAction)
    }
  }
  
  private func determineGamePhase() -> AIGameState.GamePhase {
    if totalTurns <= 6 {
      return .opening
    } else if totalTurns >= 20 {
      return .endgame
    } else {
      return .midgame
    }
  }
}
