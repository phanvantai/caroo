import Testing
@testable import Caroo

struct MinimalBlockingTest {
    
    @Test func testBasicBlocking() async throws {
        print("🔍 DEBUG: Testing basic blocking scenario")
        
        // Create the exact same scenario as CriticalBlockingTests
        var grid: [String: String] = [:]
        grid["0,0"] = "O"
        grid["0,1"] = "O" 
        grid["0,2"] = "O"
        grid["0,3"] = "O"
        
        print("🔍 DEBUG: Grid created with \(grid.count) moves")
        for (key, value) in grid {
            print("🔍 DEBUG: Grid[\(key)] = \(value)")
        }
        
        let gameState = AIGameState(
            grid: grid,
            currentPlayer: "X",
            opponentPlayer: "O",
            totalMoves: 4,
            gamePhase: .opening
        )
        
        print("🔍 DEBUG: Game state created successfully")
        
        let aiBot = AIBot(difficulty: .intermediate, personality: .defensive, playerSymbol: "X")
        print("🔍 DEBUG: AI bot created successfully")
        
        let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
        print("🔍 DEBUG: Best move calculated: \(String(describing: bestMove))")
        
        #expect(bestMove != nil, "AI should find a move")
        if let move = bestMove {
            print("🔍 DEBUG: Move found at (\(move.row), \(move.col)) with score \(move.score) and moveType \(move.moveType)")
            print("🔍 DEBUG: Expected position would be (0,4) to block the threat")
            print("🔍 DEBUG: Expected moveType would be .blocking")
            print("🔍 DEBUG: Expected score would be >= 900.0")
            
            // Compare with CriticalBlockingTests expectations
            if move.row == 0 && move.col == 4 {
                print("🔍 DEBUG: ✅ Position matches expected (0,4)")
            } else {
                print("🔍 DEBUG: ❌ Position mismatch! Got (\(move.row),\(move.col)), expected (0,4)")
            }
            
            if move.moveType == .blocking {
                print("🔍 DEBUG: ✅ MoveType matches expected .blocking")
            } else {
                print("🔍 DEBUG: ❌ MoveType mismatch! Got \(move.moveType), expected .blocking")
            }
            
            if move.score >= 900.0 {
                print("🔍 DEBUG: ✅ Score meets threshold (>= 900.0)")
            } else {
                print("🔍 DEBUG: ❌ Score below threshold! Got \(move.score), expected >= 900.0")
            }
        }
    }
}
