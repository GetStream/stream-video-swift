//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class VideoRenderingOptions_Tests: XCTestCase, @unchecked Sendable {

    private var subject: VideoRenderingOptions!

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - Initialization

    func test_init_defaults_setsExpectedValues() {
        subject = .init()

        XCTAssertEqual(subject.backend, .sharedMetal)
        XCTAssertEqual(subject.bufferPolicy, .convertWithPoolToNV12)
        XCTAssertEqual(subject.maxInFlightFrames, 0)
    }

    func test_description_includesConfiguredValues() {
        subject = .init(
            backend: .sharedMetal,
            bufferPolicy: .copyToNV12,
            maxInFlightFrames: 3
        )

        XCTAssertEqual(
            subject.description,
            "{ backend:.sharedMetal, bufferPolicy:.copyToNV12, maxInFlightFrames:3 }"
        )
    }
}
