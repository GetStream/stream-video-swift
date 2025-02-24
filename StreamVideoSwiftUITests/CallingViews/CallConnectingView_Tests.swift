//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class CallConnectingView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    private lazy var viewModel: CallViewModel! = .init()
    private lazy var factory: DefaultViewFactory! = DefaultViewFactory.shared

    override func tearDown() async throws {
        viewModel = nil
        factory = nil
        try await super.tearDown()
    }

    func test_callConnectingView_snapshot() throws {
        let call = try XCTUnwrap(streamVideoUI?.streamVideo.call(callType: .default, callId: .unique))
        call.state.ownCapabilities.append(.sendAudio)
        call.state.ownCapabilities.append(.sendVideo)
        streamVideoUI?.streamVideo.state.ringingCall = call
        viewModel.callingState = .outgoing

        let view = CallConnectingView(
            outgoingCallMembers: [],
            title: "Test title 123",
            callControls: factory.makeCallControlsView(viewModel: viewModel),
            callTopView: factory.makeCallTopView(viewModel: viewModel)
        )
        AssertSnapshot(view, variants: snapshotVariants)
    }
}
