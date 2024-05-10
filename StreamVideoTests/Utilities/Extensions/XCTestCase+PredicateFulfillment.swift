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

        await fulfillment(
            of: [waitExpectation],
            timeout: timeout,
            enforceOrder: enforceOrder
        )
    }
}
