//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class ReconnectionView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    private nonisolated(unsafe) var mockPermissions: MockPermissionsStore! = .init()

    override func tearDown() {
        mockPermissions = nil
        super.tearDown()
    }

    func test_reconnectionView_snapshot() throws {
        let view = ReconnectionView(viewModel: CallViewModel(), viewFactory: TestViewFactory())
        AssertSnapshot(view, variants: snapshotVariants)
    }
}
