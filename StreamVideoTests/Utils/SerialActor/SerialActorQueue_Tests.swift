//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import XCTest

final class SerialActorQueue_Tests: XCTestCase, @unchecked Sendable {

    private var subject: SerialActorQueue! = .init()
    private var counter = 0

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - async

    func test_async_whenCalledConcurrently_tasksCompleteSerially() async throws {
        let iterations = 10

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            self.subject.async {
                self.counter += 1
            }
        }

        await fulfillment(timeout: defaultTimeout) { self.counter == iterations }
        XCTAssertEqual(counter, iterations)
    }

    // MARK: - cancelAll

    func test_cancelAll_cancelsAllInFlightTasks() async throws {
        subject.async {
            await self.wait(for: 0.5)
            try Task.checkCancellation()
            self.counter = -1
        }

        await wait(for: 0.1)
        subject.cancelAll()

        await wait(for: 1)
        XCTAssertEqual(counter, 0)
    }
}
