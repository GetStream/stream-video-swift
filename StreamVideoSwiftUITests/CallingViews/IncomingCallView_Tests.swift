//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class IncomingCallView_Tests: StreamVideoUITestCase, @unchecked Sendable {
    
    func test_incomingCallView_snapshot() throws {
        for count in spotlightParticipants {
            let members = UserFactory.get(count)
            let callInfo = IncomingCall(
                id: callCid,
                caller: members.first!.user,
                type: callType,
                members: members,
                timeout: 15000,
                video: false
            )
            let view = IncomingCallView(
                callInfo: callInfo,
                onCallAccepted: { _ in },
                onCallRejected: { _ in }
            )
            AssertSnapshot(view, variants: snapshotVariants, suffix: "with_\(count)_participants")
        }
    }
}
