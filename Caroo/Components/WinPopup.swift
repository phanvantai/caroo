//
//  WinPopup.swift
//  Caroo
//
//  Created by Tai Phan Van on 15/1/25.
//

import Foundation
import SpriteKit

class WinPopup: SKNode {
  init(size: CGSize, winner: String) {
    super.init()
    self.name = "WinPopup"  // Add name to the popup node
    
    // Setup container with background blur
    let blurBackground = SKShapeNode(rectOf: size)
    blurBackground.fillColor = .black
    blurBackground.strokeColor = .clear
    blurBackground.alpha = 0.3
    addChild(blurBackground)
    
    // Create popup container with shadow
    let popup = SKShapeNode(rectOf: CGSize(width: 300, height: 200), cornerRadius: 20)
    popup.fillColor = .white
    popup.strokeColor = .systemBlue
    popup.lineWidth = 3
    popup.zPosition = 100
    
    // Add gradient overlay
    let gradientOverlay = SKShapeNode(rectOf: CGSize(width: 296, height: 196), cornerRadius: 18)
    gradientOverlay.fillColor = .white
    gradientOverlay.strokeColor = .white
    gradientOverlay.alpha = 0.5
    popup.addChild(gradientOverlay)
    
    // Add win text with animation
    let winText = SKLabelNode(text: "\(winner) Wins!")
    winText.fontName = "AvenirNext-Bold"
    winText.fontSize = 40
    winText.fontColor = .systemBlue
    winText.position = CGPoint(x: 0, y: 20)
    
    // Add text shadow
    let winTextShadow = SKLabelNode(text: winText.text)
    winTextShadow.fontName = winText.fontName
    winTextShadow.fontSize = winText.fontSize
    winTextShadow.fontColor = .black
    winTextShadow.alpha = 0.2
    winTextShadow.position = CGPoint(x: 2, y: -2)
    winText.addChild(winTextShadow)
    
    // Create play again button
    let buttonBackground = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 25)
    buttonBackground.fillColor = .systemBlue
    buttonBackground.strokeColor = .white
    buttonBackground.lineWidth = 2
    buttonBackground.position = CGPoint(x: 0, y: -40)
    buttonBackground.name = "PopupRestartButton"
    
    // Add button text with the same name for touch handling
    let buttonText = SKLabelNode(text: "Play Again")
    buttonText.fontName = "AvenirNext-Bold"
    buttonText.fontSize = 24
    buttonText.fontColor = .white
    buttonText.verticalAlignmentMode = .center
    buttonText.name = "PopupRestartButton"  // Same name as background for consistent touch handling
    buttonBackground.addChild(buttonText)
    
    // Add button shadow
    let buttonShadow = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 25)
    buttonShadow.fillColor = .black
    buttonShadow.strokeColor = .clear
    buttonShadow.alpha = 0.2
    buttonShadow.position = CGPoint(x: 0, y: -4)
    buttonBackground.insertChild(buttonShadow, at: 0)
    
    // Add elements to popup
    popup.addChild(winText)
    popup.addChild(buttonBackground)
    addChild(popup)
    
    // Add animations
    popup.setScale(0.5)
    popup.alpha = 0
    
    let appearSequence = SKAction.group([
      SKAction.scale(to: 1.1, duration: 0.3),
      SKAction.fadeIn(withDuration: 0.3)
    ])
    
    let bounceBack = SKAction.scale(to: 1.0, duration: 0.1)
    
    popup.run(SKAction.sequence([
      appearSequence,
      bounceBack
    ]))
    
    // Add button hover animation
    let pulseUp = SKAction.scale(to: 1.05, duration: 1.0)
    let pulseDown = SKAction.scale(to: 0.95, duration: 1.0)
    pulseUp.timingMode = .easeInEaseOut
    pulseDown.timingMode = .easeInEaseOut
    
    buttonBackground.run(SKAction.repeatForever(SKAction.sequence([
      pulseUp,
      pulseDown
    ])))
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
