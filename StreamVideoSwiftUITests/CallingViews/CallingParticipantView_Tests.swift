//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class CallingParticipantView_Tests: StreamVideoUITestCase {
    
    func test_callingParticipantView_snapshot() throws {
        let view = CallingParticipantView(participant: UserFactory.get(2).last, caller: "caller.123")
        AssertSnapshot(view, variants: snapshotVariants)
    }
}
