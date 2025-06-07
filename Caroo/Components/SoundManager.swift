//
//  SoundManager.swift
//  Caroo
//
//  Created by Tai Phan Van on 15/1/25.
//

import Foundation
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private init() {}
    
    func playPlaceMarkSound() {
        // Create a simple system sound for placing marks
        AudioServicesPlaySystemSound(1104) // Pop sound
    }
    
    func playWinSound() {
        // Create a celebratory sound for winning
        AudioServicesPlaySystemSound(1016) // SMS received sound
    }
    
    func playButtonSound() {
        // Create a button tap sound
        AudioServicesPlaySystemSound(1123) // Begin recording sound
    }
    
    func playThemeSwitchSound() {
        // Create a theme switch sound
        AudioServicesPlaySystemSound(1103) // Mail sent sound
    }
}
