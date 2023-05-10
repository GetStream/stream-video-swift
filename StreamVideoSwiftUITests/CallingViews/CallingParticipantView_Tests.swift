//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import SnapshotTesting
import XCTest

@MainActor
final class CallingParticipantView_Tests: StreamVideoUITestCase {
    
    func test_callingParticipantView_snapshot() throws {
        let view = CallingParticipantView(participant: UserFactory.get(2).last, caller: "caller.123")
        AssertSnapshot(view)
    }
}
