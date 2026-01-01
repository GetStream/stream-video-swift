//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class StreamCallAudioRecorder_StateTests: StreamVideoTestCase, @unchecked Sendable {

    func test_initial() {
        let actual = StreamCallAudioRecorder.Namespace.StoreState.initial

        XCTAssertFalse(actual.isRecording)
        XCTAssertFalse(actual.isInterrupted)
        XCTAssertFalse(actual.shouldRecord)
        XCTAssertEqual(actual.meter, 0)
    }
}
