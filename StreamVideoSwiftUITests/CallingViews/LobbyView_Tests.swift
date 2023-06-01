//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import SnapshotTesting
import XCTest

@MainActor
final class LobbyView_Tests: StreamVideoUITestCase {
    
    func test_lobbyView_snapshot() throws {
        for count in 1...2 {
            let users = UserFactory.get(count)
            let view = LobbyView(
                callViewModel: CallViewModel(),
                callId: callId,
                callType: callType,
                callParticipants: users
            )
            AssertSnapshot(view, suffix: "with_\(count)_participants")
        }
    }
}
