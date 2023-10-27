//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import StreamSwiftTestHelpers
import SnapshotTesting
import XCTest

@MainActor
final class CallConnectingView_Tests: StreamVideoUITestCase {
    
    func test_callConnectingView_snapshot() throws {
        let view = CallConnectingView(
            outgoingCallMembers: [],
            title: "Test title 123",
            callControls: DefaultViewFactory.shared.makeCallControlsView(viewModel: CallViewModel())
        )
        AssertSnapshot(view)
    }
}
