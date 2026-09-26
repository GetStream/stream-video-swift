//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
@preconcurrency import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class CallTopView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    private nonisolated(unsafe) var mockPermissions: MockPermissionsStore! = .init()

    override func tearDown() async throws {
        mockPermissions = nil
        try await super.tearDown()
    }

    func test_callTopView_snapshot() throws {
        let viewModel = try makeViewModel()

        AssertSnapshot(
            CallTopView(viewModel: viewModel),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    func test_callTopView_sharingIndicator_snapshot() {
        AssertSnapshot(
            SharingIndicator(viewModel: CallViewModel(), sharingPopupDismissed: .constant(false))
                .fixedSize(),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    // MARK: - Private Helpers

    private func makeViewModel() throws -> CallViewModel {
        let call = try XCTUnwrap(streamVideoUI?.streamVideo.call(callType: callType, callId: .unique))
        call.state.ownCapabilities = [.sendAudio, .sendVideo]
        let viewModel = CallViewModel()
        viewModel.setActiveCall(call)
        return viewModel
    }
}
