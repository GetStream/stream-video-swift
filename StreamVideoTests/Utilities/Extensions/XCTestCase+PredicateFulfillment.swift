//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import XCTest

#if compiler(>=6.0)
extension XCTestCase: @retroactive @unchecked Sendable {}
#else
extension XCTestCase: @unchecked Sendable {}
#endif

extension XCTestCase {

    @MainActor
    func fulfilmentInMainActor(
        timeout: TimeInterval = defaultTimeout,
        _ message: @MainActor @autoclosure () -> String = "",
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

    func fulfillment(
        timeout: TimeInterval = defaultTimeout,
        _ message: @Sendable @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line,
        block: @Sendable @escaping () -> Bool
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

    func fulfillment(
        timeout: TimeInterval = defaultTimeout,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line,
        block: @Sendable @escaping () async -> Bool
    ) async {
        final class Store: @unchecked Sendable {
            nonisolated(unsafe) var iterations = 0
            nonisolated(unsafe) var cancellable: AnyCancellable?
            init() {}
        }
        let stepInterval = 0.1
        let maxIterations = Int(timeout / stepInterval)
        let waitExpectation = expectation(description: "Wait for completion.")
        let store = Store()
        store.cancellable = Foundation
            .Timer
            .publish(every: stepInterval, on: .main, in: .default)
            .autoconnect()
            .sink { _ in
                Task {
                    defer { store.iterations += 1 }
                    guard await block() || store.iterations > maxIterations else {
                        return
                    }
                    store.cancellable?.cancel()
                    waitExpectation.fulfill()
                }
            }

        await safeFulfillment(
            of: [waitExpectation],
            timeout: timeout,
            file: file,
            line: line
        )
        store.cancellable?.cancel()
        let value = await block()
        XCTAssertTrue(value, message(), file: file, line: line)
    }

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
