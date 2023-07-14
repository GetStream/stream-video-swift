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
            let view = LobbyView(
                callId: callId,
                callType: callType,
                callSettings: .constant(CallSettings()),
                onJoinCallTap: {},
                onCloseLobby: {}
            )
            AssertSnapshot(view, suffix: "with_\(count)_participants")
        }
    }
}
