//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {

    func fulfillment(
        timeout: TimeInterval = .infinity,
        enforceOrder: Bool = false,
        block: @escaping () -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let predicate = NSPredicate { _, _ in block() }
        let waitExpectation = XCTNSPredicateExpectation(
            predicate: predicate,
            object: nil
        )

        await safeFulfillment(
            of: [waitExpectation],
            timeout: timeout,
            enforceOrder: enforceOrder,
            file: file,
            line: line
        )
    }

    func safeFulfillment(
        of expectations: [XCTestExpectation],
        timeout seconds: TimeInterval = .infinity,
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
