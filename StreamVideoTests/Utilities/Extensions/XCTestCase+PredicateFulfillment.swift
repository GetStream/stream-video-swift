//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

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
