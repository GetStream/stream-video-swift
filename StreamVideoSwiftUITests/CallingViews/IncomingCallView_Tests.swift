//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import StreamSwiftTestHelpers
import SnapshotTesting
import XCTest

@MainActor
final class IncomingCallView_Tests: StreamVideoUITestCase {
    
    func test_incomingCallView_snapshot() throws {
        for count in spotlightParticipants {
            let members = UserFactory.get(count)
            let callInfo = IncomingCall(
                id: callCid,
                caller: members.first!.user,
                type: callType,
                members: members,
                timeout: 15000
            )
            let view = IncomingCallView(
                callInfo: callInfo,
                onCallAccepted: {_ in },
                onCallRejected: {_ in }
            )
            AssertSnapshot(view, variants: snapshotVariants, suffix: "with_\(count)_participants")
        }
    }
}
