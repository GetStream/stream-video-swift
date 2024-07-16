//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class CallConnectingView_Tests: StreamVideoUITestCase {
    
    private lazy var viewModel: CallViewModel! = .init()
    private lazy var factory: DefaultViewFactory! = DefaultViewFactory.shared

    override func tearDown() {
        viewModel = nil
        factory = nil
        super.tearDown()
    }

    func test_callConnectingView_snapshot() throws {
        let view = CallConnectingView(
            outgoingCallMembers: [],
            title: "Test title 123",
            callControls: factory.makeCallControlsView(viewModel: viewModel),
            callTopView: factory.makeCallTopView(viewModel: viewModel)
        )
        AssertSnapshot(view, variants: snapshotVariants)
    }
}
