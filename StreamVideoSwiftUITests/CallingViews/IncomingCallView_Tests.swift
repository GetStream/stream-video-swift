//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import SnapshotTesting
import XCTest

@MainActor
final class IncomingCallView_Tests: StreamVideoUITestCase {
    
    func test_incomingCallView_snapshot() throws {
        for count in spotlightParticipants {
            let users = UserFactory.get(count)
            let callInfo = IncomingCall(
                id: callCid,
                caller: users.first!.user,
                type: callType,
                participants: users,
                timeout: 15000
            )
            let view = IncomingCallView(
                callInfo: callInfo,
                onCallAccepted: {_ in },
                onCallRejected: {_ in }
            )
            AssertSnapshot(view, suffix: "with_\(count)_participants")
        }
    }
}
