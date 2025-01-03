//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class SerialActor_Tests: XCTestCase {
    
    func testSerialExecution() async throws {
        let actor = SerialActor()
        
        let start1 = Date()
        try await actor.execute { try await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC) } // Simulate a 2-second task
        let end1 = Date()
        
        try await actor.execute { try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC) }
        let end2 = Date()
        
        XCTAssertGreaterThanOrEqual(end1.timeIntervalSince(start1), 2.0)
        XCTAssertGreaterThanOrEqual(end2.timeIntervalSince(end1), 1.0)
        XCTAssertGreaterThanOrEqual(end2.timeIntervalSince(start1), 3.0) // Total time should be at least 3 seconds
    }
}
