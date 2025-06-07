//
//  ThemeManager.swift
//  Caroo
//
//  Created by GitHub Copilot on 7/6/25.
//

import UIKit
import Foundation

class ThemeManager {
    static let shared = ThemeManager()
    
    private init() {
        // Load saved theme on initialization
        if let savedThemeRawValue = UserDefaults.standard.object(forKey: "SelectedTheme") as? String,
           let savedTheme = Theme(rawValue: savedThemeRawValue) {
            currentTheme = savedTheme
        } else {
            currentTheme = .neon // Default theme
        }
    }
    
    enum Theme: String, CaseIterable {
        case neon, classic, cosmic
        
        var backgroundColor: UIColor {
            switch self {
            case .neon: return UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)
            case .classic: return UIColor(red: 0.95, green: 0.95, blue: 0.92, alpha: 1.0)
            case .cosmic: return UIColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1.0)
            }
        }
        
        var primaryColor: UIColor {
            switch self {
            case .neon: return UIColor(red: 0.0, green: 1.0, blue: 0.6, alpha: 1.0)
            case .classic: return UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
            case .cosmic: return UIColor(red: 1.0, green: 0.3, blue: 0.6, alpha: 1.0)
            }
        }
        
        var secondaryColor: UIColor {
            switch self {
            case .neon: return UIColor(red: 1.0, green: 0.2, blue: 0.8, alpha: 1.0)
            case .classic: return UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
            case .cosmic: return UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1.0)
            }
        }
        
        var accentColor: UIColor {
            switch self {
            case .neon: return UIColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 0.8)
            case .classic: return UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 0.8)
            case .cosmic: return UIColor(red: 0.6, green: 0.3, blue: 0.9, alpha: 0.8)
            }
        }
        
        var gridColor: UIColor {
            switch self {
            case .neon: return UIColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 0.3)
            case .classic: return UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 0.6)
            case .cosmic: return UIColor(red: 0.6, green: 0.3, blue: 0.9, alpha: 0.4)
            }
        }
        
        var playerXColor: UIColor {
            switch self {
            case .neon: return UIColor(red: 0.0, green: 1.0, blue: 0.6, alpha: 1.0)
            case .classic: return UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
            case .cosmic: return UIColor(red: 1.0, green: 0.3, blue: 0.6, alpha: 1.0)
            }
        }
        
        var playerOColor: UIColor {
            switch self {
            case .neon: return UIColor(red: 1.0, green: 0.2, blue: 0.8, alpha: 1.0)
            case .classic: return UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
            case .cosmic: return UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1.0)
            }
        }
        
        // Additional colors for menu buttons
        var tertiaryColor: UIColor {
            switch self {
            case .neon: return UIColor(red: 0.8, green: 0.4, blue: 1.0, alpha: 1.0) // Purple
            case .classic: return UIColor(red: 0.2, green: 0.6, blue: 0.4, alpha: 1.0) // Green
            case .cosmic: return UIColor(red: 0.9, green: 0.6, blue: 0.2, alpha: 1.0) // Orange
            }
        }
        
        var quaternaryColor: UIColor {
            switch self {
            case .neon: return UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0) // Orange
            case .classic: return UIColor(red: 0.6, green: 0.3, blue: 0.7, alpha: 1.0) // Purple
            case .cosmic: return UIColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 1.0) // Bright Green
            }
        }
        
        var titleColor: UIColor {
            switch self {
            case .neon: return UIColor(red: 0.2, green: 1.0, blue: 0.8, alpha: 1.0) // Cyan
            case .classic: return UIColor(red: 0.1, green: 0.3, blue: 0.6, alpha: 1.0) // Dark Blue
            case .cosmic: return UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0) // Gold
            }
        }
        
        var subtitleColor: UIColor {
            switch self {
            case .neon: return UIColor(red: 0.6, green: 0.9, blue: 1.0, alpha: 0.8) // Light Blue
            case .classic: return UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.8) // Gray
            case .cosmic: return UIColor(red: 0.8, green: 0.4, blue: 1.0, alpha: 0.8) // Violet
            }
        }
    }
    
    private(set) var currentTheme: Theme {
        didSet {
            // Save theme to UserDefaults
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "SelectedTheme")
            UserDefaults.standard.synchronize()
            
            // Notify observers of theme change
            NotificationCenter.default.post(name: .themeDidChange, object: currentTheme)
        }
    }
    
    func switchToNextTheme() {
        let allThemes = Theme.allCases
        if let currentIndex = allThemes.firstIndex(of: currentTheme) {
            let nextIndex = (currentIndex + 1) % allThemes.count
            currentTheme = allThemes[nextIndex]
        }
    }
    
    func setTheme(_ theme: Theme) {
        currentTheme = theme
    }
}

// Notification name for theme changes
extension Notification.Name {
    static let themeDidChange = Notification.Name("ThemeDidChange")
}
