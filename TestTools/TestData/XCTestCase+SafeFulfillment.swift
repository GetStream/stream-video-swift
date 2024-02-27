//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest

extension XCTestCase {
    
    func safeFulfillment(
        of expectations: [XCTestExpectation],
        timeout seconds: TimeInterval = .infinity
    ) async {
        #if compiler(>=5.8)
        await fulfillment(of: expectations, timeout: seconds)
        #else
        await waitForExpectations(timeout: seconds)
        #endif
    }
}
