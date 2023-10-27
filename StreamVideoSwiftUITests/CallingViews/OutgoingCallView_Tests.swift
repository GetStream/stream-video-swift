//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import StreamSwiftTestHelpers
import SnapshotTesting
import XCTest

@MainActor
final class OutgoingCallView_Tests: StreamVideoUITestCase {
    
    func test_outgoingCallView_snapshot() throws {
        let viewModel = CallViewModel()
        let view = OutgoingCallView(
            outgoingCallMembers: viewModel.outgoingCallMembers.map(\.toMember),
            callControls: DefaultViewFactory.shared.makeCallControlsView(viewModel: viewModel)
        )
        AssertSnapshot(view)
    }
}
