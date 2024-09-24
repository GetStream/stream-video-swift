//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import XCTest

extension XCTestCase {

    @MainActor
    func fulfillment(
        timeout: TimeInterval = defaultTimeout,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line,
        block: @MainActor @Sendable @escaping () -> Bool
    ) async {
        let predicate = NSPredicate { _, _ in block() }
        let waitExpectation = XCTNSPredicateExpectation(
            predicate: predicate,
            object: nil
        )

        await safeFulfillment(
            of: [waitExpectation],
            timeout: timeout,
            file: file,
            line: line
        )

        XCTAssertTrue(block(), message(), file: file, line: line)
    }

    @MainActor
    func fulfillment(
        timeout: TimeInterval = defaultTimeout,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line,
        block: @MainActor @Sendable @escaping () async -> Bool
    ) async {
        let stepInterval: TimeInterval = 1
        var maxIterations = Int(timeout / stepInterval)
        var iterations = 0
        var cancellable: AnyCancellable?
        let waitExpectation = expectation(description: "Wait for completion.")
        var executionTask: Task<Void, Never>?
        cancellable = Foundation
            .Timer
            .publish(every: stepInterval, on: .main, in: .default)
            .autoconnect()
            .sink { _ in
                executionTask?.cancel()
                executionTask = Task {
                    defer { iterations += 1 }
                    guard await block() || iterations > maxIterations else {
                        return
                    }
                    cancellable?.cancel()
                    waitExpectation.fulfill()
                }
            }

        await safeFulfillment(
            of: [waitExpectation],
            timeout: timeout,
            file: file,
            line: line
        )
        executionTask?.cancel()
        let value = await block()
        XCTAssertTrue(value, message(), file: file, line: line)
    }

    @MainActor
    func safeFulfillment(
        of expectations: [XCTestExpectation],
        timeout seconds: TimeInterval = defaultTimeout,
        enforceOrder: Bool = false,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        #if compiler(>=5.8)
        await fulfillment(of: expectations, timeout: seconds, enforceOrder: enforceOrder)
        #else
        await waitForExpectations(timeout: seconds)
        #endif
    }
}
