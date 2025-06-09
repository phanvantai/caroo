//
//  AIBot.swift
//  Caroo
//
//  Completely rewritten AI bot with proper strategic thinking
//

import Foundation
import GameplayKit

class AIBot {
    
    // MARK: - AI Difficulty Levels
    enum Difficulty: String, CaseIterable {
        case medium = "Medium"
        case hard = "Hard"
        case expert = "Expert"
        case adaptive = "Adaptive"
        
        var description: String {
            switch self {
            case .medium: return "🤖 Medium - Strategic AI"
            case .hard: return "🧠 Hard - Smart AI"
            case .expert: return "⚡ Expert - Master AI"
            case .adaptive: return "🧠 Adaptive - Smart Learning AI"
            }
        }
        
        var thinkingTime: Double {
            switch self {
            case .medium: return 0.5
            case .hard: return 0.8
            case .expert: return 1.2
            case .adaptive: return 0.7 // Base time, adjusted dynamically
            }
        }
        
        var mctsIterations: Int {
            switch self {
            case .medium: return 250
            case .hard: return 500
            case .expert: return 800
            case .adaptive: return 400 // Base value, adjusted dynamically
            }
        }
    }
    
    // MARK: - Properties
    static let shared = AIBot()
    private let randomSource = GKRandomSource.sharedRandom()
    private let mctsEngine = MCTSEngine()
    
    var currentDifficulty: Difficulty = .medium {
        didSet {
            UserDefaults.standard.set(currentDifficulty.rawValue, forKey: "AIBotDifficulty")
        }
    }
    
    // Adaptive difficulty properties
    private var adaptiveDifficultyLevel: Difficulty = .medium
    private var adaptiveIterations: Int = 500
    private var difficultyChangeReason: String?
    
    // MARK: - Initialization
    private init() {
        // Load saved difficulty
        if let savedDifficulty = UserDefaults.standard.string(forKey: "AIBotDifficulty"),
           let difficulty = Difficulty(rawValue: savedDifficulty) {
            currentDifficulty = difficulty
        }
    }
    
    // MARK: - Main AI Decision Engine
    func findBestMove(for grid: [String: String], player: String = "O", opponent: String = "X") -> (row: Int, col: Int)? {
        
        let availableMoves = getAvailableMoves(from: grid)
        guard !availableMoves.isEmpty else { return nil }
        
        print("🤖 AI (\(currentDifficulty.rawValue)) analyzing \(availableMoves.count) available moves")
        
        // Opening book for early game
        if let openingMove = getOpeningMove(grid: grid, player: player, opponent: opponent) {
            print("📚 Using opening book move")
            return openingMove
        }
        
        // Determine effective difficulty for adaptive mode
        let effectiveDifficulty = currentDifficulty == .adaptive ? adaptiveDifficultyLevel : currentDifficulty
        let iterations = currentDifficulty == .adaptive ? adaptiveIterations : effectiveDifficulty.mctsIterations
        
        print("🧠 Using effective difficulty: \(effectiveDifficulty.rawValue) with \(iterations) iterations")
        
        // Apply difficulty-based strategy
        switch effectiveDifficulty {
        case .medium:
            return mediumStrategy(moves: availableMoves, grid: grid, player: player, opponent: opponent, iterations: iterations)
        case .hard:
            return hardStrategy(moves: availableMoves, grid: grid, player: player, opponent: opponent, iterations: iterations)
        case .expert:
            return expertStrategy(moves: availableMoves, grid: grid, player: player, opponent: opponent, iterations: iterations)
        case .adaptive:
            // This case should not be reached due to the effectiveDifficulty mapping above
            return mediumStrategy(moves: availableMoves, grid: grid, player: player, opponent: opponent, iterations: iterations)
        }
    }
    
    // MARK: - Adaptive Difficulty Management
    
    func setAdaptiveDifficulty(_ difficulty: Difficulty, reason: String) {
        guard currentDifficulty == .adaptive else { return }
        
        adaptiveDifficultyLevel = difficulty
        adaptiveIterations = difficulty.mctsIterations
        difficultyChangeReason = reason
        
        // Add some variance to make it feel more natural
        let variance = Int.random(in: -50...50)
        adaptiveIterations += variance
        adaptiveIterations = max(100, min(1500, adaptiveIterations))
        
        print("🧠 Adaptive AI: Difficulty adjusted to \(difficulty.rawValue) (\(reason))")
    }
    
    func getDifficultyChangeReason() -> String? {
        let reason = difficultyChangeReason
        difficultyChangeReason = nil // Clear after reading
        return reason
    }
    
    func getCurrentEffectiveDifficulty() -> Difficulty {
        return currentDifficulty == .adaptive ? adaptiveDifficultyLevel : currentDifficulty
    }
    
    // MARK: - Difficulty Strategies
    
    private func mediumStrategy(moves: [(Int, Int)], grid: [String: String], player: String, opponent: String, iterations: Int) -> (row: Int, col: Int)? {
        // Medium: Always win/block, then use MCTS for strategic moves
        
        // 1. Win if possible
        if let winMove = findImmediateWin(moves: moves, grid: grid, player: player) {
            return winMove
        }
        
        // 2. Block opponent win
        if let blockMove = findImmediateWin(moves: moves, grid: grid, player: opponent) {
            return blockMove
        }
        
        // 3. Use MCTS for strategic decisions
        if moves.count <= 15 { // Use MCTS for reasonable number of moves
            if let mctsMove = mctsEngine.findBestMove(for: grid, player: player, opponent: opponent, iterations: iterations) {
                return mctsMove
            }
        }
        
        // 4. Fallback to strategic move
        if let strategicMove = findBestStrategicMove(moves: moves, grid: grid, player: player, opponent: opponent) {
            return strategicMove
        }
        
        return moves.randomElement()
    }
    
    private func hardStrategy(moves: [(Int, Int)], grid: [String: String], player: String, opponent: String, iterations: Int) -> (row: Int, col: Int)? {
        // Hard: Advanced pattern recognition + MCTS
        
        // 1. Win immediately
        if let winMove = findImmediateWin(moves: moves, grid: grid, player: player) {
            return winMove
        }
        
        // 2. Block opponent win
        if let blockMove = findImmediateWin(moves: moves, grid: grid, player: opponent) {
            return blockMove
        }
        
        // 3. Create double threats
        if let doubleThreat = findDoubleThreatMove(moves: moves, grid: grid, player: player) {
            return doubleThreat
        }
        
        // 4. Block opponent double threats
        if let blockDoubleThreat = findDoubleThreatMove(moves: moves, grid: grid, player: opponent) {
            return blockDoubleThreat
        }
        
        // 5. Advanced threat analysis
        if let advancedThreat = findAdvancedThreatMove(moves: moves, grid: grid, player: player, opponent: opponent) {
            return advancedThreat
        }
        
        // 6. Use MCTS for complex strategic decisions
        if moves.count <= 20 {
            if let mctsMove = mctsEngine.findBestMove(for: grid, player: player, opponent: opponent, iterations: iterations) {
                return mctsMove
            }
        }
        
        // 7. Look for threats to create or block (fallback)
        if let threatMove = findThreatMove(moves: moves, grid: grid, player: player, opponent: opponent) {
            return threatMove
        }
        
        // 8. Strategic positioning
        if let strategicMove = findBestStrategicMove(moves: moves, grid: grid, player: player, opponent: opponent) {
            return strategicMove
        }
        
        return moves.randomElement()
    }
    
    private func expertStrategy(moves: [(Int, Int)], grid: [String: String], player: String, opponent: String, iterations: Int) -> (row: Int, col: Int)? {
        // Expert: High-powered MCTS with advanced heuristics and deep analysis
        
        print("🧠 Expert AI analyzing \(moves.count) moves...")
        
        // 1. Immediate win
        if let winMove = findImmediateWin(moves: moves, grid: grid, player: player) {
            print("✅ Taking winning move!")
            return winMove
        }
        
        // 2. Block opponent win
        if let blockMove = findImmediateWin(moves: moves, grid: grid, player: opponent) {
            print("🛡️ Blocking opponent win!")
            return blockMove
        }
        
        print("🤔 No immediate win/block found, using advanced strategy...")
        
        // 3. Opening book for early game (first 5-6 moves)
        if let openingMove = getOpeningMove(grid: grid, player: player, opponent: opponent) {
            print("📚 Using opening book move!")
            return openingMove
        }
        
        // 4. Create double threats
        if let doubleThreat = findDoubleThreatMove(moves: moves, grid: grid, player: player) {
            print("⚔️ Creating double threat!")
            return doubleThreat
        }
        
        // 5. Block opponent double threats
        if let blockDoubleThreat = findDoubleThreatMove(moves: moves, grid: grid, player: opponent) {
            print("🛡️ Blocking opponent double threat!")
            return blockDoubleThreat
        }
        
        // 6. Advanced threat analysis with forced move detection
        if let advancedThreat = findAdvancedThreatMove(moves: moves, grid: grid, player: player, opponent: opponent) {
            print("🎯 Using advanced threat move!")
            return advancedThreat
        }
        
        // 7. Enhanced strategic positioning for expert level
        if let enhancedMove = findEnhancedStrategicMove(moves: moves, grid: grid, player: player, opponent: opponent) {
            print("🧠 Using enhanced strategic move!")
            return enhancedMove
        }
        
        // 8. Use high-power MCTS for strategic decisions
        if moves.count <= 25 {
            if let mctsMove = mctsEngine.findBestMove(for: grid, player: player, opponent: opponent, iterations: iterations) {
                print("🎯 Using MCTS move with \(iterations) iterations")
                return mctsMove
            }
        }
        
        // 9. Deep minimax for complex positions
        if moves.count <= 15 {
            if let minimaxMove = minimaxDecision(moves: moves, grid: grid, player: player, opponent: opponent, depth: 4) {
                print("🧮 Using deep minimax move")
                return minimaxMove
            }
        }
        
        // 10. Fallback to advanced threat analysis
        if let threatMove = findThreatMove(moves: moves, grid: grid, player: player, opponent: opponent) {
            print("⚔️ Using threat move fallback")
            return threatMove
        }
        
        // 11. Final fallback to strategic move
        if let strategicMove = findBestStrategicMove(moves: moves, grid: grid, player: player, opponent: opponent) {
            print("🎲 Using strategic move fallback")
            return strategicMove
        }
        
        print("❓ Using random fallback move")
        return moves.randomElement()
    }
    
    // MARK: - Core AI Algorithms
    
    private func getOpeningMove(grid: [String: String], player: String, opponent: String) -> (row: Int, col: Int)? {
        let gridSize = grid.count
        
        // First move: place at center
        if grid.isEmpty {
            print("🎯 Opening: First move at center")
            return (0, 0)
        }
        
        // Second move (responding to opponent's first move)
        if gridSize == 1 {
            let opponentKey = grid.keys.first!
            let components = opponentKey.split(separator: ",")
            let opponentRow = Int(components[0])!
            let opponentCol = Int(components[1])!
            
            // If opponent played center, play at a diagonal
            if opponentRow == 0 && opponentCol == 0 {
                let diagonalMoves = [(1, 1), (-1, -1), (1, -1), (-1, 1)]
                return diagonalMoves.randomElement()
            }
            
            // If opponent played off-center, take center
            print("🎯 Opening: Taking center after opponent's off-center move")
            return (0, 0)
        }
        
        // Third move: strategic positioning
        if gridSize == 2 {
            let openingPatterns = getStrategicOpeningPatterns(grid: grid, player: player, opponent: opponent)
            if let strategicMove = openingPatterns.randomElement() {
                print("🎯 Opening: Strategic third move")
                return strategicMove
            }
        }
        
        // Use opening book for first 4-6 moves
        if gridSize <= 5 {
            let strategicMoves = findStrategicOpeningMoves(grid: grid, player: player, opponent: opponent)
            if !strategicMoves.isEmpty {
                print("🎯 Opening: Strategic early game move")
                return strategicMoves.randomElement()
            }
        }
        
        return nil
    }
    
    private func getStrategicOpeningPatterns(grid: [String: String], player: String, opponent: String) -> [(Int, Int)] {
        var strategicMoves: [(Int, Int)] = []
        let availableMoves = getAvailableMoves(from: grid)
        
        // Prefer moves that create multiple potential lines
        for move in availableMoves {
            let score = evaluateOpeningMove(move: move, grid: grid, player: player)
            if score >= 3 { // Threshold for good opening moves
                strategicMoves.append(move)
            }
        }
        
        return strategicMoves
    }
    
    private func findStrategicOpeningMoves(grid: [String: String], player: String, opponent: String) -> [(Int, Int)] {
        var strategicMoves: [(Int, Int)] = []
        let availableMoves = getAvailableMoves(from: grid)
        
        // Look for moves that:
        // 1. Extend our own lines
        // 2. Create multiple threat directions
        // 3. Stay reasonably close to the action
        
        for move in availableMoves {
            var score = 0
            
            // Check how many of our pieces this move would connect to
            let connectivityScore = evaluateConnectivity(move: move, grid: grid, player: player)
            score += connectivityScore * 2
            
            // Check potential for creating multiple lines
            let potentialLines = countPotentialLines(at: move, grid: grid, player: player)
            score += potentialLines
            
            // Prefer central-ish positions but not too far out
            let centerDistance = abs(move.0) + abs(move.1)
            if centerDistance <= 3 {
                score += (4 - centerDistance)
            }
            
            if score >= 5 { // Threshold for strategic moves
                strategicMoves.append(move)
            }
        }
        
        return strategicMoves
    }
    
    private func evaluateOpeningMove(move: (Int, Int), grid: [String: String], player: String) -> Int {
        var score = 0
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        
        // Check how many directions this move opens up
        for direction in directions {
            var hasPlayerPiece = false
            var emptySpaces = 0
            
            // Check 4 spaces in each direction
            for distance in 1...4 {
                let checkRow = move.0 + direction.0 * distance
                let checkCol = move.1 + direction.1 * distance
                let key = gridKey(checkRow, checkCol)
                
                if grid[key] == player {
                    hasPlayerPiece = true
                } else if grid[key] == nil {
                    emptySpaces += 1
                }
            }
            
            // Check reverse direction
            for distance in 1...4 {
                let checkRow = move.0 - direction.0 * distance
                let checkCol = move.1 - direction.1 * distance
                let key = gridKey(checkRow, checkCol)
                
                if grid[key] == player {
                    hasPlayerPiece = true
                } else if grid[key] == nil {
                    emptySpaces += 1
                }
            }
            
            // Score this direction
            if hasPlayerPiece && emptySpaces >= 3 {
                score += 2 // Good extension opportunity
            } else if emptySpaces >= 6 {
                score += 1 // Open line potential
            }
        }
        
        return score
    }
    
    private func evaluateConnectivity(move: (Int, Int), grid: [String: String], player: String) -> Int {
        var connectivity = 0
        let adjacentOffsets = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]
        
        for offset in adjacentOffsets {
            let checkRow = move.0 + offset.0
            let checkCol = move.1 + offset.1
            let key = gridKey(checkRow, checkCol)
            
            if grid[key] == player {
                connectivity += 1
            }
        }
        
        return connectivity
    }
    
    private func countPotentialLines(at move: (Int, Int), grid: [String: String], player: String) -> Int {
        var potentialLines = 0
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        
        for direction in directions {
            var lineScore = 0
            var emptySpaces = 0
            
            // Check both directions along this line
            for multiplier in [-1, 1] {
                for distance in 1...4 {
                    let checkRow = move.0 + direction.0 * distance * multiplier
                    let checkCol = move.1 + direction.1 * distance * multiplier
                    let key = gridKey(checkRow, checkCol)
                    
                    if grid[key] == player {
                        lineScore += 1
                    } else if grid[key] == nil {
                        emptySpaces += 1
                    } else {
                        break // Blocked by opponent
                    }
                }
            }
            
            // This direction has potential if we have pieces and enough empty space
            if lineScore > 0 && emptySpaces >= 3 {
                potentialLines += 1
            }
        }
        
        return potentialLines
    }
    
    private func findImmediateWin(moves: [(Int, Int)], grid: [String: String], player: String) -> (row: Int, col: Int)? {
        for (row, col) in moves {
            var testGrid = grid
            testGrid[gridKey(row, col)] = player
            
            if checkWin(at: row, col: col, player: player, grid: testGrid) {
                print("🎯 Found immediate win/block for \(player) at (\(row), \(col))")
                return (row, col)
            }
        }
        return nil
    }
    
    private func findDoubleThreatMove(moves: [(Int, Int)], grid: [String: String], player: String) -> (row: Int, col: Int)? {
        for (row, col) in moves {
            var testGrid = grid
            testGrid[gridKey(row, col)] = player
            
            let threats = countAdvancedThreats(at: row, col: col, player: player, grid: testGrid)
            if threats >= 2 {
                print("⚔️ Found double threat move for \(player) at (\(row), \(col))")
                return (row, col)
            }
        }
        return nil
    }
    
    private func findAdvancedThreatMove(moves: [(Int, Int)], grid: [String: String], player: String, opponent: String) -> (row: Int, col: Int)? {
        var bestMove: (row: Int, col: Int)?
        var bestThreatScore = -1
        
        for (row, col) in moves {
            var testGrid = grid
            testGrid[gridKey(row, col)] = player
            
            let playerThreats = countAdvancedThreats(at: row, col: col, player: player, grid: testGrid)
            
            // Check what opponent threats we block
            testGrid[gridKey(row, col)] = opponent
            let opponentThreatsBlocked = countAdvancedThreats(at: row, col: col, player: opponent, grid: testGrid)
            
            // Enhanced scoring: prioritize creating multiple threats and forcing moves
            let forcedMoveBonus = isForcedMove(at: (row, col), grid: grid, player: player, opponent: opponent) ? 5 : 0
            let threatScore = playerThreats * 4 + opponentThreatsBlocked * 2 + forcedMoveBonus
            
            if threatScore > bestThreatScore {
                bestThreatScore = threatScore
                bestMove = (row, col)
            }
        }
        
        if bestThreatScore > 0 {
            print("🎯 Found advanced threat move with score: \(bestThreatScore)")
        }
        
        return bestThreatScore > 0 ? bestMove : nil
    }
    
    private func countAdvancedThreats(at row: Int, col: Int, player: String, grid: [String: String]) -> Int {
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        var threats = 0
        
        for direction in directions {
            let lineInfo = analyzeLineFromPosition(row: row, col: col, direction: direction, player: player, grid: grid)
            
            // Count different types of threats
            if lineInfo.length >= 4 {
                threats += 1 // Immediate winning threat
            } else if lineInfo.length == 3 && lineInfo.openEnds >= 1 {
                threats += 1 // Three in a row with potential to extend
            } else if lineInfo.length == 2 && lineInfo.openEnds >= 2 {
                // Two in a row with both ends open - potential for growth
                if checkForGrowthPotential(row: row, col: col, direction: direction, player: player, grid: grid) {
                    threats += 1
                }
            }
        }
        
        return threats
    }
    
    private func analyzeLineFromPosition(row: Int, col: Int, direction: (Int, Int), player: String, grid: [String: String]) -> (length: Int, openEnds: Int) {
        var length = 1 // Count the piece at the position itself
        var openEnds = 0
        
        // Check positive direction
        var checkRow = row + direction.0
        var checkCol = col + direction.1
        while grid[gridKey(checkRow, checkCol)] == player {
            length += 1
            checkRow += direction.0
            checkCol += direction.1
        }
        if grid[gridKey(checkRow, checkCol)] == nil {
            openEnds += 1
        }
        
        // Check negative direction
        checkRow = row - direction.0
        checkCol = col - direction.1
        while grid[gridKey(checkRow, checkCol)] == player {
            length += 1
            checkRow -= direction.0
            checkCol -= direction.1
        }
        if grid[gridKey(checkRow, checkCol)] == nil {
            openEnds += 1
        }
        
        return (length, openEnds)
    }
    
    private func checkForGrowthPotential(row: Int, col: Int, direction: (Int, Int), player: String, grid: [String: String]) -> Bool {
        // Check if there's room for the line to grow to 5 in a row
        let maxExtension = 5
        var positiveSpace = 0
        var negativeSpace = 0
        
        // Check positive direction
        var checkRow = row + direction.0
        var checkCol = col + direction.1
        for _ in 1...maxExtension {
            if grid[gridKey(checkRow, checkCol)] == nil {
                positiveSpace += 1
            } else if grid[gridKey(checkRow, checkCol)] != player {
                break
            }
            checkRow += direction.0
            checkCol += direction.1
        }
        
        // Check negative direction
        checkRow = row - direction.0
        checkCol = col - direction.1
        for _ in 1...maxExtension {
            if grid[gridKey(checkRow, checkCol)] == nil {
                negativeSpace += 1
            } else if grid[gridKey(checkRow, checkCol)] != player {
                break
            }
            checkRow -= direction.0
            checkCol -= direction.1
        }
        
        return (positiveSpace + negativeSpace) >= 2 // Need at least 2 more spaces to potentially win
    }
    
    private func isForcedMove(at move: (Int, Int), grid: [String: String], player: String, opponent: String) -> Bool {
        // A forced move is one that creates an immediate threat that the opponent must respond to
        var testGrid = grid
        testGrid[gridKey(move.0, move.1)] = player
        
        // Check if this creates a situation where opponent MUST block
        let playerThreats = countWinningThreats(at: move.0, col: move.1, player: player, grid: testGrid)
        
        if playerThreats > 0 {
            // This creates a winning threat - it's a forced move
            return true
        }
        
        // Check if this creates multiple threats that can't all be blocked
        let advancedThreats = countAdvancedThreats(at: move.0, col: move.1, player: player, grid: testGrid)
        return advancedThreats >= 2
    }
    
    private func findThreatMove(moves: [(Int, Int)], grid: [String: String], player: String, opponent: String) -> (row: Int, col: Int)? {
        var bestMove: (row: Int, col: Int)?
        var bestThreatScore = -1
        
        for (row, col) in moves {
            var testGrid = grid
            testGrid[gridKey(row, col)] = player
            
            let playerThreats = countWinningThreats(at: row, col: col, player: player, grid: testGrid)
            
            // Also check what threats we block
            testGrid[gridKey(row, col)] = opponent
            let opponentThreatsBlocked = countWinningThreats(at: row, col: col, player: opponent, grid: testGrid)
            
            let threatScore = playerThreats * 3 + opponentThreatsBlocked
            
            if threatScore > bestThreatScore {
                bestThreatScore = threatScore
                bestMove = (row, col)
            }
        }
        
        return bestThreatScore > 0 ? bestMove : nil
    }
    
    private func findBestStrategicMove(moves: [(Int, Int)], grid: [String: String], player: String, opponent: String) -> (row: Int, col: Int)? {
        var bestMove: (row: Int, col: Int)?
        var bestScore = Int.min
        
        for (row, col) in moves {
            let score = evaluateMove(row: row, col: col, grid: grid, player: player, opponent: opponent)
            if score > bestScore {
                bestScore = score
                bestMove = (row, col)
            }
        }
        
        return bestMove
    }
    
    private func findEnhancedStrategicMove(moves: [(Int, Int)], grid: [String: String], player: String, opponent: String) -> (row: Int, col: Int)? {
        // Enhanced strategic evaluation for expert-level play
        var bestMove: (row: Int, col: Int)?
        var bestScore = Int.min
        
        for (row, col) in moves {
            var score = 0
            
            // 1. Base strategic score
            score += evaluateMove(row: row, col: col, grid: grid, player: player, opponent: opponent)
            
            // 2. Pattern recognition bonus
            score += evaluatePatterns(row: row, col: col, grid: grid, player: player) * 15
            
            // 3. Connectivity analysis
            score += evaluateConnectivity(row: row, col: col, grid: grid, player: player) * 12
            
            // 4. Control of key areas
            score += evaluateAreaControl(row: row, col: col, grid: grid, player: player) * 10
            
            // 5. Future potential analysis
            score += evaluateFuturePotential(row: row, col: col, grid: grid, player: player, opponent: opponent) * 8
            
            // 6. Defensive positioning
            score += evaluateDefensiveValue(row: row, col: col, grid: grid, player: player, opponent: opponent) * 6
            
            if score > bestScore {
                bestScore = score
                bestMove = (row, col)
            }
        }
        
        return bestMove
    }
    
    // MARK: - Enhanced Strategic Evaluation Functions
    
    private func evaluatePatterns(row: Int, col: Int, grid: [String: String], player: String) -> Int {
        // Look for strategic patterns like crosses, intersections, and chain formations
        var patternScore = 0
        let directions = [(0,1), (1,0), (1,1), (1,-1)]
        
        for direction in directions {
            let lineScore = evaluateLinePattern(row: row, col: col, direction: direction, grid: grid, player: player)
            patternScore += lineScore
        }
        
        // Bonus for creating intersection points
        let intersectionBonus = evaluateIntersectionPotential(row: row, col: col, grid: grid, player: player)
        patternScore += intersectionBonus
        
        return patternScore
    }
    
    private func evaluateConnectivity(row: Int, col: Int, grid: [String: String], player: String) -> Int {
        // Evaluate how well this move connects existing pieces
        var connectivityScore = 0
        let directions = [(0,1), (1,0), (1,1), (1,-1), (0,-1), (-1,0), (-1,-1), (-1,1)]
        
        for direction in directions {
            let (dr, dc) = direction
            let adjacentRow = row + dr
            let adjacentCol = col + dc
            
            if grid[gridKey(adjacentRow, adjacentCol)] == player {
                connectivityScore += 5
                
                // Bonus for connecting distant pieces
                let chainLength = getChainLength(from: adjacentRow, col: adjacentCol, direction: direction, grid: grid, player: player)
                connectivityScore += chainLength * 2
            }
        }
        
        return connectivityScore
    }
    
    private func evaluateAreaControl(row: Int, col: Int, grid: [String: String], player: String) -> Int {
        // Evaluate control over key board areas
        var areaScore = 0
        
        // Center bias (pieces near center are generally stronger)
        let centerDistance = abs(row) + abs(col)
        areaScore += max(0, 10 - centerDistance / 2)
        
        // Evaluate local area dominance
        let radius = 3
        var friendlyCount = 0
        var opponentCount = 0
        
        for r in (row - radius)...(row + radius) {
            for c in (col - radius)...(col + radius) {
                if let piece = grid[gridKey(r, c)] {
                    if piece == player {
                        friendlyCount += 1
                    } else {
                        opponentCount += 1
                    }
                }
            }
        }
        
        areaScore += (friendlyCount - opponentCount) * 3
        return areaScore
    }
    
    private func evaluateFuturePotential(row: Int, col: Int, grid: [String: String], player: String, opponent: String) -> Int {
        // Evaluate the long-term potential of this move
        var potentialScore = 0
        let directions = [(0,1), (1,0), (1,1), (1,-1)]
        
        for direction in directions {
            // Count available space in this direction
            let spaceCount = countAvailableSpace(from: row, col: col, direction: direction, grid: grid, maxRange: 6)
            
            // Bonus for directions with lots of space
            if spaceCount >= 4 {
                potentialScore += spaceCount * 2
            }
            
            // Check for potential future lines
            if canFormWinningLine(from: row, col: col, direction: direction, grid: grid, player: player) {
                potentialScore += 15
            }
        }
        
        return potentialScore
    }
    
    private func evaluateDefensiveValue(row: Int, col: Int, grid: [String: String], player: String, opponent: String) -> Int {
        // Evaluate how well this move disrupts opponent plans
        var defensiveScore = 0
        
        // Check if this move blocks opponent lines
        var testGrid = grid
        testGrid[gridKey(row, col)] = opponent
        
        let opponentThreats = countWinningThreats(at: row, col: col, player: opponent, grid: testGrid)
        defensiveScore += opponentThreats * 8
        
        // Check if this move prevents opponent double threats
        let doubleThreatPrevention = evaluateDoubleThreatPrevention(row: row, col: col, grid: grid, opponent: opponent)
        defensiveScore += doubleThreatPrevention * 12
        
        return defensiveScore
    }
    
    // MARK: - Helper Functions for Enhanced Strategy
    
    private func evaluateLinePattern(row: Int, col: Int, direction: (Int, Int), grid: [String: String], player: String) -> Int {
        let (dr, dc) = direction
        var patternScore = 0
        
        // Look for partial lines that could be extended
        for length in 2...4 {
            for offset in -length...0 {
                var hasSpace = true
                var hasPlayer = false
                
                for i in 0..<length {
                    let checkRow = row + (offset + i) * dr
                    let checkCol = col + (offset + i) * dc
                    let piece = grid[gridKey(checkRow, checkCol)]
                    
                    if piece == player {
                        hasPlayer = true
                    } else if piece != nil {
                        hasSpace = false
                        break
                    }
                }
                
                if hasSpace && hasPlayer {
                    patternScore += length * 2
                }
            }
        }
        
        return patternScore
    }
    
    private func evaluateIntersectionPotential(row: Int, col: Int, grid: [String: String], player: String) -> Int {
        // Check if this position could become a strategic intersection
        var intersectionValue = 0
        let directions = [(0,1), (1,0), (1,1), (1,-1)]
        
        var viableDirections = 0
        for direction in directions {
            if hasViableLine(from: row, col: col, direction: direction, grid: grid, player: player) {
                viableDirections += 1
            }
        }
        
        // More viable directions = better intersection potential
        if viableDirections >= 2 {
            intersectionValue = viableDirections * 8
        }
        
        return intersectionValue
    }
    
    private func getChainLength(from row: Int, col: Int, direction: (Int, Int), grid: [String: String], player: String) -> Int {
        let (dr, dc) = direction
        var length = 0
        var currentRow = row
        var currentCol = col
        
        while grid[gridKey(currentRow, currentCol)] == player {
            length += 1
            currentRow += dr
            currentCol += dc
        }
        
        return length
    }
    
    private func countAvailableSpace(from row: Int, col: Int, direction: (Int, Int), grid: [String: String], maxRange: Int) -> Int {
        let (dr, dc) = direction
        var spaceCount = 0
        
        // Check positive direction
        for i in 1...maxRange {
            let checkRow = row + i * dr
            let checkCol = col + i * dc
            if grid[gridKey(checkRow, checkCol)] == nil {
                spaceCount += 1
            } else {
                break
            }
        }
        
        // Check negative direction
        for i in 1...maxRange {
            let checkRow = row - i * dr
            let checkCol = col - i * dc
            if grid[gridKey(checkRow, checkCol)] == nil {
                spaceCount += 1
            } else {
                break
            }
        }
        
        return spaceCount
    }
    
    private func canFormWinningLine(from row: Int, col: Int, direction: (Int, Int), grid: [String: String], player: String) -> Bool {
        // Check if a winning line could potentially be formed in this direction
        let (dr, dc) = direction
        let requiredLength = 5
        var availableSpaces = 1 // The current position
        
        // Count available spaces in both directions
        for i in 1..<requiredLength {
            let posRow = row + i * dr
            let posCol = col + i * dc
            if grid[gridKey(posRow, posCol)] == nil || grid[gridKey(posRow, posCol)] == player {
                availableSpaces += 1
            } else {
                break
            }
        }
        
        for i in 1..<requiredLength {
            let negRow = row - i * dr
            let negCol = col - i * dc
            if grid[gridKey(negRow, negCol)] == nil || grid[gridKey(negRow, negCol)] == player {
                availableSpaces += 1
            } else {
                break
            }
        }
        
        return availableSpaces >= requiredLength
    }
    
    private func evaluateDoubleThreatPrevention(row: Int, col: Int, grid: [String: String], opponent: String) -> Int {
        // Check how many potential double threats this move prevents
        var testGrid = grid
        testGrid[gridKey(row, col)] = opponent
        
        let threatsWithMove = countAdvancedThreats(grid: testGrid, player: opponent)
        let threatsWithoutMove = countAdvancedThreats(grid: grid, player: opponent)
        
        return max(0, threatsWithMove - threatsWithoutMove) * 3
    }
    
    private func hasViableLine(from row: Int, col: Int, direction: (Int, Int), grid: [String: String], player: String) -> Bool {
        // Check if a line could potentially be developed in this direction
        let (dr, dc) = direction
        var viableLength = 0
        
        // Check both directions for viable spaces
        for multiplier in [-1, 1] {
            for i in 1...4 {
                let checkRow = row + (i * multiplier * dr)
                let checkCol = col + (i * multiplier * dc)
                let piece = grid[gridKey(checkRow, checkCol)]
                
                if piece == nil || piece == player {
                    viableLength += 1
                } else {
                    break
                }
            }
        }
        
        return viableLength >= 3 // Need at least 3 additional spaces for viability
    }
    
    private func minimaxDecision(moves: [(Int, Int)], grid: [String: String], player: String, opponent: String, depth: Int) -> (row: Int, col: Int)? {
        var bestMove: (row: Int, col: Int)?
        var bestScore = Int.min
        
        // Limit moves for performance
        let limitedMoves = Array(moves.shuffled().prefix(min(10, moves.count)))
        
        for (row, col) in limitedMoves {
            var testGrid = grid
            testGrid[gridKey(row, col)] = player
            
            let score = minimax(grid: testGrid, depth: depth - 1, isMaximizing: false, 
                               player: player, opponent: opponent, alpha: Int.min, beta: Int.max)
            
            if score > bestScore {
                bestScore = score
                bestMove = (row, col)
            }
        }
        
        return bestMove
    }
    
    private func minimax(grid: [String: String], depth: Int, isMaximizing: Bool, 
                        player: String, opponent: String, alpha: Int, beta: Int) -> Int {
        
        // Terminal conditions
        if depth == 0 {
            return evaluateBoard(grid: grid, player: player, opponent: opponent)
        }
        
        let moves = Array(getAvailableMoves(from: grid).prefix(8)) // Limit for performance
        
        if isMaximizing {
            var maxScore = Int.min
            var alphaValue = alpha
            
            for (row, col) in moves {
                var testGrid = grid
                testGrid[gridKey(row, col)] = player
                
                let score = minimax(grid: testGrid, depth: depth - 1, isMaximizing: false,
                                   player: player, opponent: opponent, alpha: alphaValue, beta: beta)
                maxScore = max(maxScore, score)
                alphaValue = max(alphaValue, score)
                
                if beta <= alphaValue {
                    break // Alpha-beta pruning
                }
            }
            return maxScore
        } else {
            var minScore = Int.max
            var betaValue = beta
            
            for (row, col) in moves {
                var testGrid = grid
                testGrid[gridKey(row, col)] = opponent
                
                let score = minimax(grid: testGrid, depth: depth - 1, isMaximizing: true,
                                   player: player, opponent: opponent, alpha: alpha, beta: betaValue)
                minScore = min(minScore, score)
                betaValue = min(betaValue, score)
                
                if betaValue <= alpha {
                    break // Alpha-beta pruning
                }
            }
            return minScore
        }
    }
    
    // MARK: - Evaluation Functions
    
    private func evaluateMove(row: Int, col: Int, grid: [String: String], player: String, opponent: String) -> Int {
        var score = 0
        
        // Simulate placing the piece
        var testGrid = grid
        testGrid[gridKey(row, col)] = player
        
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        
        for direction in directions {
            let playerLine = getLineLength(from: (row, col), direction: direction, player: player, grid: testGrid)
            let opponentThreat = getLineThreat(at: (row, col), direction: direction, player: opponent, grid: grid)
            
            // Score based on line length
            score += scoreForLineLength(playerLine)
            
            // Bonus for blocking opponent threats
            score += opponentThreat * 50
            
            // Central positioning bonus
            let centerDistance = abs(row) + abs(col)
            score += max(0, 20 - centerDistance)
        }
        
        return score
    }
    
    private func evaluateBoard(grid: [String: String], player: String, opponent: String) -> Int {
        var score = 0
        
        for (key, piece) in grid {
            let components = key.split(separator: ",")
            let row = Int(components[0])!
            let col = Int(components[1])!
            
            let pieceScore = evaluatePosition(row: row, col: col, player: piece, grid: grid)
            
            if piece == player {
                score += pieceScore
            } else if piece == opponent {
                score -= pieceScore
            }
        }
        
        return score
    }
    
    private func evaluatePosition(row: Int, col: Int, player: String, grid: [String: String]) -> Int {
        var score = 0
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        
        for direction in directions {
            let lineLength = getLineLength(from: (row, col), direction: direction, player: player, grid: grid)
            score += scoreForLineLength(lineLength)
        }
        
        return score
    }
    
    private func scoreForLineLength(_ length: Int) -> Int {
        switch length {
        case 5...: return 100000  // Win
        case 4: return 10000      // Four in a row
        case 3: return 1000       // Three in a row
        case 2: return 100        // Two in a row
        case 1: return 10         // Single piece
        default: return 0
        }
    }
    
    // MARK: - Helper Functions
    
    private func getLineLength(from position: (Int, Int), direction: (Int, Int), player: String, grid: [String: String]) -> Int {
        let (startRow, startCol) = position
        var count = 0
        
        // Count in positive direction
        var row = startRow
        var col = startCol
        while grid[gridKey(row, col)] == player {
            count += 1
            row += direction.0
            col += direction.1
        }
        
        // Count in negative direction (excluding start position)
        row = startRow - direction.0
        col = startCol - direction.1
        while grid[gridKey(row, col)] == player {
            count += 1
            row -= direction.0
            col -= direction.1
        }
        
        return count
    }
    
    private func getLineThreat(at position: (Int, Int), direction: (Int, Int), player: String, grid: [String: String]) -> Int {
        // Check if placing a piece here would block an opponent threat
        var testGrid = grid
        testGrid[gridKey(position.0, position.1)] = player
        
        let beforeLength = getLineLength(from: position, direction: direction, player: player, grid: grid)
        let afterLength = getLineLength(from: position, direction: direction, player: player, grid: testGrid)
        
        return max(0, afterLength - beforeLength)
    }
    
    private func countWinningThreats(at row: Int, col: Int, player: String, grid: [String: String]) -> Int {
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        var threats = 0
        
        for direction in directions {
            let lineLength = getLineLength(from: (row, col), direction: direction, player: player, grid: grid)
            if lineLength >= 4 {
                threats += 1
            }
        }
        
        return threats
    }
    
    private func getAvailableMoves(from grid: [String: String]) -> [(Int, Int)] {
        if grid.isEmpty {
            return [(0, 0)]
        }
        
        let occupiedPositions = grid.keys.compactMap { key -> (Int, Int)? in
            let components = key.split(separator: ",")
            guard components.count == 2,
                  let row = Int(components[0]),
                  let col = Int(components[1]) else { return nil }
            return (row, col)
        }
        
        let rows = occupiedPositions.map { $0.0 }
        let cols = occupiedPositions.map { $0.1 }
        
        guard let minRow = rows.min(), let maxRow = rows.max(),
              let minCol = cols.min(), let maxCol = cols.max() else {
            return [(0, 0)]
        }
        
        var availableMoves: [(Int, Int)] = []
        
        // Search in expanded area around existing pieces
        for row in (minRow - 2)...(maxRow + 2) {
            for col in (minCol - 2)...(maxCol + 2) {
                let key = gridKey(row, col)
                if grid[key] == nil {
                    // Only include moves that are reasonably close to existing pieces
                    if isReasonablyClose(row: row, col: col, to: occupiedPositions) {
                        availableMoves.append((row, col))
                    }
                }
            }
        }
        
        return availableMoves
    }
    
    private func isReasonablyClose(row: Int, col: Int, to positions: [(Int, Int)]) -> Bool {
        for (existingRow, existingCol) in positions {
            let distance = max(abs(row - existingRow), abs(col - existingCol))
            if distance <= 2 {
                return true
            }
        }
        return false
    }
    
    private func gridKey(_ row: Int, _ col: Int) -> String {
        return "\(row),\(col)"
    }
    
    private func checkWin(at row: Int, col: Int, player: String, grid: [String: String]) -> Bool {
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        
        for direction in directions {
            let lineLength = getLineLength(from: (row, col), direction: direction, player: player, grid: grid)
            if lineLength >= 5 {
                return true
            }
        }
        
        return false
    }
}
