//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import StreamSwiftTestHelpers
import SnapshotTesting
import XCTest

@MainActor
final class JoiningCallView_Tests: StreamVideoUITestCase {
    
    func test_joiningCallView_snapshot() throws {
        let viewModel = CallViewModel()
        let view = JoiningCallView(
            callControls: DefaultViewFactory.shared.makeCallControlsView(viewModel: viewModel)
        )
        AssertSnapshot(view, variants: snapshotVariants)
    }
}
