//
//  AIBot.swift
//  Caroo
//
//  Created by AI Assistant on 09/06/25.
//

import Foundation
import SpriteKit

// MARK: - AI Difficulty Levels
enum AIDifficulty: String, CaseIterable {
    case novice = "Novice"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case master = "Master"
    case adaptive = "Adaptive"
    
    var displayName: String {
        return self.rawValue
    }
    
    var description: String {
        switch self {
        case .novice:
            return "Learning-friendly AI that makes teaching mistakes"
        case .intermediate:
            return "Balanced challenge with moderate strategy"
        case .advanced:
            return "Skilled AI with complex tactical thinking"
        case .master:
            return "Expert-level AI with near-optimal play"
        case .adaptive:
            return "Dynamic difficulty that adapts to your skill"
        }
    }
}

// MARK: - AI Personality Types
enum AIPersonality: String, CaseIterable {
    case balanced = "Balanced"
    case aggressive = "Aggressive"
    case defensive = "Defensive"
    case unpredictable = "Unpredictable"
    
    var description: String {
        switch self {
        case .balanced:
            return "Mix of offensive and defensive strategies"
        case .aggressive:
            return "Focuses on attacking and creating threats"
        case .defensive:
            return "Prioritizes blocking and counter-play"
        case .unpredictable:
            return "Introduces controlled randomness"
        }
    }
}

// MARK: - Move Structure
struct AIMove {
    let row: Int
    let col: Int
    let score: Double
    let confidence: Double
    let moveType: MoveType
    
    enum MoveType {
        case winning          // Immediate win
        case blocking         // Block opponent win
        case threatening      // Create threat
        case positional       // Strategic positioning
        case random          // Random/exploratory
    }
    
    var gridKey: String {
        return "\(row),\(col)"
    }
}

// MARK: - AI State Management
struct AIGameState {
    let grid: [String: String]
    let currentPlayer: String
    let opponentPlayer: String
    let totalMoves: Int
    let gamePhase: GamePhase
    
    enum GamePhase {
        case opening    // First few moves
        case midgame    // Active play
        case endgame    // Close to win condition
    }
    
    var gridSize: Int {
        return grid.count
    }
    
    var isEmpty: Bool {
        return grid.isEmpty
    }
}

// MARK: - AI Bot Protocol
protocol AIBotProtocol {
    /// The difficulty level of this AI bot
    var difficulty: AIDifficulty { get }
    
    /// The personality type affecting decision making
    var personality: AIPersonality { get }
    
    /// The player symbol this AI represents ("X" or "O")
    var playerSymbol: String { get set }
    
    /// Calculate the best move for the current game state
    /// - Parameters:
    ///   - gameState: Current state of the game
    ///   - timeLimit: Maximum time allowed for calculation (in seconds)
    /// - Returns: The chosen move, or nil if no valid moves available
    func calculateBestMove(for gameState: AIGameState, timeLimit: TimeInterval) -> AIMove?
    
    /// Evaluate the strength of a potential move
    /// - Parameters:
    ///   - move: The move to evaluate
    ///   - gameState: Current game state
    /// - Returns: Score representing move quality (-1.0 to 1.0)
    func evaluateMove(_ move: AIMove, in gameState: AIGameState) -> Double
    
    /// Get all valid moves for current position
    /// - Parameter gameState: Current game state
    /// - Returns: Array of valid moves with basic scoring
    func getValidMoves(for gameState: AIGameState) -> [AIMove]
    
    /// Update internal state based on game events
    /// - Parameters:
    ///   - move: The move that was played
    ///   - gameState: Updated game state
    func updateState(with move: AIMove, gameState: AIGameState)
    
    /// Reset AI state for new game
    func resetState()
}

// MARK: - Base AI Bot Class
class AIBot: AIBotProtocol {
    
    // MARK: - Properties
    let difficulty: AIDifficulty
    let personality: AIPersonality
    var playerSymbol: String
    
    // Internal state tracking
    private var moveHistory: [AIMove] = []
    private var gameHistory: [AIGameState] = []
    private var thinkingTime: TimeInterval = 0
    
    // Performance metrics
    private var movesCalculated: Int = 0
    private var averageThinkingTime: TimeInterval = 0
    
    // MARK: - Initialization
    init(difficulty: AIDifficulty, personality: AIPersonality = .balanced, playerSymbol: String = "O") {
        self.difficulty = difficulty
        self.personality = personality
        self.playerSymbol = playerSymbol
    }
    
    // MARK: - AIBotProtocol Implementation
    
    func calculateBestMove(for gameState: AIGameState, timeLimit: TimeInterval = 2.0) -> AIMove? {
        let startTime = Date()
        defer {
            thinkingTime = Date().timeIntervalSince(startTime)
            updatePerformanceMetrics()
        }
        
        // PRIORITY 1: Check for immediate winning moves
        if let winningMove = findImmediateWinMove(in: gameState) {
            return winningMove
        }
        
        // PRIORITY 2: Block opponent's immediate wins (for intermediate+ difficulty)
        if difficulty != .novice, let blockingMove = findCriticalBlockingMove(in: gameState) {
            return blockingMove
        }
        
        let validMoves = getValidMoves(for: gameState)
        guard !validMoves.isEmpty else { return nil }
        
        // Apply difficulty-specific logic for remaining moves
        switch difficulty {
        case .novice:
            return calculateNoviceMove(from: validMoves, gameState: gameState)
        case .intermediate:
            return calculateIntermediateMove(from: validMoves, gameState: gameState)
        case .advanced:
            return calculateAdvancedMove(from: validMoves, gameState: gameState, timeLimit: timeLimit)
        case .master:
            return calculateMasterMove(from: validMoves, gameState: gameState, timeLimit: timeLimit)
        case .adaptive:
            return calculateAdaptiveMove(from: validMoves, gameState: gameState, timeLimit: timeLimit)
        }
    }
    
    func evaluateMove(_ move: AIMove, in gameState: AIGameState) -> Double {
        var score: Double = 0.0
        
        // Basic position evaluation
        score += evaluatePositionalValue(move, in: gameState)
        
        // Threat evaluation
        score += evaluateThreatLevel(move, in: gameState)
        
        // Apply personality modifiers
        score = applyPersonalityModifier(to: score, for: move, in: gameState)
        
        return max(-1.0, min(1.0, score))
    }
    
    func getValidMoves(for gameState: AIGameState) -> [AIMove] {
        var validMoves: [AIMove] = []
        
        // Get area around existing moves for infinite grid optimization
        let searchArea = getSearchArea(for: gameState)
        
        for row in searchArea.minRow...searchArea.maxRow {
            for col in searchArea.minCol...searchArea.maxCol {
                let gridKey = "\(row),\(col)"
                
                // Check if position is empty
                if gameState.grid[gridKey] == nil {
                    let move = AIMove(
                        row: row,
                        col: col,
                        score: 0.0,
                        confidence: 0.5,
                        moveType: .positional
                    )
                    validMoves.append(move)
                }
            }
        }
        
        return validMoves
    }
    
    func updateState(with move: AIMove, gameState: AIGameState) {
        moveHistory.append(move)
        gameHistory.append(gameState)
        
        // Limit history size for memory management
        if moveHistory.count > 50 {
            moveHistory.removeFirst()
            gameHistory.removeFirst()
        }
    }
    
    func resetState() {
        moveHistory.removeAll()
        gameHistory.removeAll()
        movesCalculated = 0
        averageThinkingTime = 0
        thinkingTime = 0
    }
    
    // MARK: - Enhanced Immediate Win Detection (Phase 2.1)
    
    /// Find immediate winning move using enhanced threat analysis
    private func findImmediateWinMove(in gameState: AIGameState) -> AIMove? {
        let searchArea = getSearchArea(for: gameState)
        
        if let winPosition = ThreatAnalyzer.getBestImmediateWin(in: gameState.grid, for: playerSymbol) {
            #if DEBUG
            print("🎯 AI found immediate winning move at (\(winPosition.row), \(winPosition.col))")
            #endif
            
            return AIMove(
                row: winPosition.row,
                col: winPosition.col,
                score: 1000.0,
                confidence: 1.0,
                moveType: .winning
            )
        }
        
        return nil
    }
    
    /// Find critical blocking move to prevent opponent's immediate win
    private func findCriticalBlockingMove(in gameState: AIGameState) -> AIMove? {
        // Use enhanced blocking analysis for comprehensive threat detection
        if let bestBlock = ThreatAnalyzer.getBestCriticalBlockingMove(
            in: gameState.grid, 
            against: gameState.opponentPlayer, 
            currentPlayer: playerSymbol
        ) {
            let baseScore: Double
            let confidence: Double
            
            // Score based on threat level and dual-purpose nature
            switch bestBlock.priority {
            case 950...1000:  // Immediate win blocking
                baseScore = 950.0
                confidence = 0.98
            case 850...949:   // Strong threat blocking
                baseScore = 900.0
                confidence = 0.95
            default:         // Moderate threat blocking
                baseScore = 800.0
                confidence = 0.90
            }
            
            // Bonus for dual-purpose moves (block + create threat)
            let finalScore = bestBlock.isDualPurpose ? baseScore + 50.0 : baseScore
            let finalConfidence = bestBlock.isDualPurpose ? min(confidence + 0.05, 1.0) : confidence
            
            #if DEBUG
            let dualPurposeStr = bestBlock.isDualPurpose ? " (dual-purpose)" : ""
            print("🛡️ AI found critical blocking move at (\(bestBlock.position.row), \(bestBlock.position.col)) - Priority: \(bestBlock.priority)\(dualPurposeStr)")
            #endif
            
            return AIMove(
                row: bestBlock.position.row,
                col: bestBlock.position.col,
                score: finalScore,
                confidence: finalConfidence,
                moveType: .blocking
            )
        }
        
        // Fallback: Check for multi-threat blocking opportunities
        let multiThreatBlocks = ThreatAnalyzer.findMultiThreatBlockingMoves(in: gameState.grid, against: gameState.opponentPlayer)
        if let bestMultiBlock = multiThreatBlocks.first {
            #if DEBUG
            print("🛡️ AI found multi-threat blocking move at (\(bestMultiBlock.position.row), \(bestMultiBlock.position.col)) - Blocks \(bestMultiBlock.threatsBlocked) threats")
            #endif
            
            return AIMove(
                row: bestMultiBlock.position.row,
                col: bestMultiBlock.position.col,
                score: min(bestMultiBlock.totalPriority, 980.0), // Cap to avoid exceeding win priority
                confidence: 0.93,
                moveType: .blocking
            )
        }
        
        return nil
    }
    
    /// Enhanced immediate win detection for threat evaluation
    private func enhancedImmediateWinCheck(_ move: AIMove, in gameState: AIGameState) -> Bool {
        return ThreatAnalyzer.wouldCreateImmediateWin(
            at: move.row, 
            col: move.col, 
            in: gameState.grid, 
            for: playerSymbol
        )
    }
    
    /// Enhanced blocking detection for threat evaluation
    private func enhancedBlockingCheck(_ move: AIMove, in gameState: AIGameState) -> Bool {
        return ThreatAnalyzer.wouldBlockCriticalThreat(
            at: move.row, 
            col: move.col, 
            in: gameState.grid, 
            against: gameState.opponentPlayer
        )
    }

    // MARK: - Difficulty-Specific Move Calculation
    
    private func calculateNoviceMove(from validMoves: [AIMove], gameState: AIGameState) -> AIMove? {
        // Novice: Always take immediate wins (teaching moment)
        if let winningMove = findImmediateWinMove(in: gameState) {
            #if DEBUG
            print("🎓 Novice AI taking winning move (teaching moment)")
            #endif
            return winningMove
        }
        
        // Block immediate wins 75% of the time (sometimes miss for teaching)
        // But always block if it would result in immediate loss
        if let blockingMove = findCriticalBlockingMove(in: gameState) {
            // Always block immediate win threats (priority >= 950)
            if blockingMove.score >= 950.0 {
                #if DEBUG
                print("🎓 Novice AI blocking immediate win threat (teaching moment)")
                #endif
                return blockingMove
            }
            
            // Block other critical threats 75% of the time
            if Double.random(in: 0...1) < 0.75 {
                #if DEBUG
                print("🎓 Novice AI blocking critical threat")
                #endif
                return blockingMove
            } else {
                #if DEBUG
                print("🎓 Novice AI missing block for teaching (25% chance)")
                #endif
            }
        }
        
        // 60% random moves, 40% basic strategy
        if Double.random(in: 0...1) < 0.6 {
            return validMoves.randomElement()
        }
        
        // Basic strategy: look for simple patterns
        let strategicMoves = validMoves.filter { move in
            let evaluation = evaluateMove(move, in: gameState)
            return evaluation > 0.3
        }
        
        return strategicMoves.randomElement() ?? validMoves.randomElement()
    }
    
    private func calculateIntermediateMove(from validMoves: [AIMove], gameState: AIGameState) -> AIMove? {
        // Intermediate: Basic minimax with limited depth
        return calculateMinimaxMove(from: validMoves, gameState: gameState, depth: 3)
    }
    
    private func calculateAdvancedMove(from validMoves: [AIMove], gameState: AIGameState, timeLimit: TimeInterval) -> AIMove? {
        // Advanced: Deeper search with pattern recognition
        return calculateMinimaxMove(from: validMoves, gameState: gameState, depth: 5)
    }
    
    private func calculateMasterMove(from validMoves: [AIMove], gameState: AIGameState, timeLimit: TimeInterval) -> AIMove? {
        // Master: Deep search with optimizations
        return calculateMinimaxMove(from: validMoves, gameState: gameState, depth: 7)
    }
    
    private func calculateAdaptiveMove(from validMoves: [AIMove], gameState: AIGameState, timeLimit: TimeInterval) -> AIMove? {
        // Adaptive: Adjust difficulty based on game state and opponent skill
        let adaptiveDifficulty = determineAdaptiveDifficulty(for: gameState)
        
        switch adaptiveDifficulty {
        case .novice:
            return calculateNoviceMove(from: validMoves, gameState: gameState)
        case .intermediate:
            return calculateIntermediateMove(from: validMoves, gameState: gameState)
        case .advanced:
            return calculateAdvancedMove(from: validMoves, gameState: gameState, timeLimit: timeLimit)
        case .master:
            return calculateMasterMove(from: validMoves, gameState: gameState, timeLimit: timeLimit)
        case .adaptive:
            return calculateIntermediateMove(from: validMoves, gameState: gameState)
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateMinimaxMove(from validMoves: [AIMove], gameState: AIGameState, depth: Int) -> AIMove? {
        var bestMove: AIMove?
        var bestScore: Double = -Double.infinity
        
        for move in validMoves {
            // Create new game state with this move
            var newGrid = gameState.grid
            newGrid[move.gridKey] = playerSymbol
            
            let newGameState = AIGameState(
                grid: newGrid,
                currentPlayer: gameState.opponentPlayer,
                opponentPlayer: gameState.currentPlayer,
                totalMoves: gameState.totalMoves + 1,
                gamePhase: gameState.gamePhase
            )
            
            // Use minimax to evaluate this move
            let score = minimax(gameState: newGameState, depth: depth - 1, isMaximizing: false, alpha: -Double.infinity, beta: Double.infinity)
            
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        
        return bestMove
    }
    
    // MARK: - Minimax Algorithm with Alpha-Beta Pruning
    
    private func minimax(gameState: AIGameState, depth: Int, isMaximizing: Bool, alpha: Double, beta: Double) -> Double {
        // Terminal conditions
        if depth == 0 {
            return evaluatePosition(gameState)
        }
        
        // Check for immediate win/loss
        let winResult = checkGameEndState(gameState)
        if winResult != 0 {
            return winResult * (isMaximizing ? 1 : -1)
        }
        
        let validMoves = getValidMoves(for: gameState)
        if validMoves.isEmpty {
            return 0 // Draw
        }
        
        var alpha = alpha
        var beta = beta
        
        if isMaximizing {
            var maxScore = -Double.infinity
            
            for move in validMoves {
                var newGrid = gameState.grid
                newGrid[move.gridKey] = isMaximizing ? playerSymbol : gameState.opponentPlayer
                
                let newGameState = AIGameState(
                    grid: newGrid,
                    currentPlayer: gameState.opponentPlayer,
                    opponentPlayer: gameState.currentPlayer,
                    totalMoves: gameState.totalMoves + 1,
                    gamePhase: gameState.gamePhase
                )
                
                let score = minimax(gameState: newGameState, depth: depth - 1, isMaximizing: false, alpha: alpha, beta: beta)
                maxScore = max(maxScore, score)
                alpha = max(alpha, score)
                
                if beta <= alpha {
                    break // Alpha-beta pruning
                }
            }
            
            return maxScore
        } else {
            var minScore = Double.infinity
            
            for move in validMoves {
                var newGrid = gameState.grid
                newGrid[move.gridKey] = gameState.currentPlayer
                
                let newGameState = AIGameState(
                    grid: newGrid,
                    currentPlayer: gameState.opponentPlayer,
                    opponentPlayer: gameState.currentPlayer,
                    totalMoves: gameState.totalMoves + 1,
                    gamePhase: gameState.gamePhase
                )
                
                let score = minimax(gameState: newGameState, depth: depth - 1, isMaximizing: true, alpha: alpha, beta: beta)
                minScore = min(minScore, score)
                beta = min(beta, score)
                
                if beta <= alpha {
                    break // Alpha-beta pruning
                }
            }
            
            return minScore
        }
    }
    
    // MARK: - Position Evaluation System
    
    private func evaluatePosition(_ gameState: AIGameState) -> Double {
        var score: Double = 0.0
        
        // Evaluate all patterns for both players
        score += evaluateAllPatterns(in: gameState, for: playerSymbol) * 1.0
        score -= evaluateAllPatterns(in: gameState, for: gameState.opponentPlayer) * 1.0
        
        // Add positional bonuses
        score += evaluatePositionalAdvantages(in: gameState)
        
        return score
    }
    
    private func evaluateAllPatterns(in gameState: AIGameState, for player: String) -> Double {
        var totalScore: Double = 0.0
        
        // Score weights for different pattern lengths
        let patternScores: [Int: Double] = [
            5: 1000.0,  // Winning line
            4: 100.0,   // Immediate threat
            3: 10.0,    // Strong position
            2: 1.0      // Basic connection
        ]
        
        // Get all positions for this player
        let playerPositions = gameState.grid.compactMap { (key, value) -> (Int, Int)? in
            if value == player {
                let components = key.split(separator: ",")
                if let row = Int(components[0]), let col = Int(components[1]) {
                    return (row, col)
                }
            }
            return nil
        }
        
        // Check all potential lines from each piece
        for (row, col) in playerPositions {
            let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
            
            for direction in directions {
                let lineScore = evaluateLineFromPosition(
                    startRow: row, startCol: col,
                    direction: direction,
                    gameState: gameState,
                    player: player
                )
                totalScore += lineScore
            }
        }
        
        return totalScore
    }
    
    private func evaluateLineFromPosition(startRow: Int, startCol: Int, direction: (Int, Int), gameState: AIGameState, player: String) -> Double {
        var consecutiveCount = 0
        var openEnds = 0
        var totalInLine = 0
        
        // Check the line in both directions
        for multiplier in [-1, 1] {
            var row = startRow
            var col = startCol
            var foundEmpty = false
            
            while true {
                row += direction.0 * multiplier
                col += direction.1 * multiplier
                
                let gridKey = "\(row),\(col)"
                let cellValue = gameState.grid[gridKey]
                
                if cellValue == player {
                    totalInLine += 1
                    if !foundEmpty {
                        consecutiveCount += 1
                    }
                } else if cellValue == nil && !foundEmpty {
                    // Empty space - potential for extension
                    openEnds += 1
                    foundEmpty = true
                } else if cellValue != nil {
                    // Opponent piece - line is blocked
                    break
                } else {
                    // Second empty space - stop checking this direction
                    break
                }
                
                // Limit search distance for performance
                if abs(row - startRow) > 6 || abs(col - startCol) > 6 {
                    break
                }
            }
        }
        
        // Calculate score based on pattern strength
        let baseScore = pow(Double(consecutiveCount + 1), 2.0)
        let openEndMultiplier = min(2.0, Double(openEnds) * 0.5 + 1.0)
        
        return baseScore * openEndMultiplier
    }
    
    private func evaluatePositionalValue(_ move: AIMove, in gameState: AIGameState) -> Double {
        var score: Double = 0.0
        
        // Enhanced center preference for infinite grid
        let centerDistance = sqrt(Double(move.row * move.row + move.col * move.col))
        score += 0.15 / (1.0 + centerDistance * 0.05)
        
        // Proximity clustering bonus - reward moves near existing pieces
        var proximityScore: Double = 0.0
        var nearbyPieces = 0
        
        for (gridKey, piecePlayer) in gameState.grid {
            let components = gridKey.split(separator: ",")
            if let existingRow = Int(components[0]), let existingCol = Int(components[1]) {
                let distance = max(abs(move.row - existingRow), abs(move.col - existingCol))
                
                if distance <= 3 {
                    nearbyPieces += 1
                    let distanceScore = 0.3 / Double(distance + 1)
                    
                    // Bonus for being near own pieces, smaller bonus for being near opponent
                    if piecePlayer == playerSymbol {
                        proximityScore += distanceScore * 1.5
                    } else {
                        proximityScore += distanceScore * 0.7
                    }
                }
            }
        }
        
        // Clustering bonus - encourage tight formations
        if nearbyPieces >= 2 {
            score += proximityScore * 1.2
        } else {
            score += proximityScore
        }
        
        // Strategic positioning bonuses
        score += evaluateStrategicPosition(move, in: gameState)
        
        return score
    }
    
    private func evaluateStrategicPosition(_ move: AIMove, in gameState: AIGameState) -> Double {
        var score: Double = 0.0
        
        // Check if this position enables multiple future lines
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        var potentialLines = 0
        
        for direction in directions {
            var lineLength = 1 // Count the move itself
            var openEnds = 0
            
            // Check both directions from this position
            for multiplier in [-1, 1] {
                var checkRow = move.row + direction.0 * multiplier
                var checkCol = move.col + direction.1 * multiplier
                
                for step in 1...4 { // Check up to 4 spaces in each direction
                    let gridKey = "\(checkRow),\(checkCol)"
                    let cellValue = gameState.grid[gridKey]
                    
                    if cellValue == playerSymbol {
                        lineLength += 1
                    } else if cellValue == nil {
                        openEnds += 1
                        break
                    } else {
                        // Opponent piece blocks this direction
                        break
                    }
                    
                    checkRow += direction.0 * multiplier
                    checkCol += direction.1 * multiplier
                }
            }
            
            // A line with potential for 5-in-a-row and open ends is valuable
            if lineLength + openEnds >= 5 && openEnds > 0 {
                potentialLines += 1
                score += Double(lineLength) * 0.1
            }
        }
        
        // Bonus for positions that create multiple potential lines
        if potentialLines >= 2 {
            score += 0.25
        }
        
        return score
    }
    
    private func evaluatePositionalAdvantages(in gameState: AIGameState) -> Double {
        var score: Double = 0.0
        
        // Territory control evaluation
        let aiTerritoryControl = calculateTerritoryControl(for: playerSymbol, in: gameState)
        let opponentTerritoryControl = calculateTerritoryControl(for: gameState.opponentPlayer, in: gameState)
        
        score += (aiTerritoryControl - opponentTerritoryControl) * 0.1
        
        // Mobility evaluation - how many good moves are available
        let aiMobility = calculateMobility(for: playerSymbol, in: gameState)
        let opponentMobility = calculateMobility(for: gameState.opponentPlayer, in: gameState)
        
        score += (aiMobility - opponentMobility) * 0.05
        
        return score
    }
    
    private func calculateTerritoryControl(for player: String, in gameState: AIGameState) -> Double {
        var controlScore: Double = 0.0
        
        // Get all positions for this player
        let playerPositions = gameState.grid.compactMap { (key, value) -> (Int, Int)? in
            if value == player {
                let components = key.split(separator: ",")
                if let row = Int(components[0]), let col = Int(components[1]) {
                    return (row, col)
                }
            }
            return nil
        }
        
        // Calculate influence area around each piece
        for (row, col) in playerPositions {
            // Each piece controls a 5x5 area around it with decreasing influence
            for r in (row-2)...(row+2) {
                for c in (col-2)...(col+2) {
                    let distance = max(abs(r - row), abs(c - col))
                    if distance <= 2 {
                        controlScore += 1.0 / Double(distance + 1)
                    }
                }
            }
        }
        
        return controlScore
    }
    
    private func calculateMobility(for player: String, in gameState: AIGameState) -> Double {
        var mobilityScore: Double = 0.0
        
        // Count high-value available moves for the player
        let searchArea = getSearchArea(for: gameState)
        
        for row in searchArea.minRow...searchArea.maxRow {
            for col in searchArea.minCol...searchArea.maxCol {
                let gridKey = "\(row),\(col)"
                
                if gameState.grid[gridKey] == nil {
                    let move = AIMove(row: row, col: col, score: 0, confidence: 0, moveType: .positional)
                    let moveValue = evaluatePositionalValue(move, in: gameState)
                    
                    if moveValue > 0.1 {
                        mobilityScore += moveValue
                    }
                }
            }
        }
        
        return mobilityScore
    }
    
    private func evaluateThreatLevel(_ move: AIMove, in gameState: AIGameState) -> Double {
        var score: Double = 0.0
        
        // Enhanced immediate win detection (highest priority)
        if enhancedImmediateWinCheck(move, in: gameState) {
            score += 1000.0 // Guaranteed win should always be taken
            #if DEBUG
            print("🎯 Enhanced immediate win detected at (\(move.row), \(move.col))")
            #endif
        }
        
        // Enhanced blocking detection (second highest priority)
        if enhancedBlockingCheck(move, in: gameState) {
            score += 900.0 // Must block immediate threats
            #if DEBUG
            print("🛡️ Enhanced critical blocking detected at (\(move.row), \(move.col))")
            #endif
        }
        
        // Comprehensive threat analysis for strategic planning
        let (ownThreats, opponentThreats) = ThreatAnalyzer.analyzeAllThreats(
            in: gameState.grid, 
            currentPlayer: playerSymbol, 
            opponent: gameState.opponentPlayer
        )
        
        // Evaluate our own threat opportunities
        for threat in ownThreats {
            if threat.position.row == move.row && threat.position.col == move.col {
                switch threat.threatLevel {
                case .strong:
                    score += 200.0 // Create 4-in-a-row
                case .moderate:
                    score += 50.0  // Create 3-in-a-row
                case .weak:
                    score += 10.0  // Create 2-in-a-row
                default:
                    break
                }
                
                // Bonus for multiple open ends
                score += Double(threat.openEnds) * 25.0
            }
        }
        
        // Evaluate opponent threat blocking
        for threat in opponentThreats {
            if threat.position.row == move.row && threat.position.col == move.col {
                switch threat.threatLevel {
                case .strong:
                    score += 400.0 // Block 4-in-a-row
                case .moderate:
                    score += 100.0 // Block 3-in-a-row
                case .weak:
                    score += 20.0  // Block 2-in-a-row
                default:
                    break
                }
            }
        }
        
        // Legacy threat evaluation for additional patterns
        score += evaluatePatternThreats(move, in: gameState)
        
        return score
    }
    
    private func wouldCreateImmediateWin(_ move: AIMove, in gameState: AIGameState) -> Bool {
        // Simulate placing the move and check for immediate win (5-in-a-row)
        var simulatedGrid = gameState.grid
        simulatedGrid[move.gridKey] = playerSymbol
        
        return checkForWinAtPosition(row: move.row, col: move.col, in: simulatedGrid, player: playerSymbol)
    }
    
    private func wouldBlockOpponentWin(_ move: AIMove, in gameState: AIGameState) -> Bool {
        // Check if opponent could win at this position
        var simulatedGrid = gameState.grid
        simulatedGrid[move.gridKey] = gameState.opponentPlayer
        
        return checkForWinAtPosition(row: move.row, col: move.col, in: simulatedGrid, player: gameState.opponentPlayer)
    }
    
    private func checkForWinAtPosition(row: Int, col: Int, in grid: [String: String], player: String) -> Bool {
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        
        for direction in directions {
            var count = 1
            
            // Check both directions from this position
            for multiplier in [-1, 1] {
                var r = row + direction.0 * multiplier
                var c = col + direction.1 * multiplier
                
                while grid["\(r),\(c)"] == player {
                    count += 1
                    r += direction.0 * multiplier
                    c += direction.1 * multiplier
                }
            }
            
            if count >= 5 {
                return true
            }
        }
        
        return false
    }
    
    private func evaluateWinningThreats(_ move: AIMove, in gameState: AIGameState, for player: String) -> Double {
        var simulatedGrid = gameState.grid
        simulatedGrid[move.gridKey] = player
        
        var threatScore: Double = 0.0
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        
        for direction in directions {
            let lineInfo = analyzeLineFromPosition(
                row: move.row, col: move.col,
                direction: direction,
                in: simulatedGrid,
                for: player
            )
            
            // Score based on how close to winning
            if lineInfo.consecutiveCount == 4 && lineInfo.openEnds > 0 {
                threatScore += 5.0 // One move from win
            } else if lineInfo.consecutiveCount == 3 && lineInfo.openEnds >= 2 {
                threatScore += 2.0 // Strong threat
            } else if lineInfo.consecutiveCount == 3 && lineInfo.openEnds == 1 {
                threatScore += 1.0 // Moderate threat
            }
        }
        
        return threatScore
    }
    
    private func evaluateBlockingThreats(_ move: AIMove, in gameState: AIGameState, against opponent: String) -> Double {
        var blockingValue: Double = 0.0
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        
        for direction in directions {
            let lineInfo = analyzeLineFromPosition(
                row: move.row, col: move.col,
                direction: direction,
                in: gameState.grid,
                for: opponent
            )
            
            // Check if placing our piece here would break opponent's threat
            if lineInfo.wouldBreakThreat {
                if lineInfo.consecutiveCount >= 4 {
                    blockingValue += 4.0 // Block immediate win
                } else if lineInfo.consecutiveCount == 3 {
                    blockingValue += 2.0 // Block strong threat
                } else if lineInfo.consecutiveCount == 2 {
                    blockingValue += 0.5 // Block developing threat
                }
            }
        }
        
        return blockingValue
    }
    
    private func evaluateForkOpportunities(_ move: AIMove, in gameState: AIGameState) -> Double {
        var simulatedGrid = gameState.grid
        simulatedGrid[move.gridKey] = playerSymbol
        
        var threatsCreated = 0
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        
        for direction in directions {
            let lineInfo = analyzeLineFromPosition(
                row: move.row, col: move.col,
                direction: direction,
                in: simulatedGrid,
                for: playerSymbol
            )
            
            // Count lines that could become threats
            if lineInfo.consecutiveCount >= 3 && lineInfo.openEnds > 0 {
                threatsCreated += 1
            }
        }
        
        // Fork is when you create multiple threats simultaneously
        return threatsCreated >= 2 ? Double(threatsCreated - 1) : 0.0
    }
    
    private func evaluatePatternThreats(_ move: AIMove, in gameState: AIGameState) -> Double {
        var patternScore: Double = 0.0
        
        // Check for specific tactical patterns
        patternScore += checkForDoubleThreats(move, in: gameState)
        patternScore += checkForSpacedThreats(move, in: gameState)
        patternScore += checkForLShapeThreats(move, in: gameState)
        
        return patternScore
    }
    
    private func checkForDoubleThreats(_ move: AIMove, in gameState: AIGameState) -> Double {
        // Look for patterns like XX_XX where _ is the move position
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        var doubleThreats: Double = 0.0
        
        for direction in directions {
            // Check if we have pieces on both sides with gaps
            let leftPieces = countConsecutivePieces(from: move.row, col: move.col, direction: (-direction.0, -direction.1), in: gameState.grid, player: playerSymbol)
            let rightPieces = countConsecutivePieces(from: move.row, col: move.col, direction: direction, in: gameState.grid, player: playerSymbol)
            
            if leftPieces >= 2 && rightPieces >= 2 {
                doubleThreats += 1.0
            } else if leftPieces >= 1 && rightPieces >= 2 || leftPieces >= 2 && rightPieces >= 1 {
                doubleThreats += 0.5
            }
        }
        
        return doubleThreats
    }
    
    private func checkForSpacedThreats(_ move: AIMove, in gameState: AIGameState) -> Double {
        // Look for patterns like X_X_X where _ could be filled
        // This is more complex pattern recognition for advanced play
        return 0.0 // Placeholder for advanced pattern recognition
    }
    
    private func checkForLShapeThreats(_ move: AIMove, in gameState: AIGameState) -> Double {
        // Check for L-shaped threats that could create multiple winning lines
        return 0.0 // Placeholder for advanced pattern recognition
    }
    
    // MARK: - Line Analysis Helper
    
    struct LineAnalysisResult {
        let consecutiveCount: Int
        let openEnds: Int
        let wouldBreakThreat: Bool
        let totalInLine: Int
    }
    
    private func analyzeLineFromPosition(row: Int, col: Int, direction: (Int, Int), in grid: [String: String], for player: String) -> LineAnalysisResult {
        var consecutiveCount = 0
        var openEnds = 0
        var totalInLine = 0
        var wouldBreakThreat = false
        
        // Check both directions from the position
        for multiplier in [-1, 1] {
            var r = row + direction.0 * multiplier
            var c = col + direction.1 * multiplier
            var foundEmptyInDirection = false
            var consecutiveInDirection = 0
            
            while true {
                let gridKey = "\(r),\(c)"
                let cellValue = grid[gridKey]
                
                if cellValue == player {
                    totalInLine += 1
                    if !foundEmptyInDirection {
                        consecutiveCount += 1
                        consecutiveInDirection += 1
                    }
                } else if cellValue == nil && !foundEmptyInDirection {
                    openEnds += 1
                    foundEmptyInDirection = true
                } else if cellValue != nil && cellValue != player {
                    // Found opponent piece
                    if consecutiveInDirection >= 2 {
                        wouldBreakThreat = true
                    }
                    break
                } else {
                    // Second empty space or already found empty
                    break
                }
                
                r += direction.0 * multiplier
                c += direction.1 * multiplier
                
                // Limit search distance
                if abs(r - row) > 5 || abs(c - col) > 5 {
                    break
                }
            }
        }
        
        return LineAnalysisResult(
            consecutiveCount: consecutiveCount,
            openEnds: openEnds,
            wouldBreakThreat: wouldBreakThreat,
            totalInLine: totalInLine
        )
    }
    
    private func countConsecutivePieces(from row: Int, col: Int, direction: (Int, Int), in grid: [String: String], player: String) -> Int {
        var count = 0
        var r = row + direction.0
        var c = col + direction.1
        
        while grid["\(r),\(c)"] == player {
            count += 1
            r += direction.0
            c += direction.1
        }
        
        return count
    }
    
    // MARK: - Game End State Check
    
    private func checkGameEndState(_ gameState: AIGameState) -> Double {
        // Check if current state is a win for either player
        for (gridKey, player) in gameState.grid {
            let components = gridKey.split(separator: ",")
            if let row = Int(components[0]), let col = Int(components[1]) {
                if checkForWinAtPosition(row: row, col: col, in: gameState.grid, player: player) {
                    return player == playerSymbol ? 1000.0 : -1000.0
                }
            }
        }
        
        return 0.0 // No winner yet
    }
    
    private func applyPersonalityModifier(to score: Double, for move: AIMove, in gameState: AIGameState) -> Double {
        switch personality {
        case .balanced:
            return score
        case .aggressive:
            // Favor offensive moves
            return move.moveType == .threatening ? score * 1.2 : score
        case .defensive:
            // Favor blocking moves
            return move.moveType == .blocking ? score * 1.2 : score
        case .unpredictable:
            // Add controlled randomness
            let randomFactor = Double.random(in: 0.8...1.2)
            return score * randomFactor
        }
    }
    
    private func getSearchArea(for gameState: AIGameState) -> (minRow: Int, maxRow: Int, minCol: Int, maxCol: Int) {
        guard !gameState.grid.isEmpty else {
            // If grid is empty, start near center
            return (-3, 3, -3, 3)
        }
        
        var minRow = Int.max
        var maxRow = Int.min
        var minCol = Int.max
        var maxCol = Int.min
        
        // Find bounds of existing pieces
        for gridKey in gameState.grid.keys {
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
    
    private func determineAdaptiveDifficulty(for gameState: AIGameState) -> AIDifficulty {
        // Basic adaptive logic - can be enhanced later
        let moveCount = gameState.totalMoves
        
        if moveCount < 5 {
            return .novice
        } else if moveCount < 15 {
            return .intermediate
        } else {
            return .advanced
        }
    }
    
    private func updatePerformanceMetrics() {
        movesCalculated += 1
        averageThinkingTime = ((averageThinkingTime * Double(movesCalculated - 1)) + thinkingTime) / Double(movesCalculated)
    }
}

// MARK: - AI Bot Factory
class AIBotFactory {
    static func createBot(difficulty: AIDifficulty, personality: AIPersonality = .balanced, playerSymbol: String = "O") -> AIBotProtocol {
        return AIBot(difficulty: difficulty, personality: personality, playerSymbol: playerSymbol)
    }
    
    static func getAllDifficulties() -> [AIDifficulty] {
        return AIDifficulty.allCases
    }
    
    static func getAllPersonalities() -> [AIPersonality] {
        return AIPersonality.allCases
    }
}
