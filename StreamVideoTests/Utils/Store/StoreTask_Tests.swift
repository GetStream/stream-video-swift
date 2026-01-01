//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

/// Tests focused on StoreTask behavior and integration with Store.
final class StoreTask_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - Subject

    private lazy var subject: Store<TaskTestNamespace>! = TaskTestNamespace.store(
        initialState: .initial
    )

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - Completion

    func test_result_successfulAction_completesWithoutError() async throws {
        // When
        let task = subject.dispatch(.increment)

        // Then
        try await task.result()
        XCTAssertEqual(subject.state.counter, 1)
    }

    func test_result_failingReducer_throwsError() async {
        // When
        let task = subject.dispatch(.fail)

        // Then
        do {
            try await task.result()
            XCTFail("Expected error, but succeeded")
        } catch TaskTestError.expectedFailure {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        // State should remain unchanged on failure
        XCTAssertEqual(subject.state.counter, 0)
    }

    // MARK: - Fire-and-forget

    func test_fireAndForget_withoutAwait_stillProcessesAction() async {
        // When
        subject.dispatch(.setValue(42))

        // Then
        await fulfillment(timeout: 2) {
            self.subject.state.value == 42
        }
    }

    // MARK: - Multiple awaiters

    func test_multipleAwaiters_onSameTask_allComplete() async {
        // Given
        let task = subject.dispatch(.setValue(7))

        // When
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    do { try await task.result() } catch { XCTFail("Unexpected error: \(error)") }
                }
            }
        }

        // Then
        XCTAssertEqual(subject.state.value, 7)
    }

    // MARK: - Delays

    func test_delayBefore_dispatch_delaysProcessingUntilElapsed() async throws {
        // Given
        let before: TimeInterval = 0.2

        // When
        _ = subject.dispatch(TaskTestNamespace.Action.setValue(9).withBeforeDelay(before))

        // Then: Before delay elapses, value should not be updated
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        XCTAssertNotEqual(subject.state.value, 9)

        // After delay, value should be applied
        await fulfillment(timeout: 2) {
            self.subject.state.value == 9
        }
    }
}

// MARK: - Private Types

private enum TaskTestNamespace: StoreNamespace {
    typealias State = TaskTestState
    typealias Action = TaskTestAction

    static let identifier = "storetask.tests.namespace"

    static func reducers() -> [Reducer<Self>] { [TaskTestReducer()] }
}

private struct TaskTestState: Equatable {
    var counter: Int = 0
    var value: Int = 0

    static let initial = TaskTestState()
}

private enum TaskTestAction: Sendable, StoreActionBoxProtocol {
    case increment
    case setValue(Int)
    case fail
}

private enum TaskTestError: Error, Equatable {
    case expectedFailure
}

private final class TaskTestReducer: Reducer<TaskTestNamespace>, @unchecked Sendable {
    override func reduce(
        state: TaskTestState,
        action: TaskTestAction,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) async throws -> TaskTestState {
        var newState = state

        switch action {
        case .increment:
            newState.counter += 1

        case let .setValue(value):
            newState.value = value

        case .fail:
            throw TaskTestError.expectedFailure
        }

        return newState
    }
}
