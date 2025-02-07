//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class JoiningCallView_Tests: StreamVideoUITestCase {
    
    private lazy var viewModel: CallViewModel! = .init()
    private lazy var factory: DefaultViewFactory! = DefaultViewFactory.shared

    override func tearDown() {
        viewModel = nil
        factory = nil
        super.tearDown()
    }

    func test_joiningCallView_snapshot() throws {
        let view = JoiningCallView(
            callTopView: factory.makeCallTopView(viewModel: viewModel),
            callControls: factory.makeCallControlsView(viewModel: viewModel)
        )
        AssertSnapshot(view, variants: snapshotVariants, record: true)
    }
}
