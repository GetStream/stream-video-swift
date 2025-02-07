//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class OutgoingCallView_Tests: StreamVideoUITestCase {

    private lazy var viewModel: CallViewModel! = .init()
    private lazy var factory: DefaultViewFactory! = DefaultViewFactory.shared

    override func tearDown() {
        viewModel = nil
        factory = nil
        super.tearDown()
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
        viewModel.callingState = .outgoing
        viewModel.streamVideo.state.ringingCall = call

        let view = factory.makeOutgoingCallView(viewModel: viewModel)

        AssertSnapshot(view, variants: snapshotVariants)
    }
}
