//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
@testable import StreamSwiftTestHelpers
import SnapshotTesting
import XCTest

@MainActor
final class JoiningCallView_Tests: StreamVideoUITestCase {
    
    func test_joiningCallView_snapshot() throws {
        let viewModel = CallViewModel()
        let view = JoiningCallView(
            callControls: DefaultViewFactory.shared.makeCallControlsView(viewModel: viewModel)
        )
        AssertSnapshot(view)
    }
}
