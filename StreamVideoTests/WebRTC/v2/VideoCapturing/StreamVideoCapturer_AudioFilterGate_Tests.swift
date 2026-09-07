//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class StreamVideoCapturer_AudioFilterGate_Tests: XCTestCase,
    @unchecked Sendable {

    func test_setAudioFilterGate_inAppCapturer_attachesToHandler() {
        let subject = StreamVideoCapturer.screenShareCapturer(
            with: PeerConnectionFactory.mock()
                .makeVideoSource(forScreenShare: true),
            audioDeviceModule: .init(MockRTCAudioDeviceModule()),
            includeAudio: true
        )

        subject.setAudioFilterGate { _ in }

        let handler: ScreenShareCaptureHandler? = subject.actionHandler()
        XCTAssertNotNil(handler)
    }

    func test_setAudioFilterGate_broadcastCapturer_isNoOp() {
        let subject = StreamVideoCapturer.broadcastCapturer(
            with: PeerConnectionFactory.mock()
                .makeVideoSource(forScreenShare: true),
            audioDeviceModule: .init(MockRTCAudioDeviceModule())
        )

        subject.setAudioFilterGate { _ in }

        let handler: ScreenShareCaptureHandler? = subject.actionHandler()
        XCTAssertNil(handler)
    }
}
