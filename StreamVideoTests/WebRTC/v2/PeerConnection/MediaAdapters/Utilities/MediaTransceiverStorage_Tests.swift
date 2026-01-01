//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class MediaTransceiverStorage_Tests: XCTestCase, @unchecked Sendable {

    private lazy var factory: PeerConnectionFactory! = .mock()
    private lazy var trackA: RTCMediaStreamTrack! = factory.mockVideoTrack(forScreenShare: false)
    private lazy var trackB: RTCMediaStreamTrack! = factory.mockVideoTrack(forScreenShare: true)
    private lazy var subject: MediaTransceiverStorage<String>! = .init(for: .video)

    override func tearDown() {
        subject = nil
        trackA = nil
        trackB = nil
        factory = nil
        super.tearDown()
    }

    // MARK: - Initialization

    func test_initialization() {
        XCTAssertTrue(subject.isEmpty)
    }

    // MARK: - Storage Operations

    func test_addTransceiver() throws {
        subject.set(try makeTransceiver(), track: trackA, for: "transceiver1")

        XCTAssertEqual(subject.count, 1)
    }

    func test_getTransceiver() throws {
        let transceiver = try makeTransceiver()
        subject.set(transceiver, track: trackA, for: "transceiver1")

        let entry = try XCTUnwrap(subject.get(for: "transceiver1"))
        XCTAssertTrue(entry.transceiver === transceiver)
        XCTAssertTrue(entry.track === trackA)
    }

    func test_removeAllTransceivers() throws {
        subject.set(try makeTransceiver(), track: trackA, for: "transceiver1")
        subject.set(try makeTransceiver(), track: trackB, for: "transceiver2")

        subject.removeAll()

        XCTAssertTrue(subject.isEmpty)
    }

    // MARK: - Private Helpers

    private func makeTransceiver() throws -> RTCRtpTransceiver {
        try factory.mockTransceiver(
            of: .video,
            videoOptions: PublishOptions.VideoPublishOptions(
                id: subject.count,
                codec: .h264,
                capturingLayers: .init(spatialLayers: 1, temporalLayers: 1),
                bitrate: 1_000_000,
                frameRate: 30,
                dimensions: CGSize(width: 1920, height: 1080)
            )
        )
    }
}
