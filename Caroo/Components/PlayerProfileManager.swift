//
//  PlayerProfileManager.swift
//  Caroo
//
//  Player performance tracking and adaptive difficulty management
//

import Foundation

class PlayerProfileManager {
    
    // MARK: - Singleton
    static let shared = PlayerProfileManager()
    
    // MARK: - Player Statistics
    struct PlayerStats {
        var totalGames: Int = 0
        var playerWins: Int = 0
        var aiWins: Int = 0
        var averageTurnsToWin: Double = 0.0
        var currentWinStreak: Int = 0
        var currentLossStreak: Int = 0
        var longestWinStreak: Int = 0
        var totalTurnsPlayed: Int = 0
        
        var winRate: Double {
            return totalGames > 0 ? Double(playerWins) / Double(totalGames) : 0.0
        }
        
        var lossRate: Double {
            return totalGames > 0 ? Double(aiWins) / Double(totalGames) : 0.0
        }
    }
    
    // MARK: - Properties
    private var playerStats = PlayerStats()
    private let userDefaults = UserDefaults.standard
    
    // Keys for UserDefaults
    private let totalGamesKey = "PlayerStats_TotalGames"
    private let playerWinsKey = "PlayerStats_PlayerWins"
    private let aiWinsKey = "PlayerStats_AIWins"
    private let averageTurnsKey = "PlayerStats_AverageTurns"
    private let currentWinStreakKey = "PlayerStats_CurrentWinStreak"
    private let currentLossStreakKey = "PlayerStats_CurrentLossStreak"
    private let longestWinStreakKey = "PlayerStats_LongestWinStreak"
    private let totalTurnsPlayedKey = "PlayerStats_TotalTurnsPlayed"
    
    // MARK: - Initialization
    private init() {
        loadPlayerStats()
    }
    
    // MARK: - Public Methods
    
    func recordGameResult(playerWon: Bool, turnsPlayed: Int) {
        playerStats.totalGames += 1
        playerStats.totalTurnsPlayed += turnsPlayed
        
        if playerWon {
            playerStats.playerWins += 1
            playerStats.currentWinStreak += 1
            playerStats.currentLossStreak = 0
            
            if playerStats.currentWinStreak > playerStats.longestWinStreak {
                playerStats.longestWinStreak = playerStats.currentWinStreak
            }
        } else {
            playerStats.aiWins += 1
            playerStats.currentLossStreak += 1
            playerStats.currentWinStreak = 0
        }
        
        // Update average turns to win (only count player wins)
        if playerStats.playerWins > 0 {
            playerStats.averageTurnsToWin = Double(playerStats.totalTurnsPlayed) / Double(playerStats.playerWins)
        }
        
        savePlayerStats()
        adjustAIDifficultyIfNeeded()
    }
    
    func getCurrentStats() -> PlayerStats {
        return playerStats
    }
    
    func resetStats() {
        playerStats = PlayerStats()
        savePlayerStats()
    }
    
    // MARK: - Adaptive Difficulty Logic
    
    private func adjustAIDifficultyIfNeeded() {
        // Only adjust if we have enough data (at least 3 games) and using adaptive mode
        guard playerStats.totalGames >= 3 && AIBot.shared.currentDifficulty == .adaptive else { return }
        
        let currentEffectiveDifficulty = AIBot.shared.getCurrentEffectiveDifficulty()
        let winRate = playerStats.winRate
        
        // Check for adjustment triggers
        var newDifficulty: AIBot.Difficulty?
        
        // Player winning too much (>75% win rate or 3+ win streak)
        if winRate > 0.75 || playerStats.currentWinStreak >= 3 {
            newDifficulty = getNextHigherDifficulty(current: currentEffectiveDifficulty)
        }
        // Player losing too much (<25% win rate or 3+ loss streak)
        else if winRate < 0.25 || playerStats.currentLossStreak >= 3 {
            newDifficulty = getNextLowerDifficulty(current: currentEffectiveDifficulty)
        }
        // Player has very quick wins (much faster than average)
        else if playerStats.averageTurnsToWin < 10 && playerStats.playerWins >= 2 {
            newDifficulty = getNextHigherDifficulty(current: currentEffectiveDifficulty)
        }
        
        // Apply the difficulty change if needed
        if let newDifficulty = newDifficulty, newDifficulty != currentEffectiveDifficulty {
            AIBot.shared.setAdaptiveDifficulty(newDifficulty, reason: getDifficultyChangeReason())
        }
    }
    
    private func getNextHigherDifficulty(current: AIBot.Difficulty) -> AIBot.Difficulty? {
        switch current {
        case .medium: return .hard
        case .hard: return .expert
        case .expert, .adaptive: return nil // Already at maximum
        }
    }
    
    private func getNextLowerDifficulty(current: AIBot.Difficulty) -> AIBot.Difficulty? {
        switch current {
        case .expert: return .hard
        case .hard: return .medium
        case .medium, .adaptive: return nil // Already at minimum
        }
    }
    
    private func getDifficultyChangeReason() -> String {
        let winRate = playerStats.winRate
        
        if playerStats.currentWinStreak >= 3 {
            return "🔥 On a winning streak!"
        } else if playerStats.currentLossStreak >= 3 {
            return "💪 Making it easier"
        } else if winRate > 0.75 {
            return "🎯 Increasing challenge"
        } else if winRate < 0.25 {
            return "🤝 Adjusting difficulty"
        } else if playerStats.averageTurnsToWin < 10 {
            return "⚡ Quick wins detected"
        } else {
            return "🧠 Adaptive adjustment"
        }
    }
    
    // MARK: - Persistence
    
    private func savePlayerStats() {
        userDefaults.set(playerStats.totalGames, forKey: totalGamesKey)
        userDefaults.set(playerStats.playerWins, forKey: playerWinsKey)
        userDefaults.set(playerStats.aiWins, forKey: aiWinsKey)
        userDefaults.set(playerStats.averageTurnsToWin, forKey: averageTurnsKey)
        userDefaults.set(playerStats.currentWinStreak, forKey: currentWinStreakKey)
        userDefaults.set(playerStats.currentLossStreak, forKey: currentLossStreakKey)
        userDefaults.set(playerStats.longestWinStreak, forKey: longestWinStreakKey)
        userDefaults.set(playerStats.totalTurnsPlayed, forKey: totalTurnsPlayedKey)
    }
    
    private func loadPlayerStats() {
        playerStats.totalGames = userDefaults.integer(forKey: totalGamesKey)
        playerStats.playerWins = userDefaults.integer(forKey: playerWinsKey)
        playerStats.aiWins = userDefaults.integer(forKey: aiWinsKey)
        playerStats.averageTurnsToWin = userDefaults.double(forKey: averageTurnsKey)
        playerStats.currentWinStreak = userDefaults.integer(forKey: currentWinStreakKey)
        playerStats.currentLossStreak = userDefaults.integer(forKey: currentLossStreakKey)
        playerStats.longestWinStreak = userDefaults.integer(forKey: longestWinStreakKey)
        playerStats.totalTurnsPlayed = userDefaults.integer(forKey: totalTurnsPlayedKey)
    }
}
