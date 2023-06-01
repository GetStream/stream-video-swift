//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import SnapshotTesting
import XCTest

@MainActor
final class ReconnectionView_Tests: StreamVideoUITestCase {
    
    func test_reconnectionView_snapshot() throws {
        let view = ReconnectionView(viewModel: CallViewModel(), viewFactory: TestViewFactory())
        AssertSnapshot(view)
    }
}
