//
//  isolated_debug_test.swift
//  CarooTests
//
//  Created by AI Assistant on 09/06/25.
//

import Testing
@testable import Caroo

struct IsolatedDebugTest {
    
    @Test func testAIBotStateInspection() async throws {
        print("🔍 Starting AIBot state inspection test...")
        
        // Create the exact same scenario as the failing test
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
        
        // Create AIBot with explicit constructor
        let aiBot = AIBot(difficulty: .intermediate, personality: .balanced, playerSymbol: "X")
        
        // Inspect AIBot state before calculation
        print("📊 AIBot state before calculateBestMove:")
        print("  - playerSymbol: '\(aiBot.playerSymbol)'")
        print("  - difficulty: \(aiBot.difficulty)")
        print("  - personality: \(aiBot.personality)")
        
        // Test ThreatAnalyzer directly first
        print("🎯 Testing ThreatAnalyzer directly:")
        let directWinMoves = ThreatAnalyzer.findImmediateWins(in: grid, for: "X")
        print("  - Direct ThreatAnalyzer.findImmediateWins: \(directWinMoves)")
        
        let directBestWin = ThreatAnalyzer.getBestImmediateWin(in: grid, for: "X")
        print("  - Direct ThreatAnalyzer.getBestImmediateWin: \(String(describing: directBestWin))")
        
        // Now test through AIBot
        print("🤖 Testing through AIBot:")
        let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
        
        print("📊 AIBot calculation result:")
        print("  - bestMove: \(String(describing: bestMove))")
        print("  - moveType: \(String(describing: bestMove?.moveType))")
        print("  - position: \(String(describing: bestMove != nil ? "(\(bestMove!.row), \(bestMove!.col))" : "nil"))")
        
        // Verify expectations
        #expect(bestMove != nil, "AI should find a move")
        if let move = bestMove {
            #expect(move.row == 0, "Winning move should be in row 0")
            #expect(move.col == 4, "Winning move should be in column 4")
            #expect(move.moveType == .winning, "Move should be classified as winning")
        }
    }
    
    @Test func testMultipleAIBotInstances() async throws {
        print("🔄 Testing multiple AIBot instances...")
        
        // Same test data
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
        
        // Create multiple instances and test them
        for i in 1...3 {
            print("🤖 Testing AIBot instance #\(i)")
            let aiBot = AIBot(difficulty: .intermediate, personality: .balanced, playerSymbol: "X")
            
            let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
            print("  - Result #\(i): \(String(describing: bestMove))")
            
            #expect(bestMove != nil, "AI instance #\(i) should find a move")
            if let move = bestMove {
                #expect(move.row == 0, "Instance #\(i): Winning move should be in row 0")
                #expect(move.col == 4, "Instance #\(i): Winning move should be in column 4")
                #expect(move.moveType == .winning, "Instance #\(i): Move should be classified as winning")
            }
        }
    }
    
    @Test func testSearchAreaCalculation() async throws {
        print("📏 Testing search area calculation...")
        
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
        
        // Let's test the AI's behavior without accessing private methods
        print("🎯 Testing AI calculation with search area implications...")
        
        let bestMove = aiBot.calculateBestMove(for: gameState, timeLimit: 1.0)
        print("🎯 AI result: \(String(describing: bestMove))")
        
        #expect(bestMove != nil, "AI should find a move within search area")
    }
}
