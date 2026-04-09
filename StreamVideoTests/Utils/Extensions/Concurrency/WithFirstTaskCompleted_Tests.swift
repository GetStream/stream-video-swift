//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class WithFirstTaskCompleted_Tests: XCTestCase, @unchecked Sendable {

    private enum TestError: Error, Equatable {
        case expected
    }

    func test_withFirstTaskCompleted_returnsFirstSuccess_whenFirstCompletesFirst() async throws {
        let result = await withFirstTaskCompleted(
            {
                try await Task.sleep(nanoseconds: 10_000_000)
                return 1
            },
            {
                try await Task.sleep(nanoseconds: 100_000_000)
                return "second"
            }
        )

        switch result {
        case let .first(.success(value)):
            XCTAssertEqual(value, 1)
        default:
            XCTFail("Expected first task to complete successfully first.")
        }
    }

    func test_withFirstTaskCompleted_returnsSecondSuccess_whenSecondCompletesFirst() async throws {
        let result = await withFirstTaskCompleted(
            {
                try await Task.sleep(nanoseconds: 100_000_000)
                return 1
            },
            {
                try await Task.sleep(nanoseconds: 10_000_000)
                return "second"
            }
        )

        switch result {
        case let .second(.success(value)):
            XCTAssertEqual(value, "second")
        default:
            XCTFail("Expected second task to complete successfully first.")
        }
    }

    func test_withFirstTaskCompleted_returnsFirstFailure_whenFirstThrowsFirst() async {
        let result = await withFirstTaskCompleted(
            { () async throws -> Int in
                throw TestError.expected
            },
            {
                try await Task.sleep(nanoseconds: 100_000_000)
                return "second"
            }
        )

        switch result {
        case let .first(.failure(error)):
            XCTAssertEqual(error as? TestError, .expected)
        default:
            XCTFail("Expected first task failure to win the race.")
        }
    }

    func test_withFirstTaskCompleted_returnsSecondFailure_whenSecondThrowsFirst() async {
        let result = await withFirstTaskCompleted(
            {
                try await Task.sleep(nanoseconds: 100_000_000)
                return 1
            },
            { () async throws -> String in
                throw TestError.expected
            }
        )

        switch result {
        case let .second(.failure(error)):
            XCTAssertEqual(error as? TestError, .expected)
        default:
            XCTFail("Expected second task failure to win the race.")
        }
    }

    func test_withFirstTaskCompleted_cancelsSecondTask_whenFirstCompletesFirst() async {
        let secondTaskStarted = expectation(description: "Second task started.")
        let cancellationObserved = expectation(description: "Second task observed cancellation.")
        let didStartSecondTask = Atomic(wrappedValue: false)

        _ = await withFirstTaskCompleted(
            {
                while !didStartSecondTask.wrappedValue {
                    await Task.yield()
                }
                return 1
            },
            {
                didStartSecondTask.wrappedValue = true
                secondTaskStarted.fulfill()
                do {
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                    return "second"
                } catch is CancellationError {
                    cancellationObserved.fulfill()
                    throw CancellationError()
                }
            }
        )

        await fulfillment(
            of: [secondTaskStarted, cancellationObserved],
            timeout: defaultTimeout
        )
    }

    func test_withFirstTaskCompleted_cancelsFirstTask_whenSecondCompletesFirst() async {
        let firstTaskStarted = expectation(description: "First task started.")
        let cancellationObserved = expectation(description: "First task observed cancellation.")
        let didStartFirstTask = Atomic(wrappedValue: false)

        _ = await withFirstTaskCompleted(
            {
                didStartFirstTask.wrappedValue = true
                firstTaskStarted.fulfill()
                do {
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                    return 1
                } catch is CancellationError {
                    cancellationObserved.fulfill()
                    throw CancellationError()
                }
            },
            {
                while !didStartFirstTask.wrappedValue {
                    await Task.yield()
                }
                return "second"
            }
        )

        await fulfillment(
            of: [firstTaskStarted, cancellationObserved],
            timeout: defaultTimeout
        )
    }

    func test_withFirstTaskCompleted_returnsCancelled_whenParentTaskIsCancelled() async throws {
        let firstTaskStarted = expectation(description: "First task started.")
        let secondTaskStarted = expectation(description: "Second task started.")
        let firstCancellationObserved = expectation(description: "First task observed cancellation.")
        let secondCancellationObserved = expectation(description: "Second task observed cancellation.")

        let task = Task {
            await withFirstTaskCompleted(
                {
                    firstTaskStarted.fulfill()
                    do {
                        try await Task.sleep(nanoseconds: 5_000_000_000)
                        return 1
                    } catch is CancellationError {
                        firstCancellationObserved.fulfill()
                        throw CancellationError()
                    }
                },
                {
                    secondTaskStarted.fulfill()
                    do {
                        try await Task.sleep(nanoseconds: 5_000_000_000)
                        return "second"
                    } catch is CancellationError {
                        secondCancellationObserved.fulfill()
                        throw CancellationError()
                    }
                }
            )
        }

        await fulfillment(
            of: [firstTaskStarted, secondTaskStarted],
            timeout: defaultTimeout
        )
        task.cancel()

        let result = await task.value

        switch result {
        case .cancelled:
            break
        default:
            XCTFail("Expected cancelled result when parent task is cancelled.")
        }

        await fulfillment(
            of: [firstCancellationObserved, secondCancellationObserved],
            timeout: defaultTimeout
        )
    }

    func test_withFirstTaskCompleted_returnsWithoutWaitingForNonCooperativeLoser() async {
        let blockerEntered = expectation(description: "Non-cooperative task entered.")
        let blockerCompleted = expectation(description: "Non-cooperative task completed.")
        let blocker = NonCooperativeTaskBlocker {
            blockerEntered.fulfill()
        } onResume: {
            blockerCompleted.fulfill()
        }
        let start = Date()

        let result = await withFirstTaskCompleted(
            {
                while !blocker.didEnter {
                    await Task.yield()
                }
                return 1
            },
            {
                await blocker.wait()
                return "second"
            }
        )

        XCTAssertLessThan(Date().timeIntervalSince(start), 1)
        switch result {
        case let .first(.success(value)):
            XCTAssertEqual(value, 1)
        default:
            XCTFail("Expected first task to finish without waiting for the blocked loser.")
        }

        await fulfillment(of: [blockerEntered], timeout: defaultTimeout)
        blocker.resume()
        await fulfillment(of: [blockerCompleted], timeout: defaultTimeout)
    }
}

private final class NonCooperativeTaskBlocker: @unchecked Sendable {
    private let onEnter: @Sendable () -> Void
    private let onResume: @Sendable () -> Void
    @Atomic private var didEnterStorage = false
    @Atomic private var continuation: CheckedContinuation<Void, Never>?

    var didEnter: Bool {
        didEnterStorage
    }

    init(
        onEnter: @escaping @Sendable () -> Void = {},
        onResume: @escaping @Sendable () -> Void = {}
    ) {
        self.onEnter = onEnter
        self.onResume = onResume
    }

    func wait() async {
        didEnterStorage = true
        onEnter()
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
        onResume()
    }

    func resume() {
        continuation?.resume()
        continuation = nil
    }
}
