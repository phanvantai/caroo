import Testing
@testable import Caroo

struct SimpleAIDebugTest {
    
    @Test func debugAIBotCreation() async throws {
        print("🔍 DEBUG: Testing AIBot creation")
        let aiBot = AIBot(difficulty: .intermediate, personality: .defensive, playerSymbol: "X")
        #expect(aiBot.playerSymbol == "X", "AIBot should have correct player symbol")
        print("✅ AIBot created successfully with symbol: \(aiBot.playerSymbol)")
    }
    
    @Test func debugGameStateCreation() async throws {
        print("🔍 DEBUG: Testing AIGameState creation")
        var grid: [String: String] = [:]
        grid["0,0"] = "O"
        grid["0,1"] = "O"
        grid["0,2"] = "O"
        grid["0,3"] = "O"
        
        let gameState = AIGameState(
            grid: grid,
            currentPlayer: "X",
            opponentPlayer: "O",
            totalMoves: 4,
            gamePhase: .opening
        )
        
        #expect(gameState.currentPlayer == "X", "Game state should have correct current player")
        #expect(gameState.opponentPlayer == "O", "Game state should have correct opponent")
        #expect(gameState.grid.count == 4, "Grid should have 4 moves")
        print("✅ GameState created with \(gameState.grid.count) moves")
    }
    
    @Test func debugBasicThreatAnalysis() async throws {
        print("🔍 DEBUG: Testing basic threat analysis directly")
        var grid: [String: String] = [:]
        grid["0,0"] = "O"
        grid["0,1"] = "O"
        grid["0,2"] = "O"
        grid["0,3"] = "O"
        
        // Check if O can win at (0,4)
        print("Grid: \(grid)")
        let canOWin = ThreatAnalyzer.wouldCreateImmediateWin(at: 0, col: 4, in: grid, for: "O")
        print("Can O win at (0,4)? \(canOWin)")
        
        // If O can win there, X should block
        let shouldXBlock = ThreatAnalyzer.wouldBlockCriticalThreat(at: 0, col: 4, in: grid, against: "O")
        print("Should X block at (0,4)? \(shouldXBlock)")
        
        #expect(canOWin == true, "O should be able to win at (0,4)")
        #expect(shouldXBlock == true, "X should block at (0,4)")
    }
    
    @Test func debugAIMove() async throws {
        print("🔍 DEBUG: Testing AI move calculation")
        var grid: [String: String] = [:]
        grid["0,0"] = "O"
        grid["0,1"] = "O"  
        grid["0,2"] = "O"
        grid["0,3"] = "O"
        
        let gameState = AIGameState(
            grid: grid,
            currentPlayer: "X",
            opponentPlayer: "O",
            totalMoves: 4,
            gamePhase: .opening
        )
        
        let aiBot = AIBot(difficulty: .intermediate, personality: .defensive, playerSymbol: "X")
        let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
        
        print("Best move found: \(String(describing: bestMove))")
        if let move = bestMove {
            print("Move details: row=\(move.row), col=\(move.col), type=\(move.moveType), score=\(move.score)")
        } else {
            print("❌ No move found!")
        }
        
        #expect(bestMove != nil, "AI should find a move")
    }
}
