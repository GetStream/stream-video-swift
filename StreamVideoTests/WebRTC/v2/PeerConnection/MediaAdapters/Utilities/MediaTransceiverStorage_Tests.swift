//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class MediaTransceiverStorage_Tests: XCTestCase {

    private lazy var factory: PeerConnectionFactory! = .mock()
    private lazy var subject: MediaTransceiverStorage<String>! = .init(for: .video)

    override func tearDown() {
        subject = nil
        factory = nil
        super.tearDown()
    }

    // MARK: - Initialization

    func test_initialization() {
        XCTAssertTrue(subject.isEmpty)
    }

    // MARK: - Storage Operations

    func test_addTransceiver() throws {
        subject.set(try makeTransceiver(), for: "transceiver1")

        XCTAssertEqual(subject.count, 1)
    }

    func test_getTransceiver() throws {
        let transceiver = try makeTransceiver()
        subject.set(transceiver, for: "transceiver1")

        let retrievedTransceiver = subject.get(for: "transceiver1")
        XCTAssertTrue(retrievedTransceiver === transceiver)
    }

    func test_removeTransceiver() throws {
        subject.set(try makeTransceiver(), for: "transceiver1")

        subject.set(nil, for: "transceiver1")

        XCTAssertNil(subject.get(for: "transceiver1"))
    }

    func test_removeAllTransceivers() throws {
        subject.set(try makeTransceiver(), for: "transceiver1")
        subject.set(try makeTransceiver(), for: "transceiver2")

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
