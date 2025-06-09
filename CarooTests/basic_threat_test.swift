import Testing
@testable import Caroo

struct BasicThreatTest {
    
    @Test func testBasicWinDetection() async throws {
        // Create the simplest possible test case
        var grid: [String: String] = [:]
        grid["0,0"] = "X"
        grid["0,1"] = "X"
        grid["0,2"] = "X"
        grid["0,3"] = "X"
        
        print("DEBUG: Grid = \(grid)")
        
        // Test the core ThreatAnalyzer function directly
        let isWin = ThreatAnalyzer.wouldCreateImmediateWin(at: 0, col: 4, in: grid, for: "X")
        print("DEBUG: wouldCreateImmediateWin(0,4) = \(isWin)")
        
        let winMoves = ThreatAnalyzer.findImmediateWins(in: grid, for: "X")
        print("DEBUG: findImmediateWins = \(winMoves)")
        
        let bestWin = ThreatAnalyzer.getBestImmediateWin(in: grid, for: "X")
        print("DEBUG: getBestImmediateWin = \(String(describing: bestWin))")
        
        #expect(isWin == true, "Should detect immediate win")
        #expect(winMoves.count > 0, "Should find winning moves")
        #expect(bestWin != nil, "Should find best winning move")
        #expect(bestWin?.row == 0 && bestWin?.col == 4, "Should find correct position")
    }
    
    @Test func testBasicAIBotWithSimpleState() async throws {
        // Test AIBot with minimal setup
        var grid: [String: String] = [:]
        grid["0,0"] = "X"
        grid["0,1"] = "X"
        grid["0,2"] = "X"
        grid["0,3"] = "X"
        
        let gameState = AIGameState(
            grid: grid,
            currentPlayer: "X",
            opponentPlayer: "O",
            totalMoves: 4,
            gamePhase: .opening
        )
        
        let aiBot = AIBot(difficulty: .intermediate, personality: .balanced, playerSymbol: "X")
        
        print("DEBUG: AI Bot created with playerSymbol: \(aiBot.playerSymbol)")
        print("DEBUG: Game state currentPlayer: \(gameState.currentPlayer)")
        
        let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
        
        print("DEBUG: Best move calculated: \(String(describing: bestMove))")
        
        #expect(bestMove != nil, "AI should find a move")
        if let move = bestMove {
            #expect(move.row == 0, "Should find winning row")
            #expect(move.col == 4, "Should find winning column")
            #expect(move.moveType == .winning, "Should be classified as winning")
        }
    }
}
