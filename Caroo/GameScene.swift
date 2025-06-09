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
    addAIDifficultyIndicator() // Add AI difficulty indicator on start
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
    let turnText = SKLabelNode(text: "Turn: \(currentPlayer)")
    turnText.fontName = "AvenirNext-Bold"
    turnText.fontSize = 16
    turnText.fontColor = currentPlayer == "X" ? currentTheme.playerXColor : currentTheme.playerOColor
    turnText.verticalAlignmentMode = .center
    turnText.name = "TurnText"
    
    indicator.addChild(background)
    indicator.addChild(turnText)
    
    camera?.addChild(indicator)
  }
  
  func updateTurnIndicator() {
    if let indicator = camera?.childNode(withName: "TurnIndicator"),
       let turnText = indicator.childNode(withName: "TurnText") as? SKLabelNode {
        turnText.text = "Turn: \(currentPlayer)"
        turnText.fontColor = currentPlayer == "X" ? currentTheme.playerXColor : currentTheme.playerOColor
        
        // Add pulse animation
        turnText.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
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
    
    // Only place mark if game hasn't ended and user didn't scroll
    if !gameEnded && !isScrolling {
        let location = touch.location(in: self)
        
        // Convert touch location to world coordinates using camera position
        let worldX = location.x + camera.position.x
        let worldY = location.y + camera.position.y
        
        // Calculate grid position from world coordinates
        let row = Int(floor((worldY - camera.position.y) / cellSize))
        let col = Int(floor((worldX - camera.position.x) / cellSize))
        let key = gridKey(row, col)
        
        // Check if cell is already occupied
        if grid[key] != nil {
            return
        }
        
        // Place mark with enhanced animation
        grid[key] = currentPlayer
        let markNode = placeMark(at: row, col: col, player: currentPlayer)
        
        // Increment turn counter
        totalTurns += 1
        
        // Play sound effect
        SoundManager.shared.playPlaceMarkSound()
        
        // Add placement animation
        markNode.setScale(0)
        markNode.run(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
        
        // Add particle effect
        addParticleEffect(at: markNode.position, color: currentPlayer == "X" ? currentTheme.playerXColor : currentTheme.playerOColor)
        
        if checkForWin(at: row, col: col, player: currentPlayer) {
            showWinAlert(for: currentPlayer)
            return
        }
        
        currentPlayer = (currentPlayer == "X") ? "O" : "X"
        updateTurnIndicator()
        
        if isSinglePlayer && currentPlayer == "O" {
            // Show AI thinking animation and use difficulty-based delay
            showAIThinking()
            let thinkingTime = AIBot.shared.currentDifficulty.thinkingTime
            DispatchQueue.main.asyncAfter(deadline: .now() + thinkingTime) {
                self.hideAIThinking()
                self.aiMove()
            }
        }
    }
    
    // Reset scrolling flag
    isScrolling = false
  }
  
  // MARK: - AI Difficulty Display
  
  func addAIDifficultyIndicator() {
    guard isSinglePlayer else { return }
    
    let difficultyNode = SKNode()
    difficultyNode.name = "AIDifficultyIndicator"
    difficultyNode.zPosition = 95
    
    // Background
    let background = SKShapeNode(rectOf: CGSize(width: 160, height: 35), cornerRadius: 17.5)
    background.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.7)
    background.strokeColor = currentTheme.accentColor
    background.lineWidth = 1.5
    
    // Add glow for neon theme
    if currentTheme == .neon {
      background.glowWidth = 2
    }
    
    difficultyNode.addChild(background)
    
    // Difficulty text
    let difficultyText = getDifficultyDisplayText()
    let difficultyLabel = SKLabelNode(text: difficultyText)
    difficultyLabel.fontName = "AvenirNext-Bold"
    difficultyLabel.fontSize = 12
    difficultyLabel.fontColor = currentTheme.accentColor
    difficultyLabel.verticalAlignmentMode = .center
    difficultyLabel.horizontalAlignmentMode = .center
    difficultyNode.addChild(difficultyLabel)
    
    // Position at top-left of screen
    difficultyNode.position = CGPoint(x: -frame.width/2 + 90, y: frame.height/2 - 80)
    
    // Add entrance animation
    difficultyNode.alpha = 0
    difficultyNode.run(SKAction.sequence([
      SKAction.wait(forDuration: 1.0),
      SKAction.fadeIn(withDuration: 0.5)
    ]))
    
    camera?.addChild(difficultyNode)
  }
  
  private func getDifficultyDisplayText() -> String {
    let difficulty = AIBot.shared.currentDifficulty
    if difficulty == .adaptive {
      let effectiveDifficulty = AIBot.shared.getCurrentEffectiveDifficulty()
      return "🧠 Adaptive (\(effectiveDifficulty.rawValue))"
    } else {
      return difficulty.description
    }
  }
  
  func showAdaptiveDifficultyNotification(_ reason: String) {
    guard let camera = self.camera else { return }
    
    // Create notification node
    let notificationNode = SKNode()
    notificationNode.name = "AdaptiveDifficultyNotification"
    notificationNode.zPosition = 150
    
    // Background
    let background = SKShapeNode(rectOf: CGSize(width: 250, height: 50), cornerRadius: 25)
    background.fillColor = UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 0.9)
    background.strokeColor = .white
    background.lineWidth = 2
    
    // Add glow effect
    if currentTheme == .neon {
      background.glowWidth = 4
    }
    
    notificationNode.addChild(background)
    
    // Notification text
    let notificationText = SKLabelNode(text: reason)
    notificationText.fontName = "AvenirNext-Bold"
    notificationText.fontSize = 16
    notificationText.fontColor = .white
    notificationText.verticalAlignmentMode = .center
    notificationText.horizontalAlignmentMode = .center
    notificationNode.addChild(notificationText)
    
    // Position at top center of screen
    notificationNode.position = CGPoint(x: 0, y: frame.height/2 - 120)
    
    // Entrance animation
    notificationNode.setScale(0)
    notificationNode.alpha = 0
    
    let appearSequence = SKAction.group([
      SKAction.scale(to: 1.0, duration: 0.3),
      SKAction.fadeIn(withDuration: 0.3)
    ])
    
    let dismissSequence = SKAction.group([
      SKAction.scale(to: 0.8, duration: 0.3),
      SKAction.fadeOut(withDuration: 0.3)
    ])
    
    notificationNode.run(SKAction.sequence([
      appearSequence,
      SKAction.wait(forDuration: 2.5),
      dismissSequence,
      SKAction.removeFromParent()
    ]))
    
    camera.addChild(notificationNode)
    
    // Update the difficulty indicator
    updateDifficultyIndicator()
  }
  
  private func updateDifficultyIndicator() {
    guard let camera = self.camera,
          let difficultyIndicator = camera.childNode(withName: "AIDifficultyIndicator") else { return }
    
    // Update the text
    for child in difficultyIndicator.children {
      if let labelNode = child as? SKLabelNode {
        labelNode.text = getDifficultyDisplayText()
        
        // Add update animation
        labelNode.run(SKAction.sequence([
          SKAction.scale(to: 1.2, duration: 0.2),
          SKAction.scale(to: 1.0, duration: 0.2)
        ]))
        break
      }
    }
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
  
  func aiMove() {
    // Use the new AI bot to find the best move
    guard let bestMove = AIBot.shared.findBestMove(for: grid, player: "O", opponent: "X") else {
      // Fallback to center if no move found
      let row = 0
      let col = 0
      grid[gridKey(row, col)] = "O"
      let _ = placeMark(at: row, col: col, player: "O")
      currentPlayer = "X"
      updateTurnIndicator()
      return
    }
    
    let (row, col) = bestMove
    
    // Place the AI move
    grid[gridKey(row, col)] = "O"
    let _ = placeMark(at: row, col: col, player: "O")
    
    // Increment turn counter for AI move
    totalTurns += 1
    
    // Check for AI win
    if checkForWin(at: row, col: col, player: "O") {
      showWinAlert(for: "O")
      return
    }
    
    // Switch back to player turn
    currentPlayer = "X"
    updateTurnIndicator()
  }
  
  // MARK: - AI Thinking Animation
  
  func showAIThinking() {
    // Create thinking indicator
    let thinkingNode = SKNode()
    thinkingNode.name = "AIThinking"
    thinkingNode.zPosition = 100
    
    // Position relative to camera
    guard let camera = self.camera else { return }
    
    // Background bubble
    let background = SKShapeNode(rectOf: CGSize(width: 180, height: 50), cornerRadius: 25)
    background.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
    background.strokeColor = currentTheme.playerOColor
    background.lineWidth = 2
    
    // Add glow effect for neon theme
    if currentTheme == .neon {
      background.glowWidth = 4
    }
    
    thinkingNode.addChild(background)
    
    // AI thinking text
    let thinkingText = SKLabelNode(text: "🤖 AI Thinking...")
    thinkingText.fontName = "AvenirNext-Medium"
    thinkingText.fontSize = 16
    thinkingText.fontColor = .white
    thinkingText.verticalAlignmentMode = .center
    thinkingText.horizontalAlignmentMode = .center
    thinkingText.position = CGPoint(x: -15, y: 0)
    thinkingNode.addChild(thinkingText)
    
    // Animated dots
    let dots = SKLabelNode(text: "...")
    dots.fontName = "AvenirNext-Medium"
    dots.fontSize = 16
    dots.fontColor = currentTheme.playerOColor
    dots.verticalAlignmentMode = .center
    dots.horizontalAlignmentMode = .center
    dots.position = CGPoint(x: 45, y: 0)
    
    // Animate dots
    let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.5)
    let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.5)
    dots.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])))
    
    thinkingNode.addChild(dots)
    
    // Position thinking indicator at top-right of screen
    thinkingNode.position = CGPoint(x: frame.width/2 - 100, y: frame.height/2 - 80)
    
    // Add entrance animation
    thinkingNode.setScale(0)
    thinkingNode.run(SKAction.scale(to: 1.0, duration: 0.2))
    
    camera.addChild(thinkingNode)
  }
  
  func hideAIThinking() {
    guard let camera = self.camera,
          let thinkingNode = camera.childNode(withName: "AIThinking") else { return }
    
    // Exit animation
    thinkingNode.run(SKAction.sequence([
      SKAction.scale(to: 0, duration: 0.2),
      SKAction.removeFromParent()
    ]))
  }

  // ...existing code...
  
  func restartGame() {
    grid.removeAll()
    totalTurns = 0  // Reset turn counter
    
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
    currentPlayer = "X"
    gameEnded = false
    lastVisibleRect = .zero  // Reset last visible rect to force grid update
    
    // Recreate turn indicator
    addTurnIndicator()
    addAIDifficultyIndicator() // Re-add AI difficulty indicator
    
    // Play restart sound
    SoundManager.shared.playButtonSound()
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
    // Play win sound effect
    SoundManager.shared.playWinSound()
    
    // Record game result for adaptive difficulty (only in single player mode)
    if isSinglePlayer {
      let playerWon = (player == "X")
      PlayerProfileManager.shared.recordGameResult(playerWon: playerWon, turnsPlayed: totalTurns)
    }
    
    let popup = WinPopup(size: self.size, winner: player, theme: currentTheme)
    popup.zPosition = 1000
    camera?.addChild(popup)
    gameEnded = true
    
    // Add celebration particle burst
    addCelebrationEffect()
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
}
