//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
@preconcurrency import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class WaitingLocalUserView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    private nonisolated(unsafe) var mockPermissions: MockPermissionsStore! = .init()

    override func tearDown() async throws {
        mockPermissions = nil
        try await super.tearDown()
    }

    func test_waitingLocalUserView_snapshot() throws {
        let call = try XCTUnwrap(streamVideoUI?.streamVideo.call(callType: callType, callId: .unique))
        call.state.ownCapabilities = [.sendAudio, .sendVideo]
        let viewModel = CallViewModel()
        viewModel.setActiveCall(call)

        AssertSnapshot(
            WaitingLocalUserView(viewModel: viewModel, viewFactory: TestViewFactory()),
            variants: snapshotVariants
        )
    }
}
