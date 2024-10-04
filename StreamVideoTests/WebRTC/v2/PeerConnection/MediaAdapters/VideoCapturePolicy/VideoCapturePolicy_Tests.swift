//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class VideoCapturePolicy_Tests: XCTestCase {

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
    private lazy var subject: VideoCapturePolicy! = .init()

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
        await assertUpdateCaptureQuality(input: [.full, .half, .quarter])
    }

    func test_updateCaptureQuality_halfAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec() async throws {
        await assertUpdateCaptureQuality(input: [.half, .quarter])
    }

    func test_updateCaptureQuality_fullAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec() async throws {
        await assertUpdateCaptureQuality(input: [.full, .quarter])
    }

    func test_updateCaptureQuality_fullEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec() async throws {
        await assertUpdateCaptureQuality(input: [.full])
    }

    func test_updateCaptureQuality_halfEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec() async throws {
        await assertUpdateCaptureQuality(input: [.half])
    }

    func test_updateCaptureQuality_quarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec() async throws {
        await assertUpdateCaptureQuality(input: [.quarter])
    }

    // MARK: - Private helpers

    private func assertUpdateCaptureQuality(
        input: [VideoCodec],
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        await subject.updateCaptureQuality(
            with: .init(input.map(\.quality)),
            for: activeCaptureSession
        )

        XCTAssertEqual(
            cameraVideoCapturer.timesCalled(.updateCaptureQuality),
            0,
            file: file,
            line: line
        )
    }
}
