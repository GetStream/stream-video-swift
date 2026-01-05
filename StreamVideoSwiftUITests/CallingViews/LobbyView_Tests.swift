//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class LobbyView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    private nonisolated(unsafe) var mockPermissions: MockPermissionsStore! = .init()

    override func tearDown() {
        mockPermissions = nil
        super.tearDown()
    }

    func test_lobbyView_snapshot() throws {
        for count in 0...2 {
            let viewModel = LobbyViewModel(callType: callId, callId: callType)
            let users = UserFactory.get(count).map(\.user)
            viewModel.participants = users
            let view = LobbyView(
                viewModel: viewModel,
                callId: callId,
                callType: callType,
                callSettings: .constant(CallSettings()),
                onJoinCallTap: {},
                onCloseLobby: {}
            )
            AssertSnapshot(view, variants: snapshotVariants, suffix: "with_\(count)_participants")
        }
    }
}
