//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

final class CallingGroupView_Tests: StreamVideoUITestCase {
    
    func test_callingGroupView_isCalling_snapshot() throws {
        for count in spotlightParticipants {
            let users = UserFactory.get(count)
            let view = CallingGroupView(participants: users, isCalling: true)
            AssertSnapshot(
                view,
                variants: snapshotVariants,
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
                variants: snapshotVariants,
                suffix: "with_\(count)_participants"
            )
        }
    }
}
