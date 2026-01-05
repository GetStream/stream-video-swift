//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
@preconcurrency import StreamSwiftTestHelpers
@testable import StreamVideoSwiftUI
import SwiftUI
import XCTest

@MainActor
final class PictureInPictureReconnectionViewTests: StreamVideoUITestCase, @unchecked Sendable {

    func test_view_wasConfiguredCorrectly() {
        AssertSnapshot(
            PictureInPictureReconnectionView().frame(width: 400, height: 100),
            variants: snapshotVariants,
            size: .init(width: 400, height: 100)
        )
    }
}
