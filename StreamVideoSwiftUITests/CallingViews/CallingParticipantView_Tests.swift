//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class CallingParticipantView_Tests: StreamVideoUITestCase, @unchecked Sendable {
    
    func test_callingParticipantView_snapshot() throws {
        let view = CallingParticipantView(
            viewFactory: DefaultViewFactory.shared,
            participant: UserFactory.get(2).last,
            caller: "caller.123"
        )
        AssertSnapshot(view, variants: snapshotVariants)
    }
}
