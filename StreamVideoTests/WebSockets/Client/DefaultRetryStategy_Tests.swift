//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class DefaultRetryStrategyTests: XCTestCase {

    private var subject: DefaultRetryStrategy! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - incrementConsecutiveFailures

    func test_incrementConsecutiveFailures_givenInitialCount_whenIncremented_thenCountIncreases() {
        XCTAssertEqual(subject.consecutiveFailuresCount, 0)

        subject.incrementConsecutiveFailures()

        XCTAssertEqual(subject.consecutiveFailuresCount, 1)
    }

    // MARK: - resetConsecutiveFailures

    func test_resetConsecutiveFailures_givenNonZeroCount_whenReset_thenCountResetsToZero() {
        subject.incrementConsecutiveFailures()
        XCTAssertEqual(subject.consecutiveFailuresCount, 1)

        subject.resetConsecutiveFailures()

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
