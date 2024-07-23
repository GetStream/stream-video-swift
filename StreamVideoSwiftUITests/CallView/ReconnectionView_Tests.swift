//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class ReconnectionView_Tests: StreamVideoUITestCase {
    
    func test_reconnectionView_snapshot() throws {
        let view = ReconnectionView(viewModel: CallViewModel(), viewFactory: TestViewFactory())
        AssertSnapshot(view, variants: snapshotVariants)
    }
}
