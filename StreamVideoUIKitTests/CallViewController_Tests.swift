//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@testable import StreamVideoUIKit
import StreamSwiftTestHelpers
import SnapshotTesting
import XCTest

final class CallViewController_Tests: StreamVideoUITestCase {

    func test_callViewController_outgoingSnapshot() {
        // Given
        let callViewController = CallViewController.make()
        let participants = [
            MemberRequest(userId: "Test1"),
            MemberRequest(userId: "Test2")
        ]
        
        // When
        callViewController.startCall(callType: "default", callId: "1234", members: participants, ring: true)
        
        // Then
        AssertSnapshot(callViewController.view, variants: snapshotVariants)
    }

}
