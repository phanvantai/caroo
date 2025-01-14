//
//  GameScene.swift
//  Caroo
//
//  Created by Tai Phan Van on 14/1/25.
//

import SpriteKit
import GameplayKit

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
  
  // Add visible rect tracking
  private var lastVisibleRect: CGRect = .zero
  
  // Add these properties at the top of the class
  private var updateThreshold: TimeInterval = 0.3
  private var lastUpdateTime: TimeInterval = 0
  private var isDragging = false
  
  // Add property to track all created nodes
//  private var allCreatedNodes = Set<SKNode>()
//  
  func addModeSelectionButton() {
    // Create container node
    let buttonContainer = SKNode()
    buttonContainer.name = "ModeButton"
    buttonContainer.position = CGPoint(x: 0, y: -frame.height/2 + 50)
    buttonContainer.zPosition = 100
    
    // Create button background with gradient effect
    let background = SKShapeNode(rectOf: CGSize(width: 200, height: 44), cornerRadius: 22)
    background.fillColor = .systemBlue
    background.strokeColor = .white
    background.lineWidth = 2
    background.alpha = 0.9
    background.name = "ModeButton"
    
    // Add inner shadow effect
    let innerGlow = SKShapeNode(rectOf: CGSize(width: 196, height: 40), cornerRadius: 20)
    innerGlow.fillColor = .clear
    innerGlow.strokeColor = .white
    innerGlow.lineWidth = 1
    innerGlow.alpha = 0.3
    background.addChild(innerGlow)
    
    buttonContainer.addChild(background)
    
    // Create button text with correct initial state
    let buttonText = SKLabelNode(text: isSinglePlayer ? "Switch to 2 Players" : "Switch to AI")
    buttonText.fontName = "AvenirNext-Bold"
    buttonText.fontSize = 20
    buttonText.fontColor = .white
    buttonText.verticalAlignmentMode = .center
    buttonText.horizontalAlignmentMode = .center
    buttonText.name = "ModeButton"
    
    buttonContainer.addChild(buttonText)
    
    // Add subtle pulsing animation
    let pulseUp = SKAction.scale(to: 1.05, duration: 1.0)
    let pulseDown = SKAction.scale(to: 0.95, duration: 1.0)
    pulseUp.timingMode = .easeInEaseOut
    pulseDown.timingMode = .easeInEaseOut
    
    background.run(SKAction.repeatForever(SKAction.sequence([
        pulseUp,
        pulseDown
    ])))
    
    camera?.addChild(buttonContainer)
  }
  
  override func didMove(to view: SKView) {
    // Set up camera for scrolling
    cameraNode = SKCameraNode()
    if let camera = cameraNode {
        addChild(camera)
        self.camera = camera
        camera.position = CGPoint(x: 0, y: 0)
    }
    
    // Create container for grid borders
    gridContainer = SKNode()
    if let container = gridContainer {
        addChild(container)
    }
    
    backgroundColor = .white
    setupGrid()
    addModeSelectionButton()
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
    cell.strokeColor = .lightGray
    cell.lineWidth = 0.5
    cell.name = "Border-\(row)-\(col)"
    cell.zPosition = -1
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
        if node.name == "ModeButton" || node.parent?.name == "ModeButton" {
            // Find the button container
            let buttonContainer = node.name == "ModeButton" ? (node.parent ?? node) : node.parent!
            
            // Add press animation
            buttonContainer.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 0.9, duration: 0.1),
                    SKAction.fadeAlpha(to: 0.7, duration: 0.1)
                ]),
                SKAction.group([
                    SKAction.scale(to: 1.0, duration: 0.1),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.1)
                ])
            ]))
            
            // Toggle mode BEFORE updating text
            isSinglePlayer.toggle()
            
            // Find and update the button text
            for child in buttonContainer.children {
                if let textNode = child as? SKLabelNode,
                   textNode.name == "ModeButton" {
                    // Update text based on the NEW state of isSinglePlayer
                    textNode.text = isSinglePlayer ? "Switch to 2 Players" : "Switch to AI"
                    
                    // Update shadow text
                    if let shadowText = textNode.children.first as? SKLabelNode {
                        shadowText.text = textNode.text
                    }
                    break
                }
            }
            return
        } else if node.name == "PopupRestartButton" || node.parent?.name == "PopupRestartButton" {
            // Find the WinPopup node by traversing up the node tree
            var currentNode = node
            while currentNode.parent != nil && !(currentNode.parent is WinPopup) {
                currentNode = currentNode.parent!
            }
            
            if let popup = currentNode.parent as? WinPopup {
                // Add dismiss animation
                let dismissSequence = SKAction.group([
                    SKAction.scale(to: 0.5, duration: 0.2),
                    SKAction.fadeOut(withDuration: 0.2)
                ])
                
                popup.run(SKAction.sequence([
                    dismissSequence,
                    SKAction.removeFromParent()
                ]))
                
                restartGame()
            }
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
        
        // Place mark
        grid[key] = currentPlayer
        _ = placeMark(at: row, col: col, player: currentPlayer)
        
        if checkForWin(at: row, col: col, player: currentPlayer) {
            showWinAlert(for: currentPlayer)
            return
        }
        
        currentPlayer = (currentPlayer == "X") ? "O" : "X"
        
        if isSinglePlayer && currentPlayer == "O" {
            aiMove()
        }
    }
    
    // Reset scrolling flag
    isScrolling = false
  }
  
  func aiMove() {
    // Get all occupied positions
    let occupiedPositions = Set(grid.keys)
    
    // Find the bounds of the current game area
    let positions = occupiedPositions.map { key -> (Int, Int) in
        let components = key.split(separator: ",")
        return (Int(components[0])!, Int(components[1])!)
    }
    
    let rows = positions.map { $0.0 }
    let cols = positions.map { $0.1 }
    
    // If no moves yet, place in center (0,0)
    if positions.isEmpty {
        let row = 0
        let col = 0
        grid[gridKey(row, col)] = "O"
        let _ = placeMark(at: row, col: col, player: "O")
    } else {
        // Get min/max positions and add 1 cell padding
        let minRow = (rows.min() ?? 0) - 1
        let maxRow = (rows.max() ?? 0) + 1
        let minCol = (cols.min() ?? 0) - 1
        let maxCol = (cols.max() ?? 0) + 1
        
        // Find available moves within this area
        var availableMoves: [(Int, Int)] = []
        for row in minRow...maxRow {
            for col in minCol...maxCol {
                let key = gridKey(row, col)
                if grid[key] == nil {
                    availableMoves.append((row, col))
                }
            }
        }
        
        // Pick a random move
        if let randomMove = availableMoves.randomElement() {
            let (row, col) = randomMove
            grid[gridKey(row, col)] = "O"
            let _ = placeMark(at: row, col: col, player: "O")
            
            if checkForWin(at: row, col: col, player: "O") {
                showWinAlert(for: "O")
                return
            }
        }
    }
    
    currentPlayer = "X" // Switch back to player turn
  }
  
  func restartGame() {
    grid.removeAll()
    
    // Remove all nodes except camera and its children
    children.forEach { node in
        if node != camera {
            node.removeFromParent()
        }
    }
    
    // Re-create grid container
    gridContainer = SKNode()
    if let container = gridContainer {
        addChild(container)
    }
    
    setupGrid()
    currentPlayer = "X"
    gameEnded = false
    lastVisibleRect = .zero  // Reset last visible rect to force grid update
  }
  
  func placeMark(at row: Int, col: Int, player: String) -> SKNode {
    if player.isEmpty { return SKNode() }
    
    let x = CGFloat(col) * cellSize
    let y = CGFloat(row) * cellSize
    
    let label = SKLabelNode(text: player)
    label.fontName = "Arial-BoldMT"
    label.fontSize = cellSize * 0.8
    label.fontColor = .black
    label.position = CGPoint(x: x + cellSize/2, y: y + cellSize/2)
    label.verticalAlignmentMode = .center
    label.horizontalAlignmentMode = .center
    label.name = "Cell-\(row)-\(col)"
    addChild(label)
    return label
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
    for (row, col) in cells {
      // Find the label by its name and change its font color to red (or any color you prefer)
      if let cellLabel = childNode(withName: "Cell-\(row)-\(col)") as? SKLabelNode {
        cellLabel.fontColor = .red // Highlight in red
      }
    }
  }
  
  func showWinAlert(for player: String) {
    let popup = WinPopup(size: self.size, winner: player)
    popup.zPosition = 1000
    camera?.addChild(popup)
    gameEnded = true
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
    node.strokeColor = .lightGray
    node.lineWidth = 0.5
    node.zPosition = -1
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
  
  // Add cleanup in deinit
  deinit {
  }
}
