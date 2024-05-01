//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import StreamSwiftTestHelpers
import SnapshotTesting
import XCTest

@MainActor
final class CallControlsView_Tests: StreamVideoUITestCase {
    
    func test_callControlsView_snapshot() throws {
        let view = CallControlsView(viewModel: CallViewModel())
        AssertSnapshot(view, variants: snapshotVariants, size: sizeThatFits)
    }
}
