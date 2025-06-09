//
//  CriticalBlockingTests.swift
//  CarooTests
//
//  Created by AI Assistant on 09/06/25.
//

import Testing
@testable import Caroo

struct CriticalBlockingTests {
    
    @Test func testBasicCriticalBlocking() async throws {
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
        
        let aiBot = AIBot(difficulty: .intermediate, personality: .defensive, playerSymbol: "X")
        let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
        
        #expect(bestMove != nil, "AI should find a blocking move")
        #expect(bestMove?.row == 0, "Blocking move should be in row 0")
        #expect(bestMove?.col == 4, "Blocking move should be in column 4")
        #expect(bestMove?.moveType == .blocking, "Move should be classified as blocking")
        #expect(bestMove?.score ?? 0.0 >= 900.0, "Blocking move should have high score")
    }
    
    @Test func testMultipleThreatBlocking() async throws {
        // Create a scenario with multiple critical threats - AI should prioritize the most dangerous
        var grid: [String: String] = [:]
        
        // Horizontal threat (4 in a row)
        grid["0,0"] = "O"
        grid["0,1"] = "O"
        grid["0,2"] = "O"
        grid["0,3"] = "O"
        // Block at (0,4)
        
        // Vertical threat (3 in a row)
        grid["1,0"] = "O"
        grid["2,0"] = "O"
        grid["3,0"] = "O"
        // Block at (4,0)
        
        let gameState = AIGameState(
            grid: grid,
            currentPlayer: "X",
            opponentPlayer: "O",
            totalMoves: 7,
            gamePhase: .midgame
        )
        
        let aiBot = AIBot(difficulty: .advanced, personality: .defensive, playerSymbol: "X")
        let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
        
        #expect(bestMove != nil, "AI should find a blocking move")
        
        // Should prioritize the 4-in-a-row threat (immediate win)
        #expect(bestMove?.row == 0, "Should block the more dangerous 4-in-a-row threat")
        #expect(bestMove?.col == 4, "Should block at position (0,4)")
        #expect(bestMove?.moveType == .blocking, "Move should be classified as blocking")
    }
    
    @Test func testDualPurposeBlocking() async throws {
        // Create a scenario where blocking also creates a threat for the AI
        var grid: [String: String] = [:]
        
        // Opponent threat
        grid["0,0"] = "O"
        grid["0,1"] = "O"
        grid["0,2"] = "O"
        grid["0,3"] = "O"
        
        // AI pieces that would benefit from blocking at (0,4)
        grid["1,4"] = "X"
        grid["2,4"] = "X"
        // Blocking at (0,4) would create a 3-in-a-row for X vertically
        
        let gameState = AIGameState(
            grid: grid,
            currentPlayer: "X",
            opponentPlayer: "O",
            totalMoves: 6,
            gamePhase: .midgame
        )
        
        let aiBot = AIBot(difficulty: .advanced, personality: .balanced, playerSymbol: "X")
        let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
        
        #expect(bestMove != nil, "AI should find dual-purpose move")
        #expect(bestMove?.row == 0, "Should block at row 0")
        #expect(bestMove?.col == 4, "Should block at column 4")
        #expect(bestMove?.score ?? 0.0 > 950.0, "Dual-purpose move should have bonus score")
    }
    
    @Test func testDiagonalThreatBlocking() async throws {
        // Test blocking diagonal threats
        var grid: [String: String] = [:]
        grid["0,0"] = "O"
        grid["1,1"] = "O"
        grid["2,2"] = "O"
        grid["3,3"] = "O"
        // Should block at (4,4)
        
        let gameState = AIGameState(
            grid: grid,
            currentPlayer: "X",
            opponentPlayer: "O",
            totalMoves: 4,
            gamePhase: .opening
        )
        
        let aiBot = AIBot(difficulty: .intermediate, personality: .defensive, playerSymbol: "X")
        let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
        
        #expect(bestMove != nil, "AI should find diagonal blocking move")
        #expect(bestMove?.row == 4, "Should block at row 4")
        #expect(bestMove?.col == 4, "Should block at column 4")
        #expect(bestMove?.moveType == .blocking, "Move should be classified as blocking")
    }
    
    @Test func testNoviceDifficultyBlockingBehavior() async throws {
        // Test that novice AI blocks immediate wins but sometimes misses other threats
        var grid: [String: String] = [:]
        grid["0,0"] = "O"
        grid["0,1"] = "O"
        grid["0,2"] = "O"
        grid["0,3"] = "O"
        // Critical immediate win threat at (0,4)
        
        let gameState = AIGameState(
            grid: grid,
            currentPlayer: "X",
            opponentPlayer: "O",
            totalMoves: 4,
            gamePhase: .opening
        )
        
        let aiBot = AIBot(difficulty: .novice, personality: .balanced, playerSymbol: "X")
        
        // Test multiple times to account for randomness
        var blockedCount = 0
        let testRuns = 20
        
        for _ in 0..<testRuns {
            if let move = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0) {
                if move.row == 0 && move.col == 4 && move.moveType == .blocking {
                    blockedCount += 1
                }
            }
        }
        
        // Novice should block immediate wins most of the time (at least 90% for immediate wins)
        #expect(blockedCount >= testRuns * 9 / 10, "Novice AI should block immediate win threats consistently")
    }
    
    @Test func testBlockingVsWinningPriority() async throws {
        // Create scenario where AI can win AND needs to block - should prioritize winning
        var grid: [String: String] = [:]
        
        // AI can win
        grid["0,0"] = "X"
        grid["0,1"] = "X"
        grid["0,2"] = "X"
        grid["0,3"] = "X"
        // Winning move at (0,4)
        
        // Opponent threat
        grid["1,0"] = "O"
        grid["2,0"] = "O"
        grid["3,0"] = "O"
        grid["4,0"] = "O"
        // Blocking move at (5,0)
        
        let gameState = AIGameState(
            grid: grid,
            currentPlayer: "X",
            opponentPlayer: "O",
            totalMoves: 8,
            gamePhase: .midgame
        )
        
        let aiBot = AIBot(difficulty: .advanced, personality: .balanced, playerSymbol: "X")
        let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
        
        #expect(bestMove != nil, "AI should find a move")
        #expect(bestMove?.row == 0, "Should take winning move")
        #expect(bestMove?.col == 4, "Should take winning move at (0,4)")
        #expect(bestMove?.moveType == .winning, "Should prioritize winning over blocking")
    }
    
    @Test func testSpacedPatternBlocking() async throws {
        // Test blocking threats with gaps (spaced patterns)
        var grid: [String: String] = [:]
        grid["0,0"] = "O"
        grid["0,1"] = "O"
        grid["0,3"] = "O"
        grid["0,4"] = "O"
        // Gap at (0,2) - should be blocked to prevent completion
        
        let gameState = AIGameState(
            grid: grid,
            currentPlayer: "X",
            opponentPlayer: "O",
            totalMoves: 4,
            gamePhase: .opening
        )
        
        let aiBot = AIBot(difficulty: .advanced, personality: .defensive, playerSymbol: "X")
        let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
        
        #expect(bestMove != nil, "AI should find blocking move for spaced pattern")
        #expect(bestMove?.row == 0, "Should block in row 0")
        #expect(bestMove?.col == 2, "Should fill the gap at column 2")
        #expect(bestMove?.moveType == .blocking, "Move should be classified as blocking")
    }
    
    @Test func testThreatAnalyzerDirectBlocking() async throws {
        // Test ThreatAnalyzer blocking methods directly
        var grid: [String: String] = [:]
        grid["0,0"] = "O"
        grid["0,1"] = "O"
        grid["0,2"] = "O"
        grid["0,3"] = "O"
        
        // Test enhanced blocking methods
        let allBlockingMoves = ThreatAnalyzer.findAllCriticalBlockingMoves(in: grid, against: "O")
        #expect(allBlockingMoves.count > 0, "Should find blocking moves")
        #expect(allBlockingMoves[0].position.row == 0, "Should identify correct blocking row")
        #expect(allBlockingMoves[0].position.col == 4, "Should identify correct blocking column")
        #expect(allBlockingMoves[0].threatLevel == .immediateWin, "Should classify as immediate win threat")
        
        // Test best blocking move selection
        let bestBlock = ThreatAnalyzer.getBestCriticalBlockingMove(in: grid, against: "O", currentPlayer: "X")
        #expect(bestBlock != nil, "Should find best blocking move")
        #expect(bestBlock?.position.row == 0, "Best block should be at row 0")
        #expect(bestBlock?.position.col == 4, "Best block should be at column 4")
        #expect(bestBlock?.priority ?? 0.0 >= 950.0, "Should have high priority for immediate win block")
    }
    
    @Test func testMultiThreatBlockingDetection() async throws {
        // Test detection of positions that block multiple threats
        var grid: [String: String] = [:]
        
        // Create a position that blocks both horizontal and vertical threats
        grid["1,1"] = "O"
        grid["1,2"] = "O"
        grid["1,3"] = "O"
        // Horizontal threat, block at (1,4)
        
        grid["2,4"] = "O"
        grid["3,4"] = "O"
        grid["4,4"] = "O"
        // Vertical threat, also block at (1,4)
        
        let multiBlocks = ThreatAnalyzer.findMultiThreatBlockingMoves(in: grid, against: "O")
        
        #expect(multiBlocks.count > 0, "Should find multi-threat blocking positions")
        #expect(multiBlocks[0].position.row == 1, "Should identify position (1,4)")
        #expect(multiBlocks[0].position.col == 4, "Should identify position (1,4)")
        #expect(multiBlocks[0].threatsBlocked >= 2, "Should block at least 2 threats")
    }
}
