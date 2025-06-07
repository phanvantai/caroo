//
//  WinPopup.swift
//  Caroo
//
//  Created by Tai Phan Van on 15/1/25.
//

import Foundation
import SpriteKit

class WinPopup: SKNode {
  init(size: CGSize, winner: String, theme: ThemeManager.Theme) {
    super.init()
    self.name = "WinPopup"
    self.isUserInteractionEnabled = false // Don't intercept touches - let them pass through
    
    // Setup container with enhanced background blur that blocks all touches
    let blurBackground = SKShapeNode(rectOf: size)
    blurBackground.fillColor = .black
    blurBackground.strokeColor = .clear
    blurBackground.alpha = 0.4
    blurBackground.zPosition = 999
    blurBackground.isUserInteractionEnabled = true // This blocks background touches
    addChild(blurBackground)
    
    // Create animated background particles
    createBackgroundParticles(size: size, theme: theme)
    
    // Create main popup container with enhanced design
    let popup = createMainPopup(theme: theme)
    popup.zPosition = 1000 // Ensure popup is above the blur background
    
    // Add winner content
    let winContent = createWinContent(winner: winner, theme: theme)
    popup.addChild(winContent)
    
    // Add enhanced play again button
    let playAgainButton = createPlayAgainButton(theme: theme)
    popup.addChild(playAgainButton)
    
    addChild(popup)
    
    // Enhanced entrance animation
    popup.setScale(0.1)
    popup.alpha = 0
    popup.zRotation = CGFloat.pi
    
    let appearSequence = SKAction.group([
      SKAction.scale(to: 1.1, duration: 0.5),
      SKAction.fadeIn(withDuration: 0.5),
      SKAction.rotate(toAngle: 0, duration: 0.5)
    ])
    
    let bounceBack = SKAction.sequence([
        SKAction.scale(to: 0.95, duration: 0.1),
        SKAction.scale(to: 1.0, duration: 0.1)
    ])
    
    popup.run(SKAction.sequence([
      appearSequence,
      bounceBack
    ]))
    
    // Add floating animation
    let float = SKAction.sequence([
        SKAction.moveBy(x: 0, y: 10, duration: 2.0),
        SKAction.moveBy(x: 0, y: -10, duration: 2.0)
    ])
    float.timingMode = .easeInEaseOut
    popup.run(SKAction.repeatForever(float))
  }
  
  private func createBackgroundParticles(size: CGSize, theme: ThemeManager.Theme) {
    for _ in 0..<20 {
        let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
        particle.fillColor = theme.playerXColor
        particle.alpha = 0.6
        particle.position = CGPoint(
            x: CGFloat.random(in: -size.width/2...size.width/2),
            y: CGFloat.random(in: -size.height/2...size.height/2)
        )
        particle.zPosition = 10
        
        let moveAction = SKAction.moveBy(x: CGFloat.random(in: -50...50), y: CGFloat.random(in: -50...50), duration: 3.0)
        let fadeAction = SKAction.sequence([
            SKAction.fadeIn(withDuration: 1.5),
            SKAction.fadeOut(withDuration: 1.5)
        ])
        
        particle.run(SKAction.repeatForever(SKAction.group([moveAction, fadeAction])))
        addChild(particle)
    }
  }
  
  private func createMainPopup(theme: ThemeManager.Theme) -> SKNode {
    let popup = SKNode()
    popup.zPosition = 100
    
    // Create shadow
    let shadow = SKShapeNode(rectOf: CGSize(width: 350, height: 250), cornerRadius: 25)
    shadow.fillColor = .black
    shadow.strokeColor = .clear
    shadow.alpha = 0.3
    shadow.position = CGPoint(x: 5, y: -5)
    popup.addChild(shadow)
    
    // Create main background with theme colors
    let background = SKShapeNode(rectOf: CGSize(width: 350, height: 250), cornerRadius: 25)
    background.fillColor = theme.backgroundColor
    background.strokeColor = theme.playerXColor
    background.lineWidth = 4
    
    // Add glow effect for neon theme
    if case .neon = theme {
        background.glowWidth = 8
    }
    
    // Add gradient overlay
    let gradientOverlay = SKShapeNode(rectOf: CGSize(width: 340, height: 240), cornerRadius: 22)
    gradientOverlay.fillColor = .white
    gradientOverlay.strokeColor = .clear
    gradientOverlay.alpha = {
        if case .neon = theme { return 0.1 }
        return 0.3
    }()
    background.addChild(gradientOverlay)
    
    popup.addChild(background)
    return popup
  }
  
  private func createWinContent(winner: String, theme: ThemeManager.Theme) -> SKNode {
    let content = SKNode()
    content.position = CGPoint(x: 0, y: 40)
    
    // Add trophy emoji
    let trophy = SKLabelNode(text: "🏆")
    trophy.fontSize = 50
    trophy.position = CGPoint(x: 0, y: 60)
    content.addChild(trophy)
    
    // Animate trophy
    let trophyBounce = SKAction.sequence([
        SKAction.scale(to: 1.2, duration: 0.5),
        SKAction.scale(to: 1.0, duration: 0.5)
    ])
    trophy.run(SKAction.repeatForever(trophyBounce))
    
    // Add win text with enhanced styling
    let winText = SKLabelNode(text: "\(winner) Wins!")
    winText.fontName = "Futura-Bold"
    winText.fontSize = 38
    winText.fontColor = winner == "X" ? theme.playerXColor : theme.playerOColor
    winText.position = CGPoint(x: 0, y: 10)
    
    // Add text shadow
    let winTextShadow = SKLabelNode(text: winText.text)
    winTextShadow.fontName = winText.fontName
    winTextShadow.fontSize = winText.fontSize
    winTextShadow.fontColor = .black
    winTextShadow.alpha = 0.3
    winTextShadow.position = CGPoint(x: 2, y: -2)
    winText.addChild(winTextShadow)
    
    // Add text animation
    let textPulse = SKAction.sequence([
        SKAction.scale(to: 1.1, duration: 0.8),
        SKAction.scale(to: 1.0, duration: 0.8)
    ])
    winText.run(SKAction.repeatForever(textPulse))
    
    content.addChild(winText)
    
    // Add congratulations message
    let congrats = SKLabelNode(text: "🎉 Congratulations! 🎉")
    congrats.fontName = "Optima-Bold"
    congrats.fontSize = 20
    congrats.fontColor = {
        if case .classic = theme { return .darkGray }
        return .white
    }()
    congrats.position = CGPoint(x: 0, y: -25)
    content.addChild(congrats)
    
    return content
  }
  
  private func createPlayAgainButton(theme: ThemeManager.Theme) -> SKNode {
    let buttonContainer = SKNode()
    buttonContainer.position = CGPoint(x: 0, y: -70)
    
    // Create button shadow
    let buttonShadow = SKShapeNode(rectOf: CGSize(width: 220, height: 55), cornerRadius: 27.5)
    buttonShadow.fillColor = .black
    buttonShadow.strokeColor = .clear
    buttonShadow.alpha = 0.3
    buttonShadow.position = CGPoint(x: 3, y: -3)
    buttonContainer.addChild(buttonShadow)
    
    // Create main button
    let buttonBackground = SKShapeNode(rectOf: CGSize(width: 220, height: 55), cornerRadius: 27.5)
    buttonBackground.fillColor = theme.playerOColor
    buttonBackground.strokeColor = .white
    buttonBackground.lineWidth = 3
    buttonBackground.name = "PopupRestartButton"
    
    // Add glow effect for neon theme
    if case .neon = theme {
        buttonBackground.glowWidth = 6
    }
    
    // Add inner highlight
    let innerHighlight = SKShapeNode(rectOf: CGSize(width: 210, height: 45), cornerRadius: 22.5)
    innerHighlight.fillColor = .clear
    innerHighlight.strokeColor = .white
    innerHighlight.lineWidth = 1
    innerHighlight.alpha = 0.6
    buttonBackground.addChild(innerHighlight)
    
    // Add button text with emoji
    let buttonText = SKLabelNode(text: "🎮 Play Again")
    buttonText.fontName = "Trebuchet MS-Bold"
    buttonText.fontSize = 24
    buttonText.fontColor = .white
    buttonText.verticalAlignmentMode = .center
    buttonText.name = "PopupRestartButton"
    
    // Add text shadow
    let textShadow = SKLabelNode(text: buttonText.text)
    textShadow.fontName = buttonText.fontName
    textShadow.fontSize = buttonText.fontSize
    textShadow.fontColor = .black
    textShadow.alpha = 0.4
    textShadow.position = CGPoint(x: 1, y: -1)
    textShadow.verticalAlignmentMode = .center
    buttonText.addChild(textShadow)
    
    buttonBackground.addChild(buttonText)
    buttonContainer.addChild(buttonBackground)
    
    // Enhanced button animations
    let pulseUp = SKAction.scale(to: 1.08, duration: 1.2)
    let pulseDown = SKAction.scale(to: 0.95, duration: 1.2)
    pulseUp.timingMode = .easeInEaseOut
    pulseDown.timingMode = .easeInEaseOut
    
    buttonBackground.run(SKAction.repeatForever(SKAction.sequence([
      pulseUp,
      pulseDown
    ])))
    
    // Add glow pulse for neon theme
    if case .neon = theme {
        let glowPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.6, duration: 1.2),
            SKAction.fadeAlpha(to: 1.0, duration: 1.2)
        ])
        buttonBackground.run(SKAction.repeatForever(glowPulse))
    }
    
    return buttonContainer
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
