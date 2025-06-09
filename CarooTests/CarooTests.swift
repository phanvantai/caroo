//
//  CarooTests.swift
//  CarooTests
//
//  Created by Tai Phan Van on 14/1/25.
//

import Testing
@testable import Caroo

struct CarooTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    // MARK: - Phase 2.1: Immediate Win Detection Tests
    
    @Test func testImmediateWinDetection_Horizontal() async throws {
        // Create a game state with 4 X's in a row, missing the 5th
        var grid: [String: String] = [:]
        grid["0,0"] = "X"
        grid["0,1"] = "X"
        grid["0,2"] = "X"
        grid["0,3"] = "X"
        // Position (0,4) should be the winning move
        
        let gameState = AIGameState(
            grid: grid,
            currentPlayer: "X",
            opponentPlayer: "O",
            totalMoves: 4,
            gamePhase: .opening
        )
        
        // FIX: Use the constructor with playerSymbol parameter instead of setting it after
        let aiBot = AIBot(difficulty: .intermediate, personality: .balanced, playerSymbol: "X")
        
        let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
        
        #expect(bestMove != nil, "AI should find a move")
        #expect(bestMove?.row == 0, "Winning move should be in row 0")
        #expect(bestMove?.col == 4, "Winning move should be in column 4")
        #expect(bestMove?.moveType == .winning, "Move should be classified as winning")
        #expect(bestMove?.score == 1000.0, "Winning move should have maximum score")
    }
    
    @Test func testImmediateWinDetection_Vertical() async throws {
        // Create a game state with 4 X's in a column, missing the 5th
        var grid: [String: String] = [:]
        grid["0,0"] = "X"
        grid["1,0"] = "X"
        grid["2,0"] = "X"
        grid["3,0"] = "X"
        // Position (4,0) should be the winning move
        
        let gameState = AIGameState(
            grid: grid,
            currentPlayer: "X",
            opponentPlayer: "O",
            totalMoves: 4,
            gamePhase: .opening
        )
        
        // FIX: Use the constructor with playerSymbol parameter instead of setting it after
        let aiBot = AIBot(difficulty: .advanced, personality: .balanced, playerSymbol: "X")
        
        let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
        
        #expect(bestMove != nil, "AI should find a move")
        #expect(bestMove?.row == 4, "Winning move should be in row 4")
        #expect(bestMove?.col == 0, "Winning move should be in column 0")
        #expect(bestMove?.moveType == .winning, "Move should be classified as winning")
    }
    
    @Test func testImmediateWinDetection_Diagonal() async throws {
        // Create a game state with 4 X's in a diagonal, missing the 5th
        var grid: [String: String] = [:]
        grid["0,0"] = "X"
        grid["1,1"] = "X"
        grid["2,2"] = "X"
        grid["3,3"] = "X"
        // Position (4,4) should be the winning move
        
        let gameState = AIGameState(
            grid: grid,
            currentPlayer: "X",
            opponentPlayer: "O",
            totalMoves: 4,
            gamePhase: .opening
        )
        
        // FIX: Use the constructor with playerSymbol parameter instead of setting it after
        let aiBot = AIBot(difficulty: .master, personality: .aggressive, playerSymbol: "X")
        
        let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
        
        #expect(bestMove != nil, "AI should find a move")
        #expect(bestMove?.row == 4, "Winning move should be in row 4")
        #expect(bestMove?.col == 4, "Winning move should be in column 4")
        #expect(bestMove?.moveType == .winning, "Move should be classified as winning")
    }
    
    @Test func testCriticalBlockingDetection() async throws {
        // Create a game state where opponent (O) has 4 in a row and needs to be blocked
        var grid: [String: String] = [:]
        grid["0,0"] = "O"
        grid["0,1"] = "O"
        grid["0,2"] = "O"
        grid["0,3"] = "O"
        // Position (0,4) should be blocked by X
        
        let gameState = AIGameState(
            grid: grid,
            currentPlayer: "X",
            opponentPlayer: "O",
            totalMoves: 4,
            gamePhase: .opening
        )
        
        // FIX: Use the constructor with playerSymbol parameter instead of setting it after
        let aiBot = AIBot(difficulty: .intermediate, personality: .defensive, playerSymbol: "X")
        
        let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
        
        #expect(bestMove != nil, "AI should find a move")
        #expect(bestMove?.row == 0, "Blocking move should be in row 0")
        #expect(bestMove?.col == 4, "Blocking move should be in column 4")
        #expect(bestMove?.moveType == .blocking, "Move should be classified as blocking")
        #expect(bestMove?.score == 900.0, "Blocking move should have high score")
    }
    
    @Test func testWinPriorityOverBlocking() async throws {
        // Create a scenario where AI can win AND needs to block - should prioritize winning
        var grid: [String: String] = [:]
        // AI (X) can win horizontally
        grid["0,0"] = "X"
        grid["0,1"] = "X"
        grid["0,2"] = "X"
        grid["0,3"] = "X"
        // Opponent (O) can win vertically but AI should prioritize own win
        grid["1,0"] = "O"
        grid["2,0"] = "O"
        grid["3,0"] = "O"
        grid["4,0"] = "O"
        
        let gameState = AIGameState(
            grid: grid,
            currentPlayer: "X",
            opponentPlayer: "O",
            totalMoves: 8,
            gamePhase: .midgame
        )
        
        // FIX: Use the constructor with playerSymbol parameter instead of setting it after
        let aiBot = AIBot(difficulty: .advanced, personality: .balanced, playerSymbol: "X")
        
        let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
        
        #expect(bestMove != nil, "AI should find a move")
        #expect(bestMove?.row == 0, "Should take winning move in row 0")
        #expect(bestMove?.col == 4, "Should take winning move in column 4")
        #expect(bestMove?.moveType == .winning, "Should prioritize winning over blocking")
    }
    
    @Test func testNoviceDifficultyStillTakesWins() async throws {
        // Even novice AI should always take immediate wins (teaching moment)
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
        
        // FIX: Use the constructor with playerSymbol parameter instead of setting it after
        let aiBot = AIBot(difficulty: .novice, personality: .balanced, playerSymbol: "X")
        
        let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
        
        #expect(bestMove != nil, "Novice AI should find winning move")
        #expect(bestMove?.moveType == .winning, "Novice should take winning moves")
    }
    
    @Test func testThreatAnalyzerDirectMethods() async throws {
        // Test ThreatAnalyzer methods directly
        var grid: [String: String] = [:]
        grid["0,0"] = "X"
        grid["0,1"] = "X"
        grid["0,2"] = "X"
        grid["0,3"] = "X"
        
        // Test immediate win detection
        let isWin = ThreatAnalyzer.wouldCreateImmediateWin(at: 0, col: 4, in: grid, for: "X")
        #expect(isWin == true, "Should detect immediate win opportunity")
        
        // Test non-winning move
        let isNotWin = ThreatAnalyzer.wouldCreateImmediateWin(at: 1, col: 1, in: grid, for: "X")
        #expect(isNotWin == false, "Should not detect win for non-winning position")
        
        // Test finding immediate wins
        let winMoves = ThreatAnalyzer.findImmediateWins(in: grid, for: "X")
        #expect(winMoves.count > 0, "Should find immediate winning moves")
        #expect(winMoves.contains { $0.row == 0 && $0.col == 4 }, "Should find the correct winning position")
    }

}
