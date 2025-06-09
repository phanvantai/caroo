import Testing
@testable import Caroo

struct BasicBlockingDebugTest {
    
    @Test func debugBasicThreatDetection() async throws {
        // Create the exact scenario from our failing test
        var grid: [String: String] = [:]
        grid["0,0"] = "O"
        grid["0,1"] = "O"  
        grid["0,2"] = "O"
        grid["0,3"] = "O"
        // Position (0,4) should be blocked by X
        
        print("🔍 DEBUG: Testing basic threat detection")
        print("Grid state: O-O-O-O-?")
        
        // Test if O can win at (0,4)
        let canOWin = ThreatAnalyzer.wouldCreateImmediateWin(at: 0, col: 4, in: grid, for: "O")
        print("Can O win at (0,4)? \(canOWin)")
        #expect(canOWin == true, "O should be able to win at (0,4)")
        
        // Test finding immediate wins for O
        let oWins = ThreatAnalyzer.findImmediateWins(in: grid, for: "O")
        print("O's winning moves: \(oWins)")
        #expect(oWins.count > 0, "Should find O's winning moves")
        #expect(oWins.contains { $0.row == 0 && $0.col == 4 }, "Should find winning move at (0,4)")
        
        // Test critical threat detection
        let threats = ThreatAnalyzer.findCriticalThreats(in: grid, for: "O")
        print("Critical threats found: \(threats.count)")
        for threat in threats {
            print("  Threat at (\(threat.position.row),\(threat.position.col)) - Level: \(threat.threatLevel) - Priority: \(threat.priority)")
        }
        
        // Test blocking move detection
        let blockingMoves = ThreatAnalyzer.findAllCriticalBlockingMoves(in: grid, against: "O")
        print("Blocking moves found: \(blockingMoves.count)")
        for move in blockingMoves {
            print("  Block at (\(move.position.row),\(move.position.col)) - Priority: \(move.priority)")
        }
        
        #expect(blockingMoves.count > 0, "Should find blocking moves")
        
        let bestBlock = ThreatAnalyzer.getBestCriticalBlockingMove(in: grid, against: "O", currentPlayer: "X")
        if let bestBlock = bestBlock {
            print("Best blocking move: (\(bestBlock.position.row),\(bestBlock.position.col)) - Priority: \(bestBlock.priority)")
            #expect(bestBlock.position.row == 0, "Best block should be at row 0")
            #expect(bestBlock.position.col == 4, "Best block should be at col 4")
        } else {
            print("❌ No best blocking move found!")
            #expect(bestBlock != nil, "Should find a best blocking move")
        }
    }
}
