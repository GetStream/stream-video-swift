//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import XCTest

final class OperationQueue_Tests: XCTestCase, @unchecked Sendable {

    private var subject: OperationQueue! = .init()
    private var counter = 0
    private var order: [Int] = []

    override func setUp() {
        super.setUp()
        subject.maxConcurrentOperationCount = 1
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - addTaskOperation

    func test_addTaskOperation_whenCalledConcurrently_tasksCompleteSerially() async throws {
        let iterations = 10

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            self.subject.addTaskOperation {
                self.counter += 1
            }
        }

        await fulfillment(timeout: defaultTimeout) { self.counter == iterations }
        XCTAssertEqual(counter, iterations)
    }

    // MARK: - sync

    func test_addSynchronousTaskOperation_givenValidTask_whenExecuted_thenReturnsResult() async throws {
        let result = try await subject.addSynchronousTaskOperation {
            "success"
        }
        XCTAssertEqual(result, "success")
    }

    func test_addSynchronousTaskOperation_givenThrowingTask_whenExecuted_thenThrowsError() async {
        enum TestError: Error { case failure }

        let error = await XCTAssertThrowsErrorAsync {
            _ = try await subject.addSynchronousTaskOperation {
                throw TestError.failure
            }
        }
        XCTAssertTrue(error is TestError)
    }

    func test_addSynchronousTaskOperation_givenConcurrentTasks_whenLimited_thenRunsSerially() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.subject.addSynchronousTaskOperation {
                    await self.wait(for: 0.2)
                    self.order.append(1)
                }
            }

            group.addTask {
                await self.wait(for: 0.1)
                try await self.subject.addSynchronousTaskOperation {
                    self.order.append(2)
                }
            }

            try await group.waitForAll()
        }

        XCTAssertEqual(order, [1, 2])
    }

    // MARK: - cancelAll

    func test_cancelAll_cancelsAllInFlightTasks() async throws {
        subject.addTaskOperation {
            await self.wait(for: 0.5)
            try Task.checkCancellation()
            self.counter = -1
        }

        await wait(for: 0.1)
        subject.cancelAllOperations()

        await wait(for: 1)
        XCTAssertEqual(counter, 0)
    }
}
