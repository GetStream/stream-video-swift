//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class WithConcurrentChildrenTask_Tests: XCTestCase, @unchecked Sendable {

    private enum TestError: Error, Equatable {
        case expected
    }

    func test_withConcurrentChildrenTask_returnsResultsInOriginalOrder_whenSecondCompletesFirst() async throws {
        let result = try await withConcurrentChildrenTask(
            {
                try await Task.sleep(nanoseconds: 100_000_000)
                return 1
            },
            {
                try await Task.sleep(nanoseconds: 10_000_000)
                return "second"
            }
        )

        XCTAssertEqual(result.0, 1)
        XCTAssertEqual(result.1, "second")
    }

    func test_withConcurrentChildrenTask_rethrowsTheThrownError() async {
        let error = await XCTAssertThrowsErrorAsync {
            _ = try await withConcurrentChildrenTask(
                { throw TestError.expected },
                { "second" }
            ) as (Int, String)
        }

        XCTAssertEqual(error as? TestError, .expected)
    }

    func test_withConcurrentChildrenTask_cancelsSiblingTask_whenOneTaskThrows() async {
        let cancellationObserved = Atomic(wrappedValue: false)

        _ = await XCTAssertThrowsErrorAsync {
            _ = try await withConcurrentChildrenTask(
                { throw TestError.expected },
                {
                    do {
                        try await Task.sleep(nanoseconds: 5_000_000_000)
                        return "second"
                    } catch is CancellationError {
                        cancellationObserved.wrappedValue = true
                        throw CancellationError()
                    }
                }
            ) as (Int, String)
        }

        XCTAssertTrue(cancellationObserved.wrappedValue)
    }
}
