//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class VideoCapturePolicy_Tests: XCTestCase, @unchecked Sendable {

    private lazy var peerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var videoCapturer: MockStreamVideoCapturer! = .init()
    private lazy var subject: VideoCapturePolicy! = .init()

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        videoCapturer = nil
        peerConnectionFactory = nil
        super.tearDown()
    }

    // MARK: - updateCaptureQuality

    func test_updateCaptureQuality_capturerWasNotCalled() async throws {
        try await subject.updateCaptureQuality(
            with: .init(width: 1280, height: 720),
            for: .init(
                position: .front,
                localTrack: peerConnectionFactory.mockVideoTrack(forScreenShare: false),
                capturer: videoCapturer
            )
        )

        XCTAssertEqual(videoCapturer.timesCalled(.updateCaptureQuality), 0)
    }
}
