//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class UnfairQueueTests: LogTestCase, @unchecked Sendable {

    private var taskWaitIntervalRange: ClosedRange<TimeInterval>! = 0.2...0.5
    private var subject: UnfairQueue!
    private var sharedResource: Int! = 0

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        // Create the lock before concurrent tasks. `lazy` init is not
        // thread-safe, so racing first access can mint two queues and
        // lose increments.
        subject = .init()
        sharedResource = 0
    }

    override func tearDown() {
        subject = nil
        taskWaitIntervalRange = nil
        sharedResource = nil
        super.tearDown()
    }

    // MARK: - sync(_:)

    func test_sync_exclusiveAccess() async {
        let iterations = 10
        let expectation = XCTestExpectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = iterations

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    await self.wait(for: Double.random(in: self.taskWaitIntervalRange))
                    self.subject.sync {
                        let currentValue = self.sharedResource!
                        self.sharedResource = currentValue + 1
                    }
                    expectation.fulfill()
                }
            }
        }

        await fulfillment(
            of: [expectation],
            timeout: TimeInterval(iterations) * taskWaitIntervalRange.upperBound
        )
        XCTAssertEqual(sharedResource, iterations)
    }
}
