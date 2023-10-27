//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import StreamSwiftTestHelpers
import SnapshotTesting
import XCTest

@MainActor
final class LobbyView_Tests: StreamVideoUITestCase {
    
    func test_lobbyView_snapshot() throws {
        for count in 0...2 {
            let viewModel = LobbyViewModel(callType: callId, callId: callType)
            let users = UserFactory.get(count).map { $0.user }
            viewModel.participants = users
            let view = LobbyView(
                viewModel: viewModel,
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
