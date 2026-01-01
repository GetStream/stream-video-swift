//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class DefaultRetryStrategyTests: XCTestCase, @unchecked Sendable {
    private var subject: DefaultRetryStrategy! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - init

    func test_consecutiveFailures_isZeroInitially() {
        XCTAssertEqual(subject.consecutiveFailuresCount, 0)
    }

    // MARK: - incrementConsecutiveFailures

    func test_incrementConsecutiveFailures_makesDelaysLonger() {
        // Declare array for delays
        var delays: [TimeInterval] = []

        for _ in 0..<10 {
            // Ask for reconection delay
            delays.append(subject.nextRetryDelay())

            // Simulate failed retry
            subject.incrementConsecutiveFailures()
        }

        // Check the delays are increasing
        XCTAssert(delays.first! < delays.last!)
    }

    func test_incrementConsecutiveFailures_incrementsConsecutiveFailures() {
        // Cache current # of consecutive failures
        var prevValue = subject.consecutiveFailuresCount

        for _ in 0..<10 {
            // Simulate failed retry
            subject.incrementConsecutiveFailures()

            // Assert # of consecutive failures is incremented
            XCTAssertEqual(subject.consecutiveFailuresCount, prevValue + 1)

            // Update # of consecutive failures
            prevValue = subject.consecutiveFailuresCount
        }
    }

    func test_incrementConsecutiveFailures_concurrentAccess() async {
        let iterations = 100
        let expectation = XCTestExpectation(description: "Concurrent increment")
        expectation.expectedFulfillmentCount = iterations

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    self.subject.incrementConsecutiveFailures()
                    expectation.fulfill()
                }
            }
        }

        await fulfillment(of: [expectation], timeout: defaultTimeout)
        XCTAssertEqual(subject.consecutiveFailuresCount, iterations)
    }

    func test_incrementAndResetConsecutiveFailures_concurrentAccess() async {
        let iterations = 100
        let expectation = XCTestExpectation(description: "Concurrent increment and reset")
        expectation.expectedFulfillmentCount = iterations * 2

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    self.subject.incrementConsecutiveFailures()
                    expectation.fulfill()
                }
                group.addTask {
                    self.subject.resetConsecutiveFailures()
                    expectation.fulfill()
                }
            }
        }

        await fulfillment(of: [expectation], timeout: defaultTimeout)
        XCTAssert(subject.consecutiveFailuresCount >= 0)
    }

    // MARK: - resetConsecutiveFailures

    func test_resetConsecutiveFailures_setsConsecutiveFailuresToZero() {
        // Simulate some # of failed retries
        for _ in 0..<Int.random(in: 10..<20) {
            subject.incrementConsecutiveFailures()
        }

        // Call `resetConsecutiveFailures`
        subject.resetConsecutiveFailures()

        // Assert # of consecutive failures is set to zero
        XCTAssertEqual(subject.consecutiveFailuresCount, 0)
    }

    func test_resetConsecutiveFailures_concurrentAccess() async {
        (0..<10).forEach { _ in subject.incrementConsecutiveFailures() }

        let iterations = 10
        let expectation = XCTestExpectation(description: "Concurrent reset")
        expectation.expectedFulfillmentCount = iterations

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    self.subject.resetConsecutiveFailures()
                    expectation.fulfill()
                }
            }
        }

        await fulfillment(of: [expectation], timeout: defaultTimeout)
        XCTAssertEqual(subject.consecutiveFailuresCount, 0)
    }

    // MARK: - nextRetryDelay

    func test_nextRetryDelay_givenInitialCount_whenCalled_thenNoDelay() {
        let delay = subject.nextRetryDelay()

        XCTAssertEqual(delay, 0)
    }

    func test_nextRetryDelay_givenIncrementedCount_whenCalled_thenReturnsValidDelay() {
        for i in 1...5 {
            subject.incrementConsecutiveFailures()
            let delay = subject.nextRetryDelay()

            XCTAssertGreaterThanOrEqual(delay, 0.25)
            XCTAssertLessThanOrEqual(delay, min(0.5 + Double(i * 2), DefaultRetryStrategy.maximumReconnectionDelay))
        }
    }

    func test_nextRetryDelay_givenHighFailureCount_whenCalled_thenReturnsMaximumDelay() {
        for _ in 0..<20 {
            subject.incrementConsecutiveFailures()
        }

        let delay = subject.nextRetryDelay()

        XCTAssertLessThanOrEqual(delay, DefaultRetryStrategy.maximumReconnectionDelay)
    }
}
