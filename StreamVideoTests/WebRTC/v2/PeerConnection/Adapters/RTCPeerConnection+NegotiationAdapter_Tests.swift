//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class RTCPeerConnectionCoordinator_NegotiationAdapter_Tests: XCTestCase, @unchecked Sendable {
    private enum DummyError: Error { case transient }

    private lazy var sessionId: String! = .unique
    private lazy var peerType: PeerConnectionType! = .publisher
    private lazy var mockPeerConnection: MockRTCPeerConnection! = .init()
    private lazy var peerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var mockSFUStack: MockSFUStack! = .init()
    private lazy var spySubject: PassthroughSubject<TrackEvent, Never>! = .init()
    private lazy var mockLocalMediaAdapterA: MockLocalMediaAdapter! = .init()
    private lazy var mockLocalMediaAdapterB: MockLocalMediaAdapter! = .init()
    private lazy var mockLocalMediaAdapterC: MockLocalMediaAdapter! = .init()
    private lazy var audioMediaAdapter: AudioMediaAdapter! = .init(
        sessionID: sessionId,
        peerConnection: mockPeerConnection,
        peerConnectionFactory: peerConnectionFactory,
        localMediaManager: mockLocalMediaAdapterA,
        subject: spySubject
    )
    private lazy var videoMediaAdapter: VideoMediaAdapter! = .init(
        sessionID: sessionId,
        peerConnection: mockPeerConnection,
        peerConnectionFactory: peerConnectionFactory,
        localMediaManager: mockLocalMediaAdapterB,
        subject: spySubject
    )
    private lazy var screenShareMediaAdapter: ScreenShareMediaAdapter! = .init(
        sessionID: sessionId,
        peerConnection: mockPeerConnection,
        peerConnectionFactory: peerConnectionFactory,
        localMediaManager: mockLocalMediaAdapterC,
        subject: spySubject
    )
    private lazy var mediaAdapter: MediaAdapter! = .init(
        subject: spySubject,
        audioMediaAdapter: audioMediaAdapter,
        videoMediaAdapter: videoMediaAdapter,
        screenShareMediaAdapter: screenShareMediaAdapter
    )
    private lazy var subject: RTCPeerConnectionCoordinator! = .init(
        sessionId: sessionId,
        peerType: peerType,
        peerConnection: mockPeerConnection,
        videoOptions: .init(),
        callSettings: .init(),
        audioSettings: .dummy(opusDtxEnabled: true, redundantCodingEnabled: true),
        publishOptions: .dummy(),
        sfuAdapter: mockSFUStack.adapter,
        mediaAdapter: mediaAdapter,
        iceAdapter: .init(
            sessionID: sessionId,
            peerType: peerType,
            peerConnection: mockPeerConnection,
            sfuAdapter: mockSFUStack.adapter
        ),
        iceConnectionStateAdapter: .init(),
        clientCapabilities: []
    )
    private lazy var negotiationAdapter: RTCPeerConnectionCoordinator.NegotiationAdapter! = .init(
        subject,
        identifier: .init(),
        peerConnection: mockPeerConnection,
        peerType: peerType,
        sessionID: sessionId,
        sfuAdapter: mockSFUStack.adapter,
        clientCapabilities: [],
        subsystem: .peerConnectionPublisher
    )

    override func tearDown() {
        negotiationAdapter = nil
        subject = nil
        mediaAdapter = nil
        audioMediaAdapter = nil
        videoMediaAdapter = nil
        screenShareMediaAdapter = nil
        mockLocalMediaAdapterA = nil
        mockLocalMediaAdapterB = nil
        mockLocalMediaAdapterC = nil
        spySubject = nil
        mockSFUStack = nil
        peerConnectionFactory = nil
        mockPeerConnection = nil
        sessionId = nil
        super.tearDown()
    }

    func test_negotiate_setUpCompleted_callsSetPublisherAndSetsRemoteDescription() async throws {
        mockSFUStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        var response = Stream_Video_Sfu_Signal_SetPublisherResponse()
        let expectedAnswer = String.unique
        response.sdp = expectedAnswer
        mockSFUStack.service.stub(for: .setPublisher, with: response)
        subject.completeSetUp()

        try await negotiationAdapter.negotiate()

        XCTAssertEqual(mockPeerConnection?.timesCalled(.offer), 1)
        XCTAssertEqual(mockPeerConnection?.timesCalled(.setLocalDescription), 1)
        XCTAssertEqual(mockSFUStack.service.timesCalled(.setPublisher), 1)
        XCTAssertEqual(mockPeerConnection?.timesCalled(.setRemoteDescription), 1)
        XCTAssertEqual(
            mockPeerConnection.recordedInputPayload(
                RTCSessionDescription.self,
                for: .setRemoteDescription
            )?.first?.sdp,
            expectedAnswer
        )
    }

    func test_negotiate_setPublisherFailsOnce_retriesAndSetsRemoteDescription() async throws {
        mockSFUStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        var response = Stream_Video_Sfu_Signal_SetPublisherResponse()
        response.sdp = String.unique
        mockSFUStack.service.stub(
            for: .setPublisher,
            with: StubVariantResultProvider<Result<Stream_Video_Sfu_Signal_SetPublisherResponse, Error>> { iteration in
                iteration == 0 ? .failure(DummyError.transient) : .success(response)
            }
        )
        subject.completeSetUp()

        try await negotiationAdapter.negotiate()

        XCTAssertEqual(mockSFUStack.service.timesCalled(.setPublisher), 2)
        XCTAssertEqual(mockPeerConnection?.timesCalled(.setRemoteDescription), 1)
    }

    func test_negotiate_withPublishedAudioTrack_sendsTrackInSetPublisherRequest() async throws {
        mockSFUStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        let expectedTrack = Stream_Video_Sfu_Models_TrackInfo
            .dummy(trackType: .audio, mid: "0")
        mockLocalMediaAdapterA.stub(for: .trackInfo, with: [expectedTrack])
        subject.completeSetUp()

        try await negotiationAdapter.negotiate()

        XCTAssertEqual(
            mockSFUStack.service.setPublisherWasCalledWithRequest?.tracks.map(\.trackID),
            [expectedTrack.trackID]
        )
    }

    func test_negotiate_peerConnectionCoordinatorReleased_throwsClientError() async throws {
        mockSFUStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        var localAdapter: RTCPeerConnectionCoordinator.NegotiationAdapter!
        weak var weakCoordinator: RTCPeerConnectionCoordinator?
        do {
            let localCoordinator = try XCTUnwrap(subject)
            weakCoordinator = localCoordinator
            localAdapter = RTCPeerConnectionCoordinator.NegotiationAdapter(
                localCoordinator,
                identifier: .init(),
                peerConnection: mockPeerConnection,
                peerType: peerType,
                sessionID: sessionId,
                sfuAdapter: mockSFUStack.adapter,
                clientCapabilities: [],
                subsystem: .peerConnectionPublisher
            )
        }
        subject = nil
        await wait(for: 0.1)
        XCTAssertNil(weakCoordinator)

        do {
            try await localAdapter.negotiate()
            XCTFail("Expected an error but received success.")
        } catch {
            XCTAssertTrue(
                "\(error)".contains("RTCPeerConnectionCoordinator is unavailable"),
                "Received unexpected error: \(error)"
            )
        }
    }
}
