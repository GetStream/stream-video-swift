//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class CallControlsView_Tests: StreamVideoUITestCase {
    
    func test_callControlsView_withoutCapabilities_snapshot() throws {
        let view = CallControlsView(viewModel: CallViewModel())
        AssertSnapshot(
            view,
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    func test_callControlsView_activeCall_snapshot() throws {
        let call = streamVideoUI?.streamVideo.call(callType: .default, callId: .unique)
        call?.state.ownCapabilities = [.sendAudio, .sendVideo]
        let viewModel = CallViewModel()
        viewModel.setActiveCall(call)

        let view = CallControlsView(viewModel: viewModel)
        AssertSnapshot(
            view,
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    func test_callControlsView_ringingCall_snapshot() async throws {
        let call = try XCTUnwrap(streamVideoUI?.streamVideo.call(callType: .default, callId: .unique))
        call.state.ownCapabilities = [.sendAudio, .sendVideo]
        streamVideoUI?.streamVideo.state.ringingCall = call
        let viewModel = CallViewModel()
        viewModel.callingState = .outgoing

        let view = CallControlsView(viewModel: viewModel)
        AssertSnapshot(
            view,
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }
}
