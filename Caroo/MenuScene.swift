//
//  MenuScene.swift
//  Caroo
//
//  Created by Tai Phan Van on 14/1/25.
//

import SpriteKit
import GameplayKit

class MenuScene: SKScene {
  
  // Use centralized theme manager
  private var currentTheme: ThemeManager.Theme {
    return ThemeManager.shared.currentTheme
  }
  
  // UI Elements
  private var titleLabel: SKLabelNode?
  private var singlePlayerButton: SKNode?
  private var twoPlayerButton: SKNode?
  private var settingsButton: SKNode?
  private var instructionsButton: SKNode?
  private var themeButton: SKNode?
  
  // Popup state tracking
  private var isPopupShowing = false
  
  override func didMove(to view: SKView) {
    // Set anchor point to center of screen
    anchorPoint = CGPoint(x: 0.5, y: 0.5)
    
    // Listen for theme changes
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleThemeChange),
      name: .themeDidChange,
      object: nil
    )
    
    setupBackground()
    setupTitle()
    setupMenuButtons()
    setupThemeButton()
    createAnimatedBackground()
    
    // Add entrance animations
    animateMenuEntrance()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc private func handleThemeChange() {
    updateTheme()
  }
  
  func setupBackground() {
    backgroundColor = currentTheme.backgroundColor
  }
  
  func setupTitle() {
    // Create main title
    titleLabel = SKLabelNode(text: "CAROO")
    guard let titleLabel = titleLabel else { return }
    
    titleLabel.fontName = "AvenirNext-Heavy"
    titleLabel.fontSize = 80
    titleLabel.fontColor = currentTheme.titleColor // Use dedicated title color
    titleLabel.position = CGPoint(x: 0, y: frame.height * 0.25)
    titleLabel.horizontalAlignmentMode = .center
    titleLabel.verticalAlignmentMode = .center
    titleLabel.zPosition = 10
    
    // Add title shadow
    let titleShadow = SKLabelNode(text: "CAROO")
    titleShadow.fontName = titleLabel.fontName
    titleShadow.fontSize = titleLabel.fontSize
    titleShadow.fontColor = .black
    titleShadow.alpha = 0.3
    titleShadow.position = CGPoint(x: 3, y: -3)
    titleShadow.horizontalAlignmentMode = .center
    titleShadow.verticalAlignmentMode = .center
    titleLabel.addChild(titleShadow)
    
    // Add title glow for neon theme
    if currentTheme == .neon {
      let titleGlow = SKLabelNode(text: "CAROO")
      titleGlow.fontName = titleLabel.fontName
      titleGlow.fontSize = titleLabel.fontSize + 4
      titleGlow.fontColor = currentTheme.titleColor
      titleGlow.alpha = 0.3
      titleGlow.position = CGPoint(x: 0, y: 0)
      titleGlow.horizontalAlignmentMode = .center
      titleGlow.verticalAlignmentMode = .center
      titleGlow.zPosition = -1
      titleLabel.addChild(titleGlow)
    }
    
    addChild(titleLabel)
    
    // Add subtitle
    let subtitle = SKLabelNode(text: "Infinite Tic-Tac-Toe")
    subtitle.fontName = "AvenirNext-Medium"
    subtitle.fontSize = 24
    subtitle.fontColor = currentTheme.subtitleColor // Use dedicated subtitle color
    subtitle.position = CGPoint(x: 0, y: frame.height * 0.15)
    subtitle.horizontalAlignmentMode = .center
    subtitle.verticalAlignmentMode = .center
    subtitle.alpha = 0.8
    addChild(subtitle)
  }
  
  func setupMenuButtons() {
    let buttonSpacing: CGFloat = 70
    let startY: CGFloat = 20  // Adjusted to accommodate two game mode buttons
    
    // Single Player Button - Use primary color
    singlePlayerButton = createMenuButton(
      text: "🎮 Practice Mode",
      position: CGPoint(x: 0, y: startY),
      color: currentTheme.primaryColor,
      name: "SinglePlayerButton"
    )
    
    // Two Player Button - Use secondary color
    twoPlayerButton = createMenuButton(
      text: "👥 Two Players",
      position: CGPoint(x: 0, y: startY - buttonSpacing),
      color: currentTheme.secondaryColor,
      name: "TwoPlayerButton"
    )
    
    // Settings Button - Use tertiary color
    settingsButton = createMenuButton(
      text: "⚙️ Settings",
      position: CGPoint(x: 0, y: startY - buttonSpacing * 2),
      color: currentTheme.tertiaryColor,
      name: "SettingsButton"
    )
    
    // Instructions Button - Use quaternary color
    instructionsButton = createMenuButton(
      text: "📖 How to Play",
      position: CGPoint(x: 0, y: startY - buttonSpacing * 3),
      color: currentTheme.quaternaryColor,
      name: "InstructionsButton"
    )
    
    if let singlePlayerButton = singlePlayerButton { addChild(singlePlayerButton) }
    if let twoPlayerButton = twoPlayerButton { addChild(twoPlayerButton) }
    if let settingsButton = settingsButton { addChild(settingsButton) }
    if let instructionsButton = instructionsButton { addChild(instructionsButton) }
  }
  
  func createMenuButton(text: String, position: CGPoint, color: UIColor, name: String) -> SKNode {
    let buttonContainer = SKNode()
    buttonContainer.name = name
    buttonContainer.position = position
    buttonContainer.zPosition = 5
    
    // Button shadow
    let shadow = SKShapeNode(rectOf: CGSize(width: 280, height: 60), cornerRadius: 30)
    shadow.fillColor = .black
    shadow.strokeColor = .clear
    shadow.alpha = 0.2
    shadow.position = CGPoint(x: 2, y: -2)
    buttonContainer.addChild(shadow)
    
    // Button background
    let background = SKShapeNode(rectOf: CGSize(width: 280, height: 60), cornerRadius: 30)
    background.fillColor = color
    background.strokeColor = .white
    background.lineWidth = 2
    background.alpha = 0.9
    background.name = name
    
    // Button glow effect
    if currentTheme == .neon {
      let glow = SKShapeNode(rectOf: CGSize(width: 300, height: 70), cornerRadius: 35)
      glow.fillColor = .clear
      glow.strokeColor = color
      glow.lineWidth = 2
      glow.alpha = 0.4
      glow.zPosition = -1
      buttonContainer.addChild(glow)
      
      // Animated glow pulse
      let glowPulse = SKAction.sequence([
        SKAction.fadeAlpha(to: 0.8, duration: 1.5),
        SKAction.fadeAlpha(to: 0.2, duration: 1.5)
      ])
      glow.run(SKAction.repeatForever(glowPulse))
    }
    
    buttonContainer.addChild(background)
    
    // Button text
    let buttonText = SKLabelNode(text: text)
    buttonText.fontName = "AvenirNext-Bold"
    buttonText.fontSize = 22
    buttonText.fontColor = .white
    buttonText.verticalAlignmentMode = .center
    buttonText.horizontalAlignmentMode = .center
    buttonText.name = name
    
    // Text shadow
    let textShadow = SKLabelNode(text: text)
    textShadow.fontName = buttonText.fontName
    textShadow.fontSize = buttonText.fontSize
    textShadow.fontColor = .black
    textShadow.alpha = 0.4
    textShadow.position = CGPoint(x: 1, y: -1)
    textShadow.verticalAlignmentMode = .center
    textShadow.horizontalAlignmentMode = .center
    buttonText.addChild(textShadow)
    
    buttonContainer.addChild(buttonText)
    
    // Subtle floating animation
    let floatUp = SKAction.moveBy(x: 0, y: 5, duration: 2.0)
    let floatDown = SKAction.moveBy(x: 0, y: -5, duration: 2.0)
    floatUp.timingMode = .easeInEaseOut
    floatDown.timingMode = .easeInEaseOut
    
    buttonContainer.run(SKAction.repeatForever(SKAction.sequence([floatUp, floatDown])))
    
    return buttonContainer
  }
  
  func setupThemeButton() {
    themeButton = SKNode()
    guard let themeButton = themeButton else { return }
    
    themeButton.name = "ThemeButton"
    themeButton.position = CGPoint(x: frame.width/2 - 60, y: -frame.height/2 + 60)
    themeButton.zPosition = 10
    
    let background = SKShapeNode(circleOfRadius: 30)
    background.fillColor = currentTheme.accentColor // Use accent color for theme button
    background.strokeColor = .white
    background.lineWidth = 3
    background.name = "ThemeButton"
    
    let icon = SKLabelNode(text: "🎨")
    icon.fontSize = 35
    icon.verticalAlignmentMode = .center
    icon.horizontalAlignmentMode = .center
    icon.name = "ThemeButton"
    
    themeButton.addChild(background)
    themeButton.addChild(icon)
    
    // Rotating animation
    let rotation = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 8.0)
    background.run(SKAction.repeatForever(rotation))
    
    addChild(themeButton)
  }
  
  func createAnimatedBackground() {
    // Create animated background particles for cosmic theme
    if currentTheme == .cosmic {
      for _ in 0..<60 {
        let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...2.5))
        star.fillColor = .white
        star.alpha = CGFloat.random(in: 0.2...0.8)
        star.position = CGPoint(
          x: CGFloat.random(in: -frame.width/2...frame.width/2),
          y: CGFloat.random(in: -frame.height/2...frame.height/2)
        )
        star.zPosition = -10
        star.name = "star"
        
        let twinkle = SKAction.sequence([
          SKAction.fadeAlpha(to: 0.1, duration: Double.random(in: 1...4)),
          SKAction.fadeAlpha(to: 0.9, duration: Double.random(in: 1...4))
        ])
        star.run(SKAction.repeatForever(twinkle))
        
        addChild(star)
      }
    }
    
    // Add floating particles for neon theme
    if currentTheme == .neon {
      for _ in 0..<20 {
        let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3))
        particle.fillColor = currentTheme.accentColor
        particle.alpha = CGFloat.random(in: 0.3...0.7)
        particle.position = CGPoint(
          x: CGFloat.random(in: -frame.width/2...frame.width/2),
          y: CGFloat.random(in: -frame.height/2...frame.height/2)
        )
        particle.zPosition = -5
        particle.name = "particle"
        
        let float = SKAction.moveBy(
          x: CGFloat.random(in: -50...50),
          y: CGFloat.random(in: -50...50),
          duration: Double.random(in: 3...8)
        )
        particle.run(SKAction.repeatForever(SKAction.sequence([float, float.reversed()])))
        
        addChild(particle)
      }
    }
  }
  
  func animateMenuEntrance() {
    // Animate title entrance
    titleLabel?.setScale(0)
    titleLabel?.alpha = 0
    titleLabel?.run(SKAction.group([
      SKAction.scale(to: 1.0, duration: 0.8),
      SKAction.fadeIn(withDuration: 0.8)
    ]))
    
    // Animate buttons with staggered delay
    let buttons = [singlePlayerButton, twoPlayerButton, settingsButton, instructionsButton]
    for (index, button) in buttons.enumerated() {
      button?.alpha = 0
      button?.position.y -= 50
      
      let delay = Double(index) * 0.2 + 0.5
      button?.run(SKAction.sequence([
        SKAction.wait(forDuration: delay),
        SKAction.group([
          SKAction.moveBy(x: 0, y: 50, duration: 0.6),
          SKAction.fadeIn(withDuration: 0.6)
        ])
      ]))
    }
    
    // Animate theme button
    themeButton?.setScale(0)
    themeButton?.run(SKAction.sequence([
      SKAction.wait(forDuration: 1.2),
      SKAction.scale(to: 1.0, duration: 0.4)
    ]))
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    
    let touchLocation = touch.location(in: self)
    let touchedNodes = nodes(at: touchLocation)
    
    // If popup is showing, don't allow background button interactions
    if isPopupShowing {
      return
    }
    
    for node in touchedNodes {
      if node.name == "SinglePlayerButton" || node.parent?.name == "SinglePlayerButton" {
        handleSinglePlayerButtonTap(node: node)
        return
      } else if node.name == "TwoPlayerButton" || node.parent?.name == "TwoPlayerButton" {
        handleTwoPlayerButtonTap(node: node)
        return
      } else if node.name == "SettingsButton" || node.parent?.name == "SettingsButton" {
        handleSettingsButtonTap(node: node)
        return
      } else if node.name == "InstructionsButton" || node.parent?.name == "InstructionsButton" {
        handleInstructionsButtonTap(node: node)
        return
      } else if node.name == "ThemeButton" || node.parent?.name == "ThemeButton" {
        handleThemeButtonTap(node: node)
        return
      }
    }
  }
  
  func handleSinglePlayerButtonTap(node: SKNode) {
    if isPopupShowing {
      // Ignore taps if popup is showing
      return
    }
    let buttonContainer = node.name == "SinglePlayerButton" ? (node.parent ?? node) : node.parent!
    
    // Button press animation
    buttonContainer.run(SKAction.sequence([
      SKAction.group([
        SKAction.scale(to: 0.9, duration: 0.1),
        SKAction.fadeAlpha(to: 0.7, duration: 0.1)
      ]),
      SKAction.group([
        SKAction.scale(to: 1.0, duration: 0.1),
        SKAction.fadeAlpha(to: 1.0, duration: 0.1)
      ])
    ])) {
      // Show difficulty selection popup
      self.showDifficultySelectionPopup()
    }
    
    // Play sound effect
    SoundManager.shared.playButtonSound()
  }
  
  func handleTwoPlayerButtonTap(node: SKNode) {
    if isPopupShowing {
      // Ignore taps if popup is showing
      return
    }
    let buttonContainer = node.name == "TwoPlayerButton" ? (node.parent ?? node) : node.parent!
    
    // Button press animation
    buttonContainer.run(SKAction.sequence([
      SKAction.group([
        SKAction.scale(to: 0.9, duration: 0.1),
        SKAction.fadeAlpha(to: 0.7, duration: 0.1)
      ]),
      SKAction.group([
        SKAction.scale(to: 1.0, duration: 0.1),
        SKAction.fadeAlpha(to: 1.0, duration: 0.1)
      ])
    ])) {
      self.transitionToGame(isSinglePlayer: false)
    }
    
    // Play sound effect
    SoundManager.shared.playButtonSound()
  }
  
  func handleSettingsButtonTap(node: SKNode) {
    if isPopupShowing {
      // Ignore taps if popup is showing
      return
    }
    let buttonContainer = node.name == "SettingsButton" ? (node.parent ?? node) : node.parent!
    
    // Button press animation
    buttonContainer.run(SKAction.sequence([
      SKAction.scale(to: 0.9, duration: 0.1),
      SKAction.scale(to: 1.0, duration: 0.1)
    ]))
    
    // Play sound effect
    SoundManager.shared.playButtonSound()
    
    // Show settings popup (we'll implement this)
    showSettingsPopup()
  }
  
  func handleInstructionsButtonTap(node: SKNode) {
    if isPopupShowing {
      // Ignore taps if popup is showing
      return
    }
    let buttonContainer = node.name == "InstructionsButton" ? (node.parent ?? node) : node.parent!
    
    // Button press animation
    buttonContainer.run(SKAction.sequence([
      SKAction.scale(to: 0.9, duration: 0.1),
      SKAction.scale(to: 1.0, duration: 0.1)
    ]))
    
    // Play sound effect
    SoundManager.shared.playButtonSound()
    
    // Show instructions popup
    showInstructionsPopup()
  }
  
  func handleThemeButtonTap(node: SKNode) {
    if isPopupShowing {
      // Ignore taps if popup is showing
      return
    }
    let buttonContainer = node.name == "ThemeButton" ? (node.parent ?? node) : node.parent!
    
    // Button press animation
    buttonContainer.run(SKAction.sequence([
      SKAction.scale(to: 0.8, duration: 0.1),
      SKAction.scale(to: 1.2, duration: 0.1),
      SKAction.scale(to: 1.0, duration: 0.1)
    ]))
    
    // Play theme switch sound
    SoundManager.shared.playThemeSwitchSound()
    
    switchTheme()
  }
  
  func handleDifficultyButtonTap(node: SKNode) {
    guard let nodeName = node.name,
          let difficultyString = nodeName.components(separatedBy: "-").last,
          let difficulty = AIDifficulty(rawValue: difficultyString) else {
      return
    }
    
    // Button press animation
    let buttonContainer = node.parent ?? node
    buttonContainer.run(SKAction.sequence([
      SKAction.group([
        SKAction.scale(to: 0.9, duration: 0.1),
        SKAction.fadeAlpha(to: 0.7, duration: 0.1)
      ]),
      SKAction.group([
        SKAction.scale(to: 1.0, duration: 0.1),
        SKAction.fadeAlpha(to: 1.0, duration: 0.1)
      ])
    ])) {
      // Close the difficulty popup and start the game
      self.closePopup(named: "DifficultySelectionPopup")
      self.transitionToGame(isSinglePlayer: true, aiDifficulty: difficulty)
    }
    
    // Play sound effect
    SoundManager.shared.playButtonSound()
  }
  
  func transitionToGame(isSinglePlayer: Bool, aiDifficulty: AIDifficulty = .intermediate) {
    // Create transition effect
    let transition = SKTransition.fade(withDuration: 0.8)
    
    // Create GameScene with the specified game mode and AI difficulty
    let gameScene = GameScene(size: self.size, singlePlayer: isSinglePlayer, aiDifficulty: aiDifficulty)
    gameScene.scaleMode = .aspectFill
    
    // Present the game scene
    self.view?.presentScene(gameScene, transition: transition)
  }
  
  func switchTheme() {
    ThemeManager.shared.switchToNextTheme()
  }
  
  func updateTheme() {
    // Update background
    backgroundColor = currentTheme.backgroundColor
    
    // Remove old background elements
    children.filter { $0.name == "star" || $0.name == "particle" }.forEach { $0.removeFromParent() }
    
    // Recreate background
    createAnimatedBackground()
    
    // Update UI elements colors
    updateUIColors()
  }
  
  func updateUIColors() {
    // Update title color
    titleLabel?.fontColor = currentTheme.titleColor
    
    // Update subtitle color (find the subtitle node)
    for child in children {
      if let labelNode = child as? SKLabelNode, labelNode.text == "Infinite Tic-Tac-Toe" {
        labelNode.fontColor = currentTheme.subtitleColor
      }
    }
    
    // Update button colors with new color scheme
    updateButtonColor(singlePlayerButton, color: currentTheme.primaryColor)
    updateButtonColor(twoPlayerButton, color: currentTheme.secondaryColor)
    updateButtonColor(settingsButton, color: currentTheme.tertiaryColor)
    updateButtonColor(instructionsButton, color: currentTheme.quaternaryColor)
    
    // Update theme button
    if let themeButton = themeButton {
      for child in themeButton.children {
        if let shapeNode = child as? SKShapeNode, child.name == "ThemeButton" {
          shapeNode.fillColor = currentTheme.accentColor
        }
      }
    }
  }
  
  func updateButtonColor(_ button: SKNode?, color: UIColor) {
    guard let button = button else { return }
    
    for child in button.children {
      if let shapeNode = child as? SKShapeNode, child.name == button.name {
        shapeNode.fillColor = color
      }
    }
  }
  
  func showSettingsPopup() {
    // Set popup state
    isPopupShowing = true
    
    // Create a simple settings popup
    let popup = SKNode()
    popup.name = "SettingsPopup"
    popup.zPosition = 100
    
    // Background overlay
    let overlay = SKShapeNode(rect: CGRect(x: -frame.width/2, y: -frame.height/2, width: frame.width, height: frame.height))
    overlay.fillColor = .black
    overlay.alpha = 0.5
    overlay.strokeColor = .clear
    overlay.name = "PopupOverlay"
    popup.addChild(overlay)
    
    // Popup background
    let popupBg = SKShapeNode(rectOf: CGSize(width: 300, height: 200), cornerRadius: 20)
    popupBg.fillColor = currentTheme.backgroundColor
    popupBg.strokeColor = currentTheme.primaryColor
    popupBg.lineWidth = 3
    
    // Popup title
    let title = SKLabelNode(text: "Settings")
    title.fontName = "AvenirNext-Bold"
    title.fontSize = 24
    title.fontColor = currentTheme.primaryColor
    title.position = CGPoint(x: 0, y: 60)
    title.horizontalAlignmentMode = .center
    
    // Close button
    let closeButton = SKLabelNode(text: "✕")
    closeButton.fontName = "AvenirNext-Bold"
    closeButton.fontSize = 30
    closeButton.fontColor = currentTheme.secondaryColor
    closeButton.position = CGPoint(x: 120, y: 70)
    closeButton.name = "CloseSettings"
    
    // Settings content
    let settingsText = SKLabelNode(text: "Theme switching available\nwith 🎨 button")
    settingsText.fontName = "AvenirNext-Medium"
    settingsText.fontSize = 16
    settingsText.fontColor = currentTheme.accentColor
    settingsText.numberOfLines = 2
    settingsText.horizontalAlignmentMode = .center
    settingsText.verticalAlignmentMode = .center
    
    popup.addChild(popupBg)
    popup.addChild(title)
    popup.addChild(closeButton)
    popup.addChild(settingsText)
    
    // Add entrance animation
    popup.setScale(0.3)
    popup.alpha = 0
    popup.run(SKAction.group([
      SKAction.scale(to: 1.0, duration: 0.3),
      SKAction.fadeIn(withDuration: 0.3)
    ]))
    
    addChild(popup)
  }
  
  func showInstructionsPopup() {
    // Set popup state
    isPopupShowing = true
    
    // Create instructions popup
    let popup = SKNode()
    popup.name = "InstructionsPopup"
    popup.zPosition = 100
    
    // Background overlay
    let overlay = SKShapeNode(rect: CGRect(x: -frame.width/2, y: -frame.height/2, width: frame.width, height: frame.height))
    overlay.fillColor = .black
    overlay.alpha = 0.5
    overlay.strokeColor = .clear
    overlay.name = "PopupOverlay"
    popup.addChild(overlay)
    
    // Popup background
    let popupBg = SKShapeNode(rectOf: CGSize(width: 350, height: 400), cornerRadius: 20)
    popupBg.fillColor = currentTheme.backgroundColor
    popupBg.strokeColor = currentTheme.primaryColor
    popupBg.lineWidth = 3
    
    // Popup title
    let title = SKLabelNode(text: "How to Play")
    title.fontName = "AvenirNext-Bold"
    title.fontSize = 24
    title.fontColor = currentTheme.primaryColor
    title.position = CGPoint(x: 0, y: 150)
    title.horizontalAlignmentMode = .center
    
    // Close button
    let closeButton = SKLabelNode(text: "✕")
    closeButton.fontName = "AvenirNext-Bold"
    closeButton.fontSize = 30
    closeButton.fontColor = currentTheme.secondaryColor
    closeButton.position = CGPoint(x: 150, y: 160)
    closeButton.name = "CloseInstructions"
    
    // Instructions content
    let instructions = """
        🎯 GOAL
        Get 5 in a row to win!
        
        🕹️ CONTROLS
        • Tap to place X or O
        • Drag to scroll the infinite grid
        • Play against another player
        
        🎨 THEMES
        Use the theme button to switch
        between Neon, Classic, and Cosmic!
        
        ✨ FEATURES
        • Infinite scrollable grid
        • Two player local gameplay
        • Beautiful particle effects
        """
    
    let instructionText = SKLabelNode(text: instructions)
    instructionText.fontName = "AvenirNext-Medium"
    instructionText.fontSize = 14
    instructionText.fontColor = currentTheme.accentColor
    instructionText.numberOfLines = 0
    instructionText.horizontalAlignmentMode = .center
    instructionText.verticalAlignmentMode = .center
    instructionText.lineBreakMode = .byWordWrapping
    instructionText.preferredMaxLayoutWidth = 300
    instructionText.position = CGPoint(x: 0, y: -20)
    
    popup.addChild(popupBg)
    popup.addChild(title)
    popup.addChild(closeButton)
    popup.addChild(instructionText)
    
    // Add entrance animation
    popup.setScale(0.3)
    popup.alpha = 0
    popup.run(SKAction.group([
      SKAction.scale(to: 1.0, duration: 0.3),
      SKAction.fadeIn(withDuration: 0.3)
    ]))
    
    addChild(popup)
  }
  
  func showDifficultySelectionPopup() {
    // Set popup state
    isPopupShowing = true
    
    // Create difficulty selection popup
    let popup = SKNode()
    popup.name = "DifficultySelectionPopup"
    popup.zPosition = 100
    
    // Background overlay
    let overlay = SKShapeNode(rect: CGRect(x: -frame.width/2, y: -frame.height/2, width: frame.width, height: frame.height))
    overlay.fillColor = .black
    overlay.alpha = 0.5
    overlay.strokeColor = .clear
    overlay.name = "PopupOverlay"
    popup.addChild(overlay)
    
    // Popup background
    let popupBg = SKShapeNode(rectOf: CGSize(width: 320, height: 360), cornerRadius: 20)
    popupBg.fillColor = currentTheme.backgroundColor
    popupBg.strokeColor = currentTheme.primaryColor
    popupBg.lineWidth = 3
    
    // Popup title
    let title = SKLabelNode(text: "Choose AI Difficulty")
    title.fontName = "AvenirNext-Bold"
    title.fontSize = 22
    title.fontColor = currentTheme.primaryColor
    title.position = CGPoint(x: 0, y: 130)
    title.horizontalAlignmentMode = .center
    
    // Close button
    let closeButton = SKLabelNode(text: "✕")
    closeButton.fontName = "AvenirNext-Bold"
    closeButton.fontSize = 24
    closeButton.fontColor = currentTheme.secondaryColor
    closeButton.position = CGPoint(x: 130, y: 140)
    closeButton.name = "CloseDifficultySelection"
    
    // Difficulty buttons
    let buttonSpacing: CGFloat = 80
    let startY: CGFloat = 40
    
    // Easy button
    let easyButton = createDifficultyButton(
      text: "🙂 Easy",
      subtitle: "Relaxed AI",
      position: CGPoint(x: 0, y: startY),
      color: currentTheme.tertiaryColor,
      difficulty: .novice
    )
    
    // Intermediate button
    let intermediateButton = createDifficultyButton(
      text: "🤔 Intermediate", 
      subtitle: "Balanced AI",
      position: CGPoint(x: 0, y: startY - buttonSpacing),
      color: currentTheme.secondaryColor,
      difficulty: .intermediate
    )
    
    // Hard button
    let hardButton = createDifficultyButton(
      text: "🔥 Hard",
      subtitle: "Strategic AI",
      position: CGPoint(x: 0, y: startY - buttonSpacing * 2),
      color: currentTheme.primaryColor,
      difficulty: .advanced
    )
    
    popup.addChild(popupBg)
    popup.addChild(title)
    popup.addChild(closeButton)
    popup.addChild(easyButton)
    popup.addChild(intermediateButton)
    popup.addChild(hardButton)
    
    // Add entrance animation
    popup.setScale(0.3)
    popup.alpha = 0
    popup.run(SKAction.group([
      SKAction.scale(to: 1.0, duration: 0.3),
      SKAction.fadeIn(withDuration: 0.3)
    ]))
    
    addChild(popup)
  }
  
  func createDifficultyButton(text: String, subtitle: String, position: CGPoint, color: UIColor, difficulty: AIDifficulty) -> SKNode {
    let buttonContainer = SKNode()
    buttonContainer.name = "DifficultyButton-\(difficulty.rawValue)"
    buttonContainer.position = position
    buttonContainer.zPosition = 5
    
    // Button shadow
    let shadow = SKShapeNode(rectOf: CGSize(width: 260, height: 50), cornerRadius: 25)
    shadow.fillColor = .black
    shadow.strokeColor = .clear
    shadow.alpha = 0.2
    shadow.position = CGPoint(x: 2, y: -2)
    buttonContainer.addChild(shadow)
    
    // Button background
    let background = SKShapeNode(rectOf: CGSize(width: 260, height: 50), cornerRadius: 25)
    background.fillColor = color
    background.strokeColor = .white
    background.lineWidth = 2
    background.alpha = 0.9
    background.name = "DifficultyButton-\(difficulty.rawValue)"
    
    // Button glow effect for neon theme
    if currentTheme == .neon {
      let glow = SKShapeNode(rectOf: CGSize(width: 280, height: 60), cornerRadius: 30)
      glow.fillColor = .clear
      glow.strokeColor = color
      glow.lineWidth = 2
      glow.alpha = 0.4
      glow.zPosition = -1
      buttonContainer.addChild(glow)
      
      // Animated glow pulse
      let glowPulse = SKAction.sequence([
        SKAction.fadeAlpha(to: 0.6, duration: 1.0),
        SKAction.fadeAlpha(to: 0.2, duration: 1.0)
      ])
      glow.run(SKAction.repeatForever(glowPulse))
    }
    
    buttonContainer.addChild(background)
    
    // Main text
    let buttonText = SKLabelNode(text: text)
    buttonText.fontName = "AvenirNext-Bold"
    buttonText.fontSize = 18
    buttonText.fontColor = .white
    buttonText.verticalAlignmentMode = .center
    buttonText.horizontalAlignmentMode = .center
    buttonText.position = CGPoint(x: 0, y: 6)
    buttonText.name = "DifficultyButton-\(difficulty.rawValue)"
    
    // Subtitle text
    let subtitleText = SKLabelNode(text: subtitle)
    subtitleText.fontName = "AvenirNext-Medium"
    subtitleText.fontSize = 12
    subtitleText.fontColor = .white
    subtitleText.alpha = 0.8
    subtitleText.verticalAlignmentMode = .center
    subtitleText.horizontalAlignmentMode = .center
    subtitleText.position = CGPoint(x: 0, y: -10)
    subtitleText.name = "DifficultyButton-\(difficulty.rawValue)"
    
    // Text shadows
    let textShadow = SKLabelNode(text: text)
    textShadow.fontName = buttonText.fontName
    textShadow.fontSize = buttonText.fontSize
    textShadow.fontColor = .black
    textShadow.alpha = 0.4
    textShadow.position = CGPoint(x: 1, y: -1)
    textShadow.verticalAlignmentMode = .center
    textShadow.horizontalAlignmentMode = .center
    buttonText.addChild(textShadow)
    
    let subtitleShadow = SKLabelNode(text: subtitle)
    subtitleShadow.fontName = subtitleText.fontName
    subtitleShadow.fontSize = subtitleText.fontSize
    subtitleShadow.fontColor = .black
    subtitleShadow.alpha = 0.4
    subtitleShadow.position = CGPoint(x: 1, y: -1)
    subtitleShadow.verticalAlignmentMode = .center
    subtitleShadow.horizontalAlignmentMode = .center
    subtitleText.addChild(subtitleShadow)
    
    buttonContainer.addChild(buttonText)
    buttonContainer.addChild(subtitleText)
    
    // Subtle floating animation
    let floatUp = SKAction.moveBy(x: 0, y: 3, duration: 1.5)
    let floatDown = SKAction.moveBy(x: 0, y: -3, duration: 1.5)
    floatUp.timingMode = .easeInEaseOut
    floatDown.timingMode = .easeInEaseOut
    
    buttonContainer.run(SKAction.repeatForever(SKAction.sequence([floatUp, floatDown])))
    
    return buttonContainer
  }

  // ...existing popup methods...
  
  func closePopup(named popupName: String) {
    if let popup = childNode(withName: popupName) {
      // Reset popup state
      isPopupShowing = false
      
      popup.run(SKAction.group([
        SKAction.scale(to: 0.3, duration: 0.2),
        SKAction.fadeOut(withDuration: 0.2)
      ])) {
        popup.removeFromParent()
      }
    }
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    
    let touchLocation = touch.location(in: self)
    let touchedNodes = nodes(at: touchLocation)
    
    for node in touchedNodes {
      if node.name == "CloseSettings" {
        closePopup(named: "SettingsPopup")
        return
      } else if node.name == "CloseInstructions" {
        closePopup(named: "InstructionsPopup")
        return
      } else if node.name == "CloseDifficultySelection" {
        closePopup(named: "DifficultySelectionPopup")
        return
      } else if node.name?.hasPrefix("DifficultyButton-") == true {
        handleDifficultyButtonTap(node: node)
        return
      } else if node.name == "PopupOverlay" {
        // Close popup when tapping on overlay (outside popup content)
        if let popup = node.parent {
          closePopup(named: popup.name ?? "")
        }
        return
      }
    }
  }
}
