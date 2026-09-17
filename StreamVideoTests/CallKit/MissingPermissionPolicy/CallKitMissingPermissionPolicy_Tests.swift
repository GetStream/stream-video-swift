//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class CallKitMissingPermissionPolicy_Tests: LogTestCase, @unchecked Sendable {

    func test_returnsExpectedPolicies() {
        XCTAssertNotNil(CallKitMissingPermissionPolicy.none.policy as? CallKitMissingPermissionPolicy.NoOp)
        XCTAssertNotNil(CallKitMissingPermissionPolicy.endCall.policy as? CallKitMissingPermissionPolicy.EndCall)
    }
}
