//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class RecursiveQueueTests: XCTestCase, @unchecked Sendable {

    private lazy var taskWaitIntervalRange: ClosedRange<TimeInterval>! = 0.2...0.5
    private lazy var subject: RecursiveQueue! = .init()
    private var sharedResource: Int! = 0

    // MARK: - Lifecycle

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

    // MARK: - Recursive Lock Testing

    func test_sync_recursiveAccess() async {
        let recursionDepth = 5
        let expectation = XCTestExpectation(description: "Recursive access")
        expectation.expectedFulfillmentCount = recursionDepth

        func recursiveIncrement(depth: Int) {
            guard depth > 0 else { return }
            subject.sync {
                self.sharedResource += 1
                expectation.fulfill()
                recursiveIncrement(depth: depth - 1)
            }
        }

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.wait(for: Double.random(in: self.taskWaitIntervalRange))
                recursiveIncrement(depth: recursionDepth)
            }
        }

        await fulfillment(
            of: [expectation],
            timeout: TimeInterval(recursionDepth) * taskWaitIntervalRange.upperBound
        )
        XCTAssertEqual(sharedResource, recursionDepth)
    }
}
