#!/usr/bin/env swift

// Simple debug test to check AI functionality
import Foundation

// Simplified versions for testing
struct SimpleAIMove {
    let row: Int
    let col: Int
    let score: Double
    let moveType: String
}

struct SimpleGameState {
    let grid: [String: String]
    let currentPlayer: String
    let opponentPlayer: String
}

// Test the basic win detection logic
func testWinDetection() {
    print("🧪 Testing basic win detection logic...")
    
    // Test horizontal win detection
    var grid: [String: String] = [:]
    grid["0,0"] = "X"
    grid["0,1"] = "X"
    grid["0,2"] = "X"
    grid["0,3"] = "X"
    
    print("Grid setup: \(grid)")
    print("Testing if position (0,4) would create a win...")
    
    // Simulate placing X at (0,4)
    var testGrid = grid
    testGrid["0,4"] = "X"
    
    print("Test grid with X at (0,4): \(testGrid)")
    
    // Check for 5 in a row horizontally
    let count = checkHorizontalLine(grid: testGrid, player: "X", startRow: 0, startCol: 0)
    print("Consecutive count starting from (0,0): \(count)")
    
    if count >= 5 {
        print("✅ Win detected correctly!")
    } else {
        print("❌ Win detection failed!")
    }
}

func checkHorizontalLine(grid: [String: String], player: String, startRow: Int, startCol: Int) -> Int {
    var count = 0
    var col = startCol
    
    while grid["\(startRow),\(col)"] == player {
        count += 1
        col += 1
        if count > 10 { break } // Safety check
    }
    
    return count
}

// Run the test
testWinDetection()
