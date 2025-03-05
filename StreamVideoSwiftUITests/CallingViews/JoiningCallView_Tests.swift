//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class JoiningCallView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    private lazy var viewModel: CallViewModel! = .init()
    private lazy var factory: DefaultViewFactory! = DefaultViewFactory.shared

    override func tearDown() async throws {
        viewModel = nil
        factory = nil
        try await super.tearDown()
    }

    func test_joiningCallView_snapshot() throws {
        let view = JoiningCallView(
            callTopView: factory.makeCallTopView(viewModel: viewModel),
            callControls: factory.makeCallControlsView(viewModel: viewModel)
        )
        AssertSnapshot(view, variants: snapshotVariants)
    }
}
