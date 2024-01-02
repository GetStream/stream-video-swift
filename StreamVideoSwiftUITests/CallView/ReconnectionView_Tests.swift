//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import StreamSwiftTestHelpers
import SnapshotTesting
import XCTest

@MainActor
final class ReconnectionView_Tests: StreamVideoUITestCase {
    
    func test_reconnectionView_snapshot() throws {
        let view = ReconnectionView(viewModel: CallViewModel(), viewFactory: TestViewFactory())
        AssertSnapshot(view, variants: snapshotVariants)
    }
}
