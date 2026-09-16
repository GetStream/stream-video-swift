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

    override func tearDown() async throws {
        mockPermissions = nil
        try await super.tearDown()
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

    func test_lobbyView_micAndCameraOff_snapshot() throws {
        let view = LobbyView(
            callId: callId,
            callType: callType,
            callSettings: .constant(
                CallSettings(audioOn: false, videoOn: false)
            ),
            onJoinCallTap: {},
            onCloseLobby: {}
        )

        AssertSnapshot(
            view,
            variants: snapshotVariants,
            suffix: "mic_and_camera_off"
        )
    }

    func test_lobbyView_micAndCameraPermissionDenied_snapshot() async throws {
        mockPermissions.dismantle()
        mockPermissions = nil

        let deniedPermissions = MockPermissionsStore()
        defer { deniedPermissions.dismantle() }

        deniedPermissions.stubMicrophonePermission(.denied)
        deniedPermissions.stubCameraPermission(.denied)
        await fulfillment {
            !deniedPermissions.permissionsStore.hasMicrophonePermission
                && !deniedPermissions.permissionsStore.canRequestMicrophonePermission
                && !deniedPermissions.permissionsStore.hasCameraPermission
                && !deniedPermissions.permissionsStore.canRequestCameraPermission
        }

        let view = LobbyView(
            callId: callId,
            callType: callType,
            callSettings: .constant(
                CallSettings(audioOn: false, videoOn: false)
            ),
            onJoinCallTap: {},
            onCloseLobby: {}
        )

        AssertSnapshot(
            view,
            variants: snapshotVariants,
            suffix: "mic_and_camera_permission_denied"
        )
    }
}
