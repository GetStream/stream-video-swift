//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class OutgoingCallView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    private lazy var viewModel: CallViewModel! = .init()
    private lazy var factory: DefaultViewFactory! = DefaultViewFactory.shared
    private nonisolated(unsafe) var mockPermissions: MockPermissionsStore! = .init()
    
    override func tearDown() async throws {
        viewModel = nil
        factory = nil
        mockPermissions = nil
        try await super.tearDown()
    }

    func test_outgoingCallView_snapshot() throws {
        let viewModel = CallViewModel()
        let call = try XCTUnwrap(streamVideoUI?.streamVideo.call(callType: .default, callId: .unique))
        call.state.ownCapabilities.append(.sendAudio)
        call.state.ownCapabilities.append(.sendVideo)
        call.state.members = [
            .init(user: viewModel.streamVideo.user),
            .init(userId: "test-user")
        ]
        viewModel.streamVideo.state.ringingCall = call
        viewModel.setActiveCall(call)
        viewModel.callingState = .outgoing

        let view = factory.makeOutgoingCallView(viewModel: viewModel)

        AssertSnapshot(view, variants: snapshotVariants)
    }
}
