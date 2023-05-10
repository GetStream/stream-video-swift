//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import SnapshotTesting
import XCTest

@MainActor
final class RecordingView_Tests: StreamVideoUITestCase {
    
    func test_recordingView_snapshot() throws {
        let view = RecordingView()
        
        AssertSnapshot(view)
    }
}
