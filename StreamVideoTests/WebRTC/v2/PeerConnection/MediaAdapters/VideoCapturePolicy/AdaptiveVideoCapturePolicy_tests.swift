//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class AdaptiveVideoCapturePolicy_tests: XCTestCase {

    private lazy var device: AVCaptureDevice! = .init(uniqueID: .unique)
    private lazy var peerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var videoTrack: RTCVideoTrack! = (
        RTCMediaStreamTrack
            .dummy(kind: .video, peerConnectionFactory: peerConnectionFactory) as! RTCVideoTrack
    )
    private lazy var cameraVideoCapturer: MockCameraVideoCapturer! = .init()
    private lazy var activeCaptureSession: VideoCaptureSession! = .init(
        position: .front,
        device: device,
        localTrack: videoTrack,
        capturer: cameraVideoCapturer
    )
    private lazy var subject: AdaptiveVideoCapturePolicy! = .init()

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        activeCaptureSession = nil
        cameraVideoCapturer = nil
        videoTrack = nil
        peerConnectionFactory = nil
        device = nil
        super.tearDown()
    }

    // MARK: - updateCaptureQuality

    func test_updateCaptureQuality_fullHalfAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec() async throws {
        await assertUpdateCaptureQuality(expected: [.full, .half, .quarter])
    }

    func test_updateCaptureQuality_halfAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec() async throws {
        await assertUpdateCaptureQuality(expected: [.half, .quarter])
    }

    func test_updateCaptureQuality_fullAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec() async throws {
        await assertUpdateCaptureQuality(expected: [.full, .quarter])
    }

    func test_updateCaptureQuality_fullEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec() async throws {
        await assertUpdateCaptureQuality(expected: [.full])
    }

    func test_updateCaptureQuality_halfEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec() async throws {
        await assertUpdateCaptureQuality(expected: [.half])
    }

    func test_updateCaptureQuality_quarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec() async throws {
        await assertUpdateCaptureQuality(expected: [.quarter])
    }

    // MARK: - Private helpers

    private func assertUpdateCaptureQuality(
        expected: [VideoCodec],
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        await subject.updateCaptureQuality(
            with: .init(
                expected.map(\.quality)
            ),
            for: activeCaptureSession
        )

        XCTAssertEqual(
            cameraVideoCapturer.timesCalled(.updateCaptureQuality),
            1,
            file: file,
            line: line
        )
        XCTAssertEqual(
            cameraVideoCapturer.recordedInputPayload(([VideoCodec], AVCaptureDevice?).self, for: .updateCaptureQuality)?.first?.0
                .map(\.quality).sorted(),
            expected.map(\.quality).sorted(),
            file: file,
            line: line
        )
    }
}
