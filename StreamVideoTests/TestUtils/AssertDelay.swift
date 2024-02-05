//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

@MainActor
func XCTAssertWithDelay(
    _ expression: @autoclosure () throws -> Bool,
    _ message: @autoclosure () -> String = "",
    nanoseconds: UInt64 = 500_000_000,
    file: StaticString = #file,
    line: UInt = #line
) async throws {
    try await Task.sleep(nanoseconds: nanoseconds)
    XCTAssert(try expression(), message(), file: file, line: line)
}

extension XCTestCase {
    /// An assertion that will keep checking the provided closure for a true result until the timeout ends.
    /// - Note: If the closure's result becomes `true` early then the execution won't keep running untill
    /// the timeout.
    @MainActor
    func XCTAssertContinuously(
        _ expression: @escaping () throws -> Bool,
        _ message: @escaping () -> String = { "" },
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(block: { _, _ in
                (try? expression()) ?? false
            }), object: message()
        )

        await fulfillment(
            of: [expectation],
            timeout: timeout
        )
    }
}
