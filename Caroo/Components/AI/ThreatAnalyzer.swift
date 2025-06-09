//
//  ThreatAnalyzer.swift
//  Caroo
//
//  Created by AI Assistant on 09/06/25.
//

import Foundation

// MARK: - Threat Types
enum ThreatLevel: Int, Comparable {
    case none = 0
    case weak = 1           // 2 in a row with space
    case moderate = 2       // 3 in a row with space
    case strong = 3         // 4 in a row with space (critical threat)
    case immediateWin = 4   // 5 in a row possible (winning move)
    
    static func < (lhs: ThreatLevel, rhs: ThreatLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    var description: String {
        switch self {
        case .none: return "No threat"
        case .weak: return "Weak threat (2 in a row)"
        case .moderate: return "Moderate threat (3 in a row)"
        case .strong: return "Strong threat (4 in a row)"
        case .immediateWin: return "Immediate win opportunity"
        }
    }
}

// MARK: - Threat Analysis Result
struct ThreatAnalysisResult {
    let position: (row: Int, col: Int)
    let player: String
    let threatLevel: ThreatLevel
    let direction: (Int, Int)
    let consecutiveCount: Int
    let openEnds: Int
    let canComplete: Bool           // Can this threat be completed in 1 move
    let completionMoves: [(Int, Int)] // Positions where threat can be completed
    let priority: Double            // Calculated priority score
    
    var isImmediateWin: Bool {
        return threatLevel == .immediateWin
    }
    
    var isCriticalThreat: Bool {
        return threatLevel >= .strong
    }
}

// MARK: - Pattern Analysis
struct PatternAnalysis {
    let consecutiveCount: Int
    let gapPositions: [(Int, Int)]
    let openEnds: Int
    let blockedEnds: Int
    let extendableLength: Int
}

// MARK: - Threat Analyzer Class
class ThreatAnalyzer {
    
    // MARK: - Constants
    private static let winLength = 5
    private static let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
    private static let maxSearchDistance = 6
    
    // MARK: - Immediate Win Detection
    
    /// Find all immediate winning moves for a player
    /// - Parameters:
    ///   - grid: Current game state
    ///   - player: Player to find wins for
    ///   - searchArea: Area to search for performance optimization
    /// - Returns: Array of positions that would result in immediate wins
    static func findImmediateWins(in grid: [String: String], for player: String, searchArea: (minRow: Int, maxRow: Int, minCol: Int, maxCol: Int)? = nil) -> [(row: Int, col: Int)] {
        var winningMoves: [(row: Int, col: Int)] = []
        
        let area = searchArea ?? getDefaultSearchArea(for: grid)
        
        // Check each empty position in the search area
        for row in area.minRow...area.maxRow {
            for col in area.minCol...area.maxCol {
                let gridKey = "\(row),\(col)"
                
                // Skip occupied positions
                if grid[gridKey] != nil { continue }
                
                // Test if placing a piece here would create an immediate win
                if wouldCreateImmediateWin(at: row, col: col, in: grid, for: player) {
                    winningMoves.append((row, col))
                }
            }
        }
        
        return winningMoves
    }
    
    /// Check if placing a piece at the given position would create an immediate win
    /// - Parameters:
    ///   - row: Row position
    ///   - col: Column position
    ///   - grid: Current game state
    ///   - player: Player to check for
    /// - Returns: True if this move would result in an immediate win
    static func wouldCreateImmediateWin(at row: Int, col: Int, in grid: [String: String], for player: String) -> Bool {
        // Simulate placing the piece
        var simulatedGrid = grid
        simulatedGrid["\(row),\(col)"] = player
        
        // Check all directions for 5-in-a-row
        for direction in directions {
            if checkLineLength(from: row, col: col, direction: direction, in: simulatedGrid, for: player) >= winLength {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Critical Threat Detection
    
    /// Find all critical threats (4-in-a-row that need immediate blocking)
    /// - Parameters:
    ///   - grid: Current game state
    ///   - player: Player to find threats for
    ///   - searchArea: Area to search for performance optimization
    /// - Returns: Array of threat analysis results for critical threats
    static func findCriticalThreats(in grid: [String: String], for player: String, searchArea: (minRow: Int, maxRow: Int, minCol: Int, maxCol: Int)? = nil) -> [ThreatAnalysisResult] {
        var threats: [ThreatAnalysisResult] = []
        
        let area = searchArea ?? getDefaultSearchArea(for: grid)
        
        // Find all 4-in-a-row patterns that can be completed
        for row in area.minRow...area.maxRow {
            for col in area.minCol...area.maxCol {
                let gridKey = "\(row),\(col)"
                
                // Skip occupied positions
                if grid[gridKey] != nil { continue }
                
                // Check if this position would complete a 4-in-a-row for the opponent
                let threat = analyzeThreatAtPosition(row: row, col: col, in: grid, for: player)
                if threat.threatLevel >= .strong {
                    threats.append(threat)
                }
            }
        }
        
        return threats.sorted { $0.priority > $1.priority }
    }
    
    // MARK: - Comprehensive Threat Analysis
    
    /// Analyze all threats on the board for both players
    /// - Parameters:
    ///   - grid: Current game state
    ///   - currentPlayer: Current player's symbol
    ///   - opponent: Opponent player's symbol
    /// - Returns: Comprehensive threat analysis for strategic planning
    static func analyzeAllThreats(in grid: [String: String], currentPlayer: String, opponent: String) -> (ownThreats: [ThreatAnalysisResult], opponentThreats: [ThreatAnalysisResult]) {
        let searchArea = getDefaultSearchArea(for: grid)
        
        var ownThreats: [ThreatAnalysisResult] = []
        var opponentThreats: [ThreatAnalysisResult] = []
        
        for row in searchArea.minRow...searchArea.maxRow {
            for col in searchArea.minCol...searchArea.maxCol {
                let gridKey = "\(row),\(col)"
                
                // Skip occupied positions
                if grid[gridKey] != nil { continue }
                
                // Analyze threats for current player
                let ownThreat = analyzeThreatAtPosition(row: row, col: col, in: grid, for: currentPlayer)
                if ownThreat.threatLevel > .none {
                    ownThreats.append(ownThreat)
                }
                
                // Analyze threats for opponent
                let opponentThreat = analyzeThreatAtPosition(row: row, col: col, in: grid, for: opponent)
                if opponentThreat.threatLevel > .none {
                    opponentThreats.append(opponentThreat)
                }
            }
        }
        
        // Sort by priority (highest first)
        ownThreats.sort { $0.priority > $1.priority }
        opponentThreats.sort { $0.priority > $1.priority }
        
        return (ownThreats, opponentThreats)
    }
    
    // MARK: - Pattern Recognition
    
    /// Analyze a specific pattern at a position for a player
    /// - Parameters:
    ///   - row: Row position
    ///   - col: Column position
    ///   - grid: Current game state
    ///   - player: Player to analyze for
    /// - Returns: Detailed pattern analysis
    static func analyzePattern(at row: Int, col: Int, in grid: [String: String], for player: String, direction: (Int, Int)) -> PatternAnalysis {
        var consecutiveCount = 0
        var gapPositions: [(Int, Int)] = []
        var openEnds = 0
        var blockedEnds = 0
        
        // Analyze pattern in both directions
        for multiplier in [-1, 1] {
            var currentRow = row + direction.0 * multiplier
            var currentCol = col + direction.1 * multiplier
            var foundGap = false
            var endBlocked = false
            
            for _ in 1...maxSearchDistance {
                let gridKey = "\(currentRow),\(currentCol)"
                let cellValue = grid[gridKey]
                
                if cellValue == player {
                    if !foundGap {
                        consecutiveCount += 1
                    }
                } else if cellValue == nil && !foundGap {
                    // First empty space - potential extension
                    gapPositions.append((currentRow, currentCol))
                    foundGap = true
                    openEnds += 1
                } else if cellValue != nil && cellValue != player {
                    // Opponent piece - blocked
                    endBlocked = true
                    blockedEnds += 1
                    break
                } else {
                    // Second empty space or already found gap
                    if !endBlocked {
                        openEnds += 1
                    }
                    break
                }
                
                currentRow += direction.0 * multiplier
                currentCol += direction.1 * multiplier
            }
        }
        
        let extendableLength = consecutiveCount + gapPositions.count + min(openEnds, 2)
        
        return PatternAnalysis(
            consecutiveCount: consecutiveCount,
            gapPositions: gapPositions,
            openEnds: openEnds,
            blockedEnds: blockedEnds,
            extendableLength: extendableLength
        )
    }
    
    // MARK: - Private Helper Methods
    
    /// Analyze threat level at a specific position
    private static func analyzeThreatAtPosition(row: Int, col: Int, in grid: [String: String], for player: String) -> ThreatAnalysisResult {
        var bestThreat = ThreatAnalysisResult(
            position: (row, col),
            player: player,
            threatLevel: .none,
            direction: (0, 0),
            consecutiveCount: 0,
            openEnds: 0,
            canComplete: false,
            completionMoves: [],
            priority: 0.0
        )
        
        // Check all directions
        for direction in directions {
            let threat = analyzeThreatInDirection(row: row, col: col, direction: direction, in: grid, for: player)
            
            // Keep the highest threat level
            if threat.threatLevel > bestThreat.threatLevel {
                bestThreat = threat
            } else if threat.threatLevel == bestThreat.threatLevel && threat.priority > bestThreat.priority {
                bestThreat = threat
            }
        }
        
        return bestThreat
    }
    
    /// Analyze threat in a specific direction
    private static func analyzeThreatInDirection(row: Int, col: Int, direction: (Int, Int), in grid: [String: String], for player: String) -> ThreatAnalysisResult {
        // Simulate placing the piece
        var simulatedGrid = grid
        simulatedGrid["\(row),\(col)"] = player
        
        let lineLength = checkLineLength(from: row, col: col, direction: direction, in: simulatedGrid, for: player)
        let pattern = analyzePattern(at: row, col: col, in: grid, for: player, direction: direction)
        
        var threatLevel: ThreatLevel = .none
        var canComplete = false
        var completionMoves: [(Int, Int)] = []
        var priority: Double = 0.0
        
        // Determine threat level based on line length and pattern
        if lineLength >= winLength {
            threatLevel = .immediateWin
            canComplete = true
            completionMoves.append((row, col))
            priority = 1000.0
        } else if lineLength == winLength - 1 {
            threatLevel = .strong
            canComplete = pattern.openEnds > 0
            priority = 100.0 + Double(pattern.openEnds) * 10.0
        } else if lineLength == winLength - 2 {
            threatLevel = .moderate
            canComplete = pattern.openEnds >= 2
            priority = 10.0 + Double(pattern.openEnds) * 2.0
        } else if lineLength == winLength - 3 {
            threatLevel = .weak
            canComplete = pattern.openEnds >= 3
            priority = 1.0 + Double(pattern.openEnds) * 0.5
        }
        
        // Adjust priority based on open ends and pattern strength
        priority += Double(pattern.openEnds) * 5.0
        priority += Double(pattern.consecutiveCount) * 2.0
        
        return ThreatAnalysisResult(
            position: (row, col),
            player: player,
            threatLevel: threatLevel,
            direction: direction,
            consecutiveCount: pattern.consecutiveCount,
            openEnds: pattern.openEnds,
            canComplete: canComplete,
            completionMoves: completionMoves,
            priority: priority
        )
    }
    
    /// Check line length in a specific direction
    private static func checkLineLength(from row: Int, col: Int, direction: (Int, Int), in grid: [String: String], for player: String) -> Int {
        var count = 1 // Count the starting position
        
        // Check both directions
        for multiplier in [-1, 1] {
            var currentRow = row + direction.0 * multiplier
            var currentCol = col + direction.1 * multiplier
            
            while grid["\(currentRow),\(currentCol)"] == player {
                count += 1
                currentRow += direction.0 * multiplier
                currentCol += direction.1 * multiplier
            }
        }
        
        return count
    }
    
    /// Get default search area around existing pieces
    private static func getDefaultSearchArea(for grid: [String: String]) -> (minRow: Int, maxRow: Int, minCol: Int, maxCol: Int) {
        guard !grid.isEmpty else {
            return (-3, 3, -3, 3)
        }
        
        var minRow = Int.max
        var maxRow = Int.min
        var minCol = Int.max
        var maxCol = Int.min
        
        for gridKey in grid.keys {
            let components = gridKey.split(separator: ",")
            if let row = Int(components[0]), let col = Int(components[1]) {
                minRow = min(minRow, row)
                maxRow = max(maxRow, row)
                minCol = min(minCol, col)
                maxCol = max(maxCol, col)
            }
        }
        
        // Expand search area by 3 cells in each direction
        let buffer = 3
        return (minRow - buffer, maxRow + buffer, minCol - buffer, maxCol + buffer)
    }
}

// MARK: - Threat Analyzer Extensions for AI Integration

extension ThreatAnalyzer {
    
    /// Get the best immediate win move for AI
    static func getBestImmediateWin(in grid: [String: String], for player: String) -> (row: Int, col: Int)? {
        let winningMoves = findImmediateWins(in: grid, for: player)
        
        if winningMoves.isEmpty {
            return nil
        }
        
        // If multiple winning moves exist, prefer central positions
        return winningMoves.min { move1, move2 in
            let distance1 = abs(move1.row) + abs(move1.col)
            let distance2 = abs(move2.row) + abs(move2.col)
            return distance1 < distance2
        }
    }
    
    /// Get the most critical threat that needs blocking
    static func getMostCriticalThreatToBlock(in grid: [String: String], against opponent: String) -> (row: Int, col: Int)? {
        let threats = findCriticalThreats(in: grid, for: opponent)
        
        return threats.first(where: { $0.threatLevel >= .strong })?.position
    }
    
    // MARK: - Enhanced Blocking Methods
    
    /// Find all positions that would block critical threats from the opponent
    /// - Parameters:
    ///   - grid: Current game state
    ///   - opponent: Opponent player symbol to block threats from
    ///   - searchArea: Optional search area for performance optimization
    /// - Returns: Array of blocking moves sorted by priority
    static func findAllCriticalBlockingMoves(in grid: [String: String], against opponent: String, searchArea: (minRow: Int, maxRow: Int, minCol: Int, maxCol: Int)? = nil) -> [(position: (row: Int, col: Int), priority: Double, threatLevel: ThreatLevel)] {
        let threats = findCriticalThreats(in: grid, for: opponent, searchArea: searchArea)
        
        var blockingMoves: [(position: (row: Int, col: Int), priority: Double, threatLevel: ThreatLevel)] = []
        
        for threat in threats {
            if threat.threatLevel >= .strong && threat.canComplete {
                // Calculate blocking priority based on threat level and pattern strength
                var blockingPriority = threat.priority
                
                // Immediate wins need highest priority blocking
                if threat.threatLevel == .immediateWin {
                    blockingPriority = 950.0
                } else if threat.threatLevel == .strong {
                    blockingPriority = 850.0 + Double(threat.openEnds) * 10.0
                }
                
                // Adjust priority based on pattern characteristics
                if threat.openEnds >= 2 {
                    blockingPriority += 20.0 // Open threats are more dangerous
                }
                
                blockingMoves.append((
                    position: threat.position,
                    priority: blockingPriority,
                    threatLevel: threat.threatLevel
                ))
            }
        }
        
        // Sort by priority (highest first)
        return blockingMoves.sorted { $0.priority > $1.priority }
    }
    
    /// Get the best critical blocking move considering multiple factors
    /// - Parameters:
    ///   - grid: Current game state
    ///   - opponent: Opponent player symbol
    ///   - currentPlayer: Current player symbol (for dual-purpose move evaluation)
    /// - Returns: Best blocking position with detailed analysis
    static func getBestCriticalBlockingMove(in grid: [String: String], against opponent: String, currentPlayer: String) -> (position: (row: Int, col: Int), priority: Double, isDualPurpose: Bool)? {
        let blockingMoves = findAllCriticalBlockingMoves(in: grid, against: opponent)
        
        guard !blockingMoves.isEmpty else { return nil }
        
        var bestMove = blockingMoves[0]
        var isDualPurpose = false
        
        // Check if the blocking move also creates a threat for current player
        for blockingMove in blockingMoves.prefix(3) { // Check top 3 moves for dual purpose
            if wouldCreateSignificantThreat(at: blockingMove.position.row, col: blockingMove.position.col, in: grid, for: currentPlayer) {
                bestMove = blockingMove
                isDualPurpose = true
                break
            }
        }
        
        return (position: bestMove.position, priority: bestMove.priority, isDualPurpose: isDualPurpose)
    }
    
    /// Check if placing a piece would create a significant threat (3+ in a row)
    /// - Parameters:
    ///   - row: Row position
    ///   - col: Column position
    ///   - grid: Current game state
    ///   - player: Player to check threat creation for
    /// - Returns: True if move creates a significant threat
    static func wouldCreateSignificantThreat(at row: Int, col: Int, in grid: [String: String], for player: String) -> Bool {
        // Simulate placing the piece
        var simulatedGrid = grid
        simulatedGrid["\(row),\(col)"] = player
        
        // Check all directions for threat creation
        for direction in directions {
            let lineLength = checkLineLength(from: row, col: col, direction: direction, in: simulatedGrid, for: player)
            if lineLength >= 3 {
                return true
            }
        }
        
        return false
    }
    
    /// Find positions that would block multiple threats simultaneously
    /// - Parameters:
    ///   - grid: Current game state
    ///   - opponent: Opponent player symbol
    /// - Returns: Array of positions that block multiple threats
    static func findMultiThreatBlockingMoves(in grid: [String: String], against opponent: String) -> [(position: (row: Int, col: Int), threatsBlocked: Int, totalPriority: Double)] {
        let allThreats = findCriticalThreats(in: grid, for: opponent)
        var blockingPositions: [String: [(threat: ThreatAnalysisResult, priority: Double)]] = [:]
        
        // Group threats by blocking position
        for threat in allThreats {
            if threat.threatLevel >= .moderate && threat.canComplete {
                let positionKey = "\(threat.position.row),\(threat.position.col)"
                let priority = threat.threatLevel == .immediateWin ? 1000.0 : 
                              threat.threatLevel == .strong ? 800.0 : 400.0
                
                if blockingPositions[positionKey] == nil {
                    blockingPositions[positionKey] = []
                }
                blockingPositions[positionKey]?.append((threat: threat, priority: priority))
            }
        }
        
        // Find positions that block multiple threats
        var multiThreatBlocks: [(position: (row: Int, col: Int), threatsBlocked: Int, totalPriority: Double)] = []
        
        for (positionKey, threats) in blockingPositions {
            if threats.count > 1 {
                let components = positionKey.split(separator: ",")
                if let row = Int(components[0]), let col = Int(components[1]) {
                    let totalPriority = threats.reduce(0.0) { $0 + $1.priority }
                    multiThreatBlocks.append((
                        position: (row, col),
                        threatsBlocked: threats.count,
                        totalPriority: totalPriority
                    ))
                }
            }
        }
        
        return multiThreatBlocks.sorted { $0.totalPriority > $1.totalPriority }
    }
    
    /// Check if a position would block an opponent's critical threat
    static func wouldBlockCriticalThreat(at row: Int, col: Int, in grid: [String: String], against opponent: String) -> Bool {
        let threatsToBlock = findCriticalThreats(in: grid, for: opponent)
        
        return threatsToBlock.contains { threat in
            threat.position.row == row && threat.position.col == col
        }
    }
}
