//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import SnapshotTesting
import XCTest

@MainActor
final class CallControlsView_Tests: StreamVideoUITestCase {
    
    func test_callControlsView_snapshot() throws {
        let view = CallControlsView(viewModel: CallViewModel())
        AssertSnapshot(view, size: sizeThatFits)
    }
}
