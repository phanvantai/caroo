//
//  MCTSEngine.swift
//  Caroo
//
//  Monte Carlo Tree Search implementation for adaptive AI difficulty
//

import Foundation
import GameplayKit

class MCTSEngine {
    
    // MARK: - MCTS Node
    class MCTSNode {
        var position: (row: Int, col: Int)?
        var player: String
        var grid: [String: String]
        var wins: Double = 0.0
        var visits: Int = 0
        var parent: MCTSNode?
        var children: [MCTSNode] = []
        var untriedMoves: [(Int, Int)] = []
        
        init(grid: [String: String], player: String, parent: MCTSNode? = nil, availableMoves: [(Int, Int)] = []) {
            self.grid = grid
            self.player = player
            self.parent = parent
            self.untriedMoves = availableMoves
        }
        
        var ucb1Score: Double {
            guard visits > 0 else { return Double.infinity }
            guard let parent = parent, parent.visits > 0 else { return wins / Double(visits) }
            
            let exploitation = wins / Double(visits)
            let exploration = sqrt(2.0 * log(Double(parent.visits)) / Double(visits))
            return exploitation + exploration
        }
        
        var isFullyExpanded: Bool {
            return untriedMoves.isEmpty
        }
        
        var isTerminal: Bool {
            if let pos = position {
                return MCTSEngine.checkWin(at: pos.row, col: pos.col, player: player, grid: grid)
            }
            return false
        }
    }
    
    // MARK: - Properties
    private let randomSource = GKRandomSource.sharedRandom()
    
    // MARK: - Public Methods
    
    func findBestMove(for grid: [String: String], player: String, opponent: String, iterations: Int) -> (row: Int, col: Int)? {
        
        let availableMoves = getAvailableMoves(from: grid)
        guard !availableMoves.isEmpty else { return nil }
        
        // For very early game, use heuristics
        if grid.count <= 2 {
            return getEarlyGameMove(grid: grid, availableMoves: availableMoves)
        }
        
        // Create root node
        let rootNode = MCTSNode(grid: grid, player: player, availableMoves: availableMoves)
        
        // Run MCTS iterations
        for _ in 0..<iterations {
            let selectedNode = selection(node: rootNode)
            let expandedNode = expansion(node: selectedNode)
            let result = simulation(node: expandedNode, player: player, opponent: opponent)
            backpropagation(node: expandedNode, result: result)
        }
        
        // Select best move based on visit count (more robust than win rate)
        var bestMove: (row: Int, col: Int)?
        var bestVisits = 0
        
        for child in rootNode.children {
            if child.visits > bestVisits {
                bestVisits = child.visits
                bestMove = child.position
            }
        }
        
        return bestMove
    }
    
    // MARK: - MCTS Algorithm Steps
    
    private func selection(node: MCTSNode) -> MCTSNode {
        var currentNode = node
        
        while !currentNode.isTerminal && currentNode.isFullyExpanded {
            // Select child with highest UCB1 score
            var bestChild: MCTSNode?
            var bestScore = -Double.infinity
            
            for child in currentNode.children {
                let score = child.ucb1Score
                if score > bestScore {
                    bestScore = score
                    bestChild = child
                }
            }
            
            if let bestChild = bestChild {
                currentNode = bestChild
            } else {
                break
            }
        }
        
        return currentNode
    }
    
    private func expansion(node: MCTSNode) -> MCTSNode {
        if node.isTerminal || node.untriedMoves.isEmpty {
            return node
        }
        
        // Pick a random untried move
        let moveIndex = randomSource.nextInt(upperBound: node.untriedMoves.count)
        let move = node.untriedMoves.remove(at: moveIndex)
        
        // Create new grid state
        var newGrid = node.grid
        let nextPlayer = node.player == "X" ? "O" : "X"
        newGrid[MCTSEngine.gridKey(move.0, move.1)] = node.player
        
        // Calculate available moves for the child node
        let childAvailableMoves = getAvailableMoves(from: newGrid)
        
        // Create child node
        let childNode = MCTSNode(grid: newGrid, player: nextPlayer, parent: node, availableMoves: childAvailableMoves)
        childNode.position = move
        node.children.append(childNode)
        
        return childNode
    }
    
    private func simulation(node: MCTSNode, player: String, opponent: String) -> Double {
        var currentGrid = node.grid
        var currentPlayer = node.player
        var moves = 0
        let maxMoves = 25 // Increased simulation depth for better lookahead
        
        while moves < maxMoves {
            // Check for immediate win
            if let pos = node.position, moves == 0 {
                if MCTSEngine.checkWin(at: pos.row, col: pos.col, player: currentPlayer == "X" ? "O" : "X", grid: currentGrid) {
                    // Game is already won by the previous player
                    let winner = currentPlayer == "X" ? "O" : "X"
                    return winner == player ? 1.0 : 0.0
                }
            }
            
            let availableMoves = getAvailableMoves(from: currentGrid)
            if availableMoves.isEmpty {
                break // Draw
            }
            
            // Use enhanced move selection for simulation with strategic bias
            let move = selectEnhancedSimulationMove(moves: availableMoves, grid: currentGrid, player: currentPlayer, depth: moves)
            currentGrid[MCTSEngine.gridKey(move.0, move.1)] = currentPlayer
            
            // Check for win
            if MCTSEngine.checkWin(at: move.0, col: move.1, player: currentPlayer, grid: currentGrid) {
                return currentPlayer == player ? 1.0 : 0.0
            }
            
            // Switch player
            currentPlayer = currentPlayer == "X" ? "O" : "X"
            moves += 1
        }
        
        // Enhanced position evaluation for incomplete games
        let finalScore = evaluateAdvancedPosition(grid: currentGrid, player: player, opponent: opponent)
        return finalScore
    }
    
    private func backpropagation(node: MCTSNode, result: Double) {
        var currentNode: MCTSNode? = node
        
        while let node = currentNode {
            node.visits += 1
            node.wins += result
            currentNode = node.parent
        }
    }
    
    // MARK: - Helper Methods
    
    private func getEarlyGameMove(grid: [String: String], availableMoves: [(Int, Int)]) -> (row: Int, col: Int)? {
        // First move: center
        if grid.isEmpty {
            return (0, 0)
        }
        
        // Second move: adjacent to existing piece
        if grid.count == 1 {
            let existingKey = grid.keys.first!
            let components = existingKey.split(separator: ",")
            let row = Int(components[0])!
            let col = Int(components[1])!
            
            let adjacentMoves = [
                (row + 1, col), (row - 1, col),
                (row, col + 1), (row, col - 1),
                (row + 1, col + 1), (row - 1, col - 1),
                (row + 1, col - 1), (row - 1, col + 1)
            ]
            
            for move in adjacentMoves {
                if availableMoves.contains(where: { $0.0 == move.0 && $0.1 == move.1 }) {
                    return move
                }
            }
        }
        
        return availableMoves.randomElement()
    }
    
    private func selectSimulationMove(moves: [(Int, Int)], grid: [String: String], player: String) -> (row: Int, col: Int) {
        let opponent = player == "X" ? "O" : "X"
        
        // 1. Try to win immediately
        for move in moves {
            var testGrid = grid
            testGrid[MCTSEngine.gridKey(move.0, move.1)] = player
            if MCTSEngine.checkWin(at: move.0, col: move.1, player: player, grid: testGrid) {
                return move
            }
        }
        
        // 2. Block opponent win
        for move in moves {
            var testGrid = grid
            testGrid[MCTSEngine.gridKey(move.0, move.1)] = opponent
            if MCTSEngine.checkWin(at: move.0, col: move.1, player: opponent, grid: testGrid) {
                return move
            }
        }
        
        // 3. Random move with slight preference for central positions
        let weightedMoves = moves.map { move in
            let centerDistance = abs(move.0) + abs(move.1)
            let weight = max(1, 10 - centerDistance)
            return (move, weight)
        }
        
        let totalWeight = weightedMoves.reduce(0) { $0 + $1.1 }
        let randomValue = randomSource.nextUniform() * Float(totalWeight)
        
        var currentWeight = 0
        for (move, weight) in weightedMoves {
            currentWeight += weight
            if Float(currentWeight) >= randomValue {
                return move
            }
        }
        
        return moves.randomElement()!
    }
    
    private func selectEnhancedSimulationMove(moves: [(Int, Int)], grid: [String: String], player: String, depth: Int) -> (row: Int, col: Int) {
        let opponent = player == "X" ? "O" : "X"
        
        // 1. Try to win immediately
        for move in moves {
            var testGrid = grid
            testGrid[MCTSEngine.gridKey(move.0, move.1)] = player
            if MCTSEngine.checkWin(at: move.0, col: move.1, player: player, grid: testGrid) {
                return move
            }
        }
        
        // 2. Block opponent win
        for move in moves {
            var testGrid = grid
            testGrid[MCTSEngine.gridKey(move.0, move.1)] = opponent
            if MCTSEngine.checkWin(at: move.0, col: move.1, player: opponent, grid: testGrid) {
                return move
            }
        }
        
        // 3. Early simulation: use more strategic moves (50% chance)
        if depth < 5 && randomSource.nextUniform() < 0.5 {
            var bestMove: (row: Int, col: Int)?
            var bestScore = Int.min
            
            for move in moves.prefix(min(8, moves.count)) { // Limit for performance
                var testGrid = grid
                testGrid[MCTSEngine.gridKey(move.0, move.1)] = player
                let score = evaluateStrategicMove(at: move, grid: testGrid, player: player, opponent: opponent)
                
                if score > bestScore {
                    bestScore = score
                    bestMove = move
                }
            }
            
            if let strategicMove = bestMove {
                return strategicMove
            }
        }
        
        // 4. Enhanced weighted random with strategic considerations
        let weightedMoves = moves.map { move in
            let centerDistance = abs(move.0) + abs(move.1)
            let positionWeight = max(1, 10 - centerDistance)
            
            // Add strategic weight for moves near existing pieces
            let proximityWeight = getProximityWeight(move: move, grid: grid)
            
            let totalWeight = positionWeight + proximityWeight
            return (move, totalWeight)
        }
        
        let totalWeight = weightedMoves.reduce(0) { $0 + $1.1 }
        let randomValue = randomSource.nextUniform() * Float(totalWeight)
        
        var currentWeight = 0
        for (move, weight) in weightedMoves {
            currentWeight += weight
            if Float(currentWeight) >= randomValue {
                return move
            }
        }
        
        return moves.randomElement()!
    }
    
    private func evaluateStrategicMove(at move: (Int, Int), grid: [String: String], player: String, opponent: String) -> Int {
        var score = 0
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        
        for direction in directions {
            let playerLine = getLineLength(from: move, direction: direction, player: player, grid: grid)
            let opponentLine = getLineLength(from: move, direction: direction, player: opponent, grid: grid)
            
            // Score for creating threats
            score += scoreForLineLength(playerLine) * 2
            
            // Score for blocking opponent threats
            score += scoreForLineLength(opponentLine)
            
            // Bonus for extending existing lines
            if playerLine > 1 {
                score += playerLine * 50
            }
        }
        
        return score
    }
    
    private func getProximityWeight(move: (Int, Int), grid: [String: String]) -> Int {
        var weight = 0
        let adjacentOffsets = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]
        
        for offset in adjacentOffsets {
            let adjRow = move.0 + offset.0
            let adjCol = move.1 + offset.1
            if grid[MCTSEngine.gridKey(adjRow, adjCol)] != nil {
                weight += 3 // Bonus for being adjacent to existing pieces
            }
        }
        
        return weight
    }
    
    private func getLineLength(from position: (Int, Int), direction: (Int, Int), player: String, grid: [String: String]) -> Int {
        let (startRow, startCol) = position
        var count = 0
        
        // Count in positive direction
        var row = startRow + direction.0
        var col = startCol + direction.1
        while grid[MCTSEngine.gridKey(row, col)] == player {
            count += 1
            row += direction.0
            col += direction.1
        }
        
        // Count in negative direction
        row = startRow - direction.0
        col = startCol - direction.1
        while grid[MCTSEngine.gridKey(row, col)] == player {
            count += 1
            row -= direction.0
            col -= direction.1
        }
        
        return count
    }
    
    private func scoreForLineLength(_ length: Int) -> Int {
        switch length {
        case 4...: return 1000  // Four or more in a row
        case 3: return 100      // Three in a row
        case 2: return 10       // Two in a row
        case 1: return 1        // Single piece
        default: return 0
        }
    }
    
    private func evaluatePosition(grid: [String: String], player: String) -> Int {
        var score = 0
        let opponent = player == "X" ? "O" : "X"
        
        // Simple position evaluation
        for (key, piece) in grid {
            let components = key.split(separator: ",")
            let row = Int(components[0])!
            let col = Int(components[1])!
            
            let centerDistance = abs(row) + abs(col)
            let positionValue = max(1, 5 - centerDistance)
            
            if piece == player {
                score += positionValue
            } else if piece == opponent {
                score -= positionValue
            }
        }
        
        return score
    }
    
    private func evaluateAdvancedPosition(grid: [String: String], player: String, opponent: String) -> Double {
        var playerScore = 0.0
        var opponentScore = 0.0
        
        // Evaluate all potential lines
        let evaluatedPositions = Set<String>()
        
        for (key, piece) in grid {
            let components = key.split(separator: ",")
            let row = Int(components[0])!
            let col = Int(components[1])!
            
            // Skip if already evaluated
            let posKey = "\(row),\(col)"
            if evaluatedPositions.contains(posKey) { continue }
            
            let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
            
            for direction in directions {
                let lineScore = evaluateLineFromPosition(row: row, col: col, direction: direction, 
                                                       player: piece, grid: grid)
                
                if piece == player {
                    playerScore += lineScore
                } else if piece == opponent {
                    opponentScore += lineScore
                }
            }
        }
        
        // Normalize the scores and return relative advantage
        let totalScore = playerScore + opponentScore
        if totalScore == 0 { return 0.5 }
        
        let advantage = playerScore / totalScore
        
        // Apply strategic modifiers
        let centerControl = evaluateCenterControl(grid: grid, player: player)
        let connectivity = evaluateConnectivity(grid: grid, player: player)
        
        let finalScore = advantage + (centerControl * 0.1) + (connectivity * 0.1)
        return max(0.0, min(1.0, finalScore))
    }
    
    private func evaluateLineFromPosition(row: Int, col: Int, direction: (Int, Int), player: String, grid: [String: String]) -> Double {
        var score = 0.0
        let lineLength = getLineLength(from: (row, col), direction: direction, player: player, grid: grid)
        
        if lineLength > 0 {
            // Exponential scoring for longer lines
            switch lineLength {
            case 1: score = 1.0
            case 2: score = 10.0
            case 3: score = 100.0
            case 4: score = 1000.0
            case 5...: score = 10000.0
            default: score = 0.0
            }
            
            // Bonus for having potential extensions
            let extensions = countPotentialExtensions(row: row, col: col, direction: direction, 
                                                    player: player, grid: grid, lineLength: lineLength)
            score *= (1.0 + Double(extensions) * 0.2)
        }
        
        return score
    }
    
    private func countPotentialExtensions(row: Int, col: Int, direction: (Int, Int), 
                                        player: String, grid: [String: String], lineLength: Int) -> Int {
        var extensions = 0
        
        // Check both ends of the line for empty spaces
        let endPositions = [
            (row + direction.0 * lineLength, col + direction.1 * lineLength),
            (row - direction.0 * lineLength, col - direction.1 * lineLength)
        ]
        
        for endPos in endPositions {
            let key = MCTSEngine.gridKey(endPos.0, endPos.1)
            if grid[key] == nil {
                extensions += 1
            }
        }
        
        return extensions
    }
    
    private func evaluateCenterControl(grid: [String: String], player: String) -> Double {
        var control = 0.0
        let centerRadius = 3
        
        for row in -centerRadius...centerRadius {
            for col in -centerRadius...centerRadius {
                let key = MCTSEngine.gridKey(row, col)
                if grid[key] == player {
                    let distance = max(abs(row), abs(col))
                    control += 1.0 / Double(distance + 1)
                }
            }
        }
        
        return control / 10.0 // Normalize
    }
    
    private func evaluateConnectivity(grid: [String: String], player: String) -> Double {
        var connectivity = 0.0
        let playerPositions = grid.compactMap { (key, piece) -> (Int, Int)? in
            guard piece == player else { return nil }
            let components = key.split(separator: ",")
            return (Int(components[0])!, Int(components[1])!)
        }
        
        // Count connected components and adjacencies
        for i in 0..<playerPositions.count {
            for j in (i+1)..<playerPositions.count {
                let pos1 = playerPositions[i]
                let pos2 = playerPositions[j]
                let distance = max(abs(pos1.0 - pos2.0), abs(pos1.1 - pos2.1))
                
                if distance == 1 {
                    connectivity += 1.0 // Adjacent pieces
                } else if distance <= 2 {
                    connectivity += 0.5 // Close pieces
                }
            }
        }
        
        return connectivity / Double(max(1, playerPositions.count))
    }
    
    // MARK: - Utility Functions
    
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
                let key = MCTSEngine.gridKey(row, col)
                if grid[key] == nil {
                    // Only include moves that are adjacent to existing pieces
                    if isAdjacentToOccupied(row: row, col: col, occupiedPositions: occupiedPositions) {
                        availableMoves.append((row, col))
                    }
                }
            }
        }
        
        // Limit the number of moves for performance
        if availableMoves.count > 25 {
            return Array(availableMoves.shuffled().prefix(25))
        }
        
        return availableMoves
    }
    
    private func isAdjacentToOccupied(row: Int, col: Int, occupiedPositions: [(Int, Int)]) -> Bool {
        for (existingRow, existingCol) in occupiedPositions {
            let distance = max(abs(row - existingRow), abs(col - existingCol))
            if distance <= 1 {
                return true
            }
        }
        return false
    }
    
    private static func gridKey(_ row: Int, _ col: Int) -> String {
        return "\(row),\(col)"
    }
    
    private static func checkWin(at row: Int, col: Int, player: String, grid: [String: String]) -> Bool {
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        
        for direction in directions {
            var count = 1
            
            // Check both directions
            for multiplier in [-1, 1] {
                var r = row + direction.0 * multiplier
                var c = col + direction.1 * multiplier
                
                while grid[gridKey(r, c)] == player {
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
}
