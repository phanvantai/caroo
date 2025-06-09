import Testing
@testable import Caroo

struct DebugAITests {
    
    @Test func testIsolatedWinDetection1() async throws {
        // Create a completely fresh game state
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
        
        // Create fresh AI bot
        let aiBot = AIBot(difficulty: .intermediate, personality: .balanced)
        aiBot.playerSymbol = "X"
        
        let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
        
        print("DEBUG: Test 1 - Best Move: \(String(describing: bestMove))")
        
        #expect(bestMove != nil, "AI should find a move")
        #expect(bestMove?.row == 0, "Winning move should be in row 0")
        #expect(bestMove?.col == 4, "Winning move should be in column 4")
        #expect(bestMove?.moveType == .winning, "Move should be classified as winning")
    }
    
    @Test func testIsolatedWinDetection2() async throws {
        // Create identical game state but completely separate instance
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
        
        // Create completely separate AI bot instance
        let aiBot = AIBot(difficulty: .intermediate, personality: .balanced)
        aiBot.playerSymbol = "X"
        
        let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
        
        print("DEBUG: Test 2 - Best Move: \(String(describing: bestMove))")
        
        #expect(bestMove != nil, "AI should find a move")
        #expect(bestMove?.row == 0, "Winning move should be in row 0") 
        #expect(bestMove?.col == 4, "Winning move should be in column 4")
        #expect(bestMove?.moveType == .winning, "Move should be classified as winning")
    }
    
    @Test func testDirectThreatAnalyzer() async throws {
        // Test ThreatAnalyzer methods directly
        var grid: [String: String] = [:]
        grid["0,0"] = "X"
        grid["0,1"] = "X"
        grid["0,2"] = "X"
        grid["0,3"] = "X"
        
        print("DEBUG: Grid state: \(grid)")
        
        // Test immediate win detection
        let isWin = ThreatAnalyzer.wouldCreateImmediateWin(at: 0, col: 4, in: grid, for: "X")
        print("DEBUG: wouldCreateImmediateWin(0,4): \(isWin)")
        
        // Test finding immediate wins
        let winMoves = ThreatAnalyzer.findImmediateWins(in: grid, for: "X")
        print("DEBUG: findImmediateWins result: \(winMoves)")
        
        #expect(isWin == true, "Should detect immediate win opportunity")
        #expect(winMoves.count > 0, "Should find immediate winning moves")
        #expect(winMoves.contains { $0.row == 0 && $0.col == 4 }, "Should find the correct winning position")
    }
    
    @Test func testSequentialAIBotCalls() async throws {
        // Test if the issue happens when calling the same pattern multiple times
        for i in 1...3 {
            print("DEBUG: Sequential test iteration \(i)")
            
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
            
            let aiBot = AIBot(difficulty: .intermediate, personality: .balanced)
            aiBot.playerSymbol = "X"
            
            let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
            
            print("DEBUG: Iteration \(i) - Best Move: \(String(describing: bestMove))")
            
            #expect(bestMove != nil, "AI should find a move in iteration \(i)")
            if let move = bestMove {
                #expect(move.row == 0, "Winning move should be in row 0 in iteration \(i)")
                #expect(move.col == 4, "Winning move should be in column 4 in iteration \(i)")
            }
        }
    }
    
    @Test func testPlayerSymbolPropertyBinding() async throws {
        // Test if the problem is with property binding or modification during execution
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
        
        // Create AIBot with X as constructor parameter instead of setting property
        let aiBot1 = AIBot(difficulty: .intermediate, personality: .balanced, playerSymbol: "X")
        print("DEBUG: AIBot1 playerSymbol (constructor): \(aiBot1.playerSymbol)")
        
        let bestMove1 = aiBot1.calculateBestMove(for: gameState, timeLimit: 1.0)
        print("DEBUG: AIBot1 bestMove: \(String(describing: bestMove1))")
        print("DEBUG: AIBot1 playerSymbol (after calc): \(aiBot1.playerSymbol)")
        
        #expect(aiBot1.playerSymbol == "X", "AIBot1 should have playerSymbol = X from constructor")
        #expect(bestMove1 != nil, "AIBot1 should find a move")
        #expect(bestMove1?.moveType == .winning, "AIBot1 should find winning move")
        
        // Test setting property after construction
        let aiBot2 = AIBot(difficulty: .intermediate, personality: .balanced)
        print("DEBUG: AIBot2 playerSymbol (default): \(aiBot2.playerSymbol)")
        aiBot2.playerSymbol = "X"
        print("DEBUG: AIBot2 playerSymbol (after setting): \(aiBot2.playerSymbol)")
        
        let bestMove2 = aiBot2.calculateBestMove(for: gameState, timeLimit: 1.0)
        print("DEBUG: AIBot2 bestMove: \(String(describing: bestMove2))")
        print("DEBUG: AIBot2 playerSymbol (after calc): \(aiBot2.playerSymbol)")
        
        #expect(aiBot2.playerSymbol == "X", "AIBot2 should have playerSymbol = X after setting")
        #expect(bestMove2 != nil, "AIBot2 should find a move")
        #expect(bestMove2?.moveType == .winning, "AIBot2 should find winning move")
        
        // Compare results
        #expect(bestMove1?.row == bestMove2?.row, "Both approaches should give same row")
        #expect(bestMove1?.col == bestMove2?.col, "Both approaches should give same col")
    }
}
