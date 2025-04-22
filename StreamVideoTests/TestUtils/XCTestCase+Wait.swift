//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import XCTest

extension XCTestCase {

    func wait(for interval: TimeInterval) async {
        let waitExpectation = expectation(description: "Waiting for \(interval) seconds...")
        waitExpectation.isInverted = true
        await fulfillment(of: [waitExpectation], timeout: interval)
    }
}
