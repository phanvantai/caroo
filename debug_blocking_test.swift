#!/usr/bin/env swift

// Debug script to test critical blocking functionality

import Foundation

// Mock the minimal structures we need for testing
struct MockThreatAnalysisResult {
    let position: (row: Int, col: Int)
    let player: String
    let threatLevel: Int  // Simplified: 4 = immediateWin, 3 = strong
    let priority: Double
    let canComplete: Bool
}

struct MockAIGameState {
    let grid: [String: String]
    let currentPlayer: String
    let opponentPlayer: String
    let totalMoves: Int
}

struct MockAIMove {
    let row: Int
    let col: Int
    let score: Double
    let moveType: String
}

// Simple test implementation
func findImmediateWins(in grid: [String: String], for player: String) -> [(row: Int, col: Int)] {
    var wins: [(row: Int, col: Int)] = []
    
    // Simple search around existing pieces
    for row in -5...5 {
        for col in -5...5 {
            let key = "\(row),\(col)"
            if grid[key] == nil {  // Empty position
                // Check if placing here would create 5 in a row
                if wouldCreateWin(at: row, col: col, in: grid, for: player) {
                    wins.append((row, col))
                }
            }
        }
    }
    
    return wins
}

func wouldCreateWin(at row: Int, col: Int, in grid: [String: String], for player: String) -> Bool {
    // Simulate placing the piece
    var testGrid = grid
    testGrid["\(row),\(col)"] = player
    
    // Check all directions for 5 in a row
    let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
    
    for direction in directions {
        var count = 1  // Count the placed piece
        
        // Check positive direction
        var r = row + direction.0
        var c = col + direction.1
        while testGrid["\(r),\(c)"] == player {
            count += 1
            r += direction.0
            c += direction.1
        }
        
        // Check negative direction
        r = row - direction.0
        c = col - direction.1
        while testGrid["\(r),\(c)"] == player {
            count += 1
            r -= direction.0
            c -= direction.1
        }
        
        if count >= 5 {
            return true
        }
    }
    
    return false
}

// Test the basic blocking scenario from our test
func testBasicBlocking() {
    print("🔍 Testing basic critical blocking scenario...")
    
    var grid: [String: String] = [:]
    grid["0,0"] = "O"
    grid["0,1"] = "O"
    grid["0,2"] = "O"
    grid["0,3"] = "O"
    // Position (0,4) should be blocked by X
    
    print("Grid state:")
    for col in 0...4 {
        let key = "0,\(col)"
        let value = grid[key] ?? "."
        print("[\(value)]", terminator: " ")
    }
    print()
    
    // Check if O can win at (0,4)
    let canOWin = wouldCreateWin(at: 0, col: 4, in: grid, for: "O")
    print("Can O win at (0,4)? \(canOWin)")
    
    // Find all winning moves for O
    let oWins = findImmediateWins(in: grid, for: "O")
    print("O's winning moves: \(oWins)")
    
    // This should be the position X needs to block
    if oWins.contains(where: { $0.row == 0 && $0.col == 4 }) {
        print("✅ Found critical threat that needs blocking at (0,4)")
    } else {
        print("❌ Critical threat not detected!")
    }
}

// Run the test
testBasicBlocking()
