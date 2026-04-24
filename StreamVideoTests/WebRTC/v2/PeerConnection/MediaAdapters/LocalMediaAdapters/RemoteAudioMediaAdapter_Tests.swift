//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RemoteAudioMediaAdapter_Tests: XCTestCase, @unchecked Sendable {

    private lazy var peerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var mockPeerConnection: MockRTCPeerConnection! = .init()
    private lazy var spySubject: PassthroughSubject<TrackEvent, Never>! = .init()
    private lazy var subject: RemoteAudioMediaAdapter! = .init(
        subject: spySubject,
        peerConnection: mockPeerConnection
    )

    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        subject = nil
        spySubject = nil
        mockPeerConnection = nil
        peerConnectionFactory = nil
        super.tearDown()
    }

    // MARK: - AddedReceiverEvent

    func test_addedReceiver_audioReceiver_shouldPublishAddedTrackEvent() throws {
        let recorder = TrackEventRecorder()
        let trackId = String.unique
        let receiver = try makeAudioReceiver()
        let stream = makeAudioStream(trackId: trackId)
        let audioTrack = try XCTUnwrap(receiver.track as? RTCAudioTrack)
        observeEvents(with: recorder)

        mockPeerConnection.subject.send(
            StreamRTCPeerConnection.AddedReceiverEvent(
                receiver: receiver,
                streams: [stream]
            )
        )

        waitForEvents(count: 1, in: recorder)
        guard case let .added(id, trackType, track) = recorder.events.first else {
            return XCTFail("Expected an added track event.")
        }
        XCTAssertEqual(id, trackId)
        XCTAssertEqual(trackType, .audio)
        XCTAssertEqual(track.trackId, audioTrack.trackId)
    }

    // MARK: - RemovedReceiverEvent

    func test_removedReceiver_existingAudioReceiver_shouldPublishRemovedTrackEvent() throws {
        let recorder = TrackEventRecorder()
        let trackId = String.unique
        let receiver = try makeAudioReceiver()
        let stream = makeAudioStream(trackId: trackId)
        let audioTrack = try XCTUnwrap(receiver.track as? RTCAudioTrack)
        observeEvents(with: recorder)
        mockPeerConnection.subject.send(
            StreamRTCPeerConnection.AddedReceiverEvent(
                receiver: receiver,
                streams: [stream]
            )
        )
        waitForEvents(count: 1, in: recorder)

        mockPeerConnection.subject.send(
            StreamRTCPeerConnection.RemovedReceiverEvent(receiver: receiver)
        )

        waitForEvents(count: 2, in: recorder)
        guard case let .removed(id, trackType, track) = recorder.events.last else {
            return XCTFail("Expected a removed track event.")
        }
        XCTAssertEqual(id, trackId)
        XCTAssertEqual(trackType, .audio)
        XCTAssertEqual(track.trackId, audioTrack.trackId)
    }

    // MARK: - Private Helpers

    private func makeAudioReceiver() throws -> RTCRtpReceiver {
        try peerConnectionFactory
            .mockTransceiver(
                direction: .recvOnly,
                audioOptions: .dummy(codec: .opus)
            )
            .receiver
    }

    private func makeAudioStream(trackId: String) -> RTCMediaStream {
        peerConnectionFactory.mockMediaStream(
            streamID: "\(trackId):TRACK_TYPE_AUDIO"
        )
    }

    private func observeEvents(with recorder: TrackEventRecorder) {
        _ = subject
        spySubject
            .sink { recorder.events.append($0) }
            .store(in: &cancellables)
    }

    private func waitForEvents(
        count: Int,
        in recorder: TrackEventRecorder,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in recorder.events.count == count },
            object: nil
        )
        wait(for: [expectation], timeout: defaultTimeout)
        XCTAssertEqual(recorder.events.count, count, file: file, line: line)
    }
}

private final class TrackEventRecorder: @unchecked Sendable {
    @Atomic var events: [TrackEvent] = []
}
