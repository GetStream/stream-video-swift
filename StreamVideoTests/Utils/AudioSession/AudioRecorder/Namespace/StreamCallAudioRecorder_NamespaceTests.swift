//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class StreamCallAudioRecorder_NamespaceTests: StreamVideoTestCase, @unchecked Sendable {

    typealias Subject = StreamCallAudioRecorder.Namespace

    func test_state_returnsExpectedValue() {
        XCTAssertTrue(Subject.State.self == Subject.StoreState.self)
    }

    func test_action_returnsExpectedValue() {
        XCTAssertTrue(Subject.Action.self == Subject.StoreAction.self)
    }

    func test_identifier_returnsExpectedValue() {
        XCTAssertEqual(Subject.identifier, "call.audio.recording.store")
    }

    func test_reducers_returnsExpectedValue() {
        XCTAssertEqual(
            Subject.reducers().map { "\(type(of: $0))" }, ["DefaultReducer"]
        )
    }

    func test_middleware_returnsExpectedValue() {
        XCTAssertEqual(
            Subject.middleware().map { "\(type(of: $0))" },
            [
                "InterruptionMiddleware",
                "CategoryMiddleware",
                "AVAudioRecorderMiddleware",
                "ShouldRecordMiddleware"
            ]
        )
    }
}
