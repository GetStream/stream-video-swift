//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoUIKit
import XCTest

final class CallViewController_Tests: StreamVideoUITestCase, @unchecked Sendable {

    @MainActor
    func test_callViewController_outgoingSnapshot() {
        // Given
        let callViewController = CallViewController.make()
        let participants = [
            Member(userId: "Test1"),
            Member(userId: "Test2")
        ]
        
        // When
        callViewController.startCall(callType: "default", callId: "1234", members: participants, ring: true)
        
        // Then
        AssertSnapshot(callViewController.view, variants: snapshotVariants)
    }
}
