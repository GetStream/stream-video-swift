//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class WebRTCTrackStorage_Tests: XCTestCase, @unchecked Sendable {

    private lazy var peerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var subject: WebRTCTrackStorage! = .init()

    override func tearDown() {
        subject = nil
        peerConnectionFactory = nil
        super.tearDown()
    }

    // MARK: - Add & Retrieve

    func test_add_and_retrieve_audioTrack() {
        let audioTrack = track(kind: .audio)
        let participantID = "user1"
        subject.addTrack(audioTrack, type: .audio, for: participantID)

        let fetched = subject.track(for: participantID, of: .audio)
        XCTAssertNotNil(fetched)
        XCTAssertTrue(fetched is RTCAudioTrack)
        XCTAssertEqual(fetched as? RTCAudioTrack, audioTrack)
    }

    func test_add_and_retrieve_videoTrack() {
        let videoTrack = track(kind: .video)
        let participantID = "user2"
        subject.addTrack(videoTrack, type: .video, for: participantID)

        let fetched = subject.track(for: participantID, of: .video)
        XCTAssertNotNil(fetched)
        XCTAssertTrue(fetched is RTCVideoTrack)
        XCTAssertEqual(fetched as? RTCVideoTrack, videoTrack)
    }

    func test_add_and_retrieve_screenShareTrack() {
        let screenTrack = track(kind: .screenshare)
        let participantID = "user3"
        subject.addTrack(screenTrack, type: .screenshare, for: participantID)

        let fetched = subject.track(for: participantID, of: .screenshare)
        XCTAssertNotNil(fetched)
        XCTAssertTrue(fetched is RTCVideoTrack)
        XCTAssertEqual(fetched as? RTCVideoTrack, screenTrack)
    }

    // MARK: - Remove

    func test_removeTrack_byType() {
        let audioTrack = track(kind: .audio)
        let participantID = "user4"
        subject.addTrack(audioTrack, type: .audio, for: participantID)

        subject.removeTrack(for: participantID, type: .audio)
        let fetched = subject.track(for: participantID, of: .audio)
        XCTAssertNil(fetched)
    }

    func test_removeTrack_removesOnlySpecificType() {
        let audioTrack = track(kind: .audio)
        let videoTrack = track(kind: .video)
        let participantID = "user5"
        subject.addTrack(audioTrack, type: .audio, for: participantID)
        subject.addTrack(videoTrack, type: .video, for: participantID)

        subject.removeTrack(for: participantID, type: .audio)
        XCTAssertNil(subject.track(for: participantID, of: .audio))
        XCTAssertNotNil(subject.track(for: participantID, of: .video))
    }

    func test_removeTrack_allTypesForParticipant() {
        let audioTrack = track(kind: .audio)
        let videoTrack = track(kind: .video)
        let participantID = "user6"
        subject.addTrack(audioTrack, type: .audio, for: participantID)
        subject.addTrack(videoTrack, type: .video, for: participantID)

        subject.removeTrack(for: participantID)
        XCTAssertNil(subject.track(for: participantID, of: .audio))
        XCTAssertNil(subject.track(for: participantID, of: .video))
    }

    // MARK: - Remove All

    func test_removeAll_removesAllTracks() {
        let audioTrack = track(kind: .audio)
        let videoTrack = track(kind: .video)
        subject.addTrack(audioTrack, type: .audio, for: "user7")
        subject.addTrack(videoTrack, type: .video, for: "user8")

        subject.removeAll()
        XCTAssertNil(subject.track(for: "user7", of: .audio))
        XCTAssertNil(subject.track(for: "user8", of: .video))
    }

    // MARK: - Snapshot

    func test_snapshot_returnsAllIDsAndTypes() {
        let audioTrack = track(kind: .audio)
        let videoTrack = track(kind: .video)
        let screenTrack = track(kind: .video)
        subject.addTrack(audioTrack, type: .audio, for: "user9")
        subject.addTrack(videoTrack, type: .video, for: "user10")
        subject.addTrack(screenTrack, type: .screenshare, for: "user11")

        let snapshot = subject.snapshot
        XCTAssertEqual(snapshot["user9"], .audio)
        XCTAssertEqual(snapshot["user10"], .video)
        XCTAssertEqual(snapshot["user11"], .screenshare)
    }

    // MARK: - Retrieve

    func test_track_forUnknownID_returnsNil() {
        let fetched = subject.track(for: "unknown", of: .audio)
        XCTAssertNil(fetched)
    }

    func test_track_forUnknownType_returnsNil() {
        let audioTrack = track(kind: .audio)
        subject.addTrack(audioTrack, type: .audio, for: "user12")
        let fetched = subject.track(for: "user12", of: .screenshare)
        XCTAssertNil(fetched)
    }

    // MARK: - Private Helpers

    private func track(kind: TrackType) -> RTCMediaStreamTrack {
        .dummy(kind: kind, peerConnectionFactory: peerConnectionFactory)
    }
}
