//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class CallKitMissingPermissionPolicy_Tests: XCTestCase, @unchecked Sendable {

    func test_returnsExpectedPolicies() {
        XCTAssertNotNil(CallKitMissingPermissionPolicy.none.policy as? CallKitMissingPermissionPolicy.NoOp)
        XCTAssertNotNil(CallKitMissingPermissionPolicy.endCall.policy as? CallKitMissingPermissionPolicy.EndCall)
    }
}
