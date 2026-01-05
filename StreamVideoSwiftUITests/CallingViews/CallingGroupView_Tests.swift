//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class CallingGroupView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    func test_callingGroupView_isCalling_snapshot() throws {
        for count in spotlightParticipants {
            let users = UserFactory.get(count)
            let view = CallingGroupView(
                viewFactory: DefaultViewFactory.shared,
                participants: users,
                isCalling: true
            )
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
            let view = CallingGroupView(
                viewFactory: DefaultViewFactory.shared,
                participants: users,
                isCalling: true
            )
            AssertSnapshot(
                view,
                variants: snapshotVariants,
                suffix: "with_\(count)_participants"
            )
        }
    }
}
