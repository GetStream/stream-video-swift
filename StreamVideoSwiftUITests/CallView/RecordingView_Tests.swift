//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class RecordingView_Tests: StreamVideoUITestCase, @unchecked Sendable {
    
    func test_recordingView_snapshot() throws {
        let view = RecordingView().background(.green)
        AssertSnapshot(view, variants: snapshotVariants)
    }
}
