//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class CameraCaptureSessionConfigurationHandler_Tests: XCTestCase, @unchecked Sendable {

    private lazy var subject: CameraCaptureSessionConfigurationHandler! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - startCapture

    func test_startCapture_captureSessionWasConfiguredCorrectly() async throws {
        let capturer = RTCCameraVideoCapturer()
        capturer.captureSession.usesApplicationAudioSession = false

        try await subject.handle(
            .startCapture(
                position: .back,
                dimensions: .full,
                frameRate: .zero,
                videoSource: PeerConnectionFactory.mock().makeVideoSource(forScreenShare: false),
                videoCapturer: capturer,
                videoCapturerDelegate: MockRTCVideoCapturerDelegate(),
                audioDeviceModule: .init(MockRTCAudioDeviceModule())
            )
        )

        XCTAssertEqual(capturer.captureSession.sessionPreset, .inputPriority)
        XCTAssertTrue(capturer.captureSession.usesApplicationAudioSession)
    }
}
