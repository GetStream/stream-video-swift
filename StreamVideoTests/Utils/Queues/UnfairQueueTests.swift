//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class UnfairQueueTests: XCTestCase {

    private lazy var taskWaitIntervalRange: ClosedRange<TimeInterval>! = 0.2...0.5
    private lazy var subject: UnfairQueue! = .init()

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        taskWaitIntervalRange = nil
        super.tearDown()
    }

    // MARK: - sync(_:)

    func test_sync_exclusiveAccess() async {
        var sharedResource = 0
        let iterations = 10
        let expectation = XCTestExpectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = iterations

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    await self.wait(for: Double.random(in: self.taskWaitIntervalRange))
                    self.subject.sync {
                        let currentValue = sharedResource
                        sharedResource = currentValue + 1
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
