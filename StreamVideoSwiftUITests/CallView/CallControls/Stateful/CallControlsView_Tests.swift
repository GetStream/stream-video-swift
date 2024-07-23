//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class CallControlsView_Tests: StreamVideoUITestCase {
    
    func test_callControlsView_snapshot() throws {
        let view = CallControlsView(viewModel: CallViewModel())
        AssertSnapshot(view, variants: snapshotVariants, size: sizeThatFits)
    }
}
