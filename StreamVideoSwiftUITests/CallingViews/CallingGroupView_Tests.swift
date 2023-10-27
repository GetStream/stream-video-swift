//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
@testable import StreamVideoSwiftUI
@testable import StreamVideo
import StreamSwiftTestHelpers
import XCTest

@MainActor
final class CallingGroupView_Tests: StreamVideoUITestCase {
    
    func test_callingGroupView_isCalling_snapshot() throws {
        for count in spotlightParticipants {
            let users = UserFactory.get(count)
            let view = CallingGroupView(participants: users, isCalling: true)
            AssertSnapshot(
                view,
                suffix: "with_\(count)_participants"
            )
        }
    }
    
    func test_callingGroupView_isNotCalling_snapshot() throws {
        for count in spotlightParticipants {
            let users = UserFactory.get(count)
            let view = CallingGroupView(participants: users, isCalling: true)
            AssertSnapshot(
                view,
                suffix: "with_\(count)_participants"
            )
        }
    }
}
