//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCPeerConnectionCoordinator_Tests: XCTestCase {

    private lazy var sessionId: String! = .unique
    private lazy var mockPeerConnection: MockRTCPeerConnection! = .init()
    private lazy var peerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var mockSFUStack: (
        sfuAdapter: SFUAdapter,
        mockService: MockSignalServer,
        mockWebSocketClient: MockWebSocketClient
    )! = SFUAdapter.mock(webSocketClientType: .sfu)
    private lazy var audioSession: AudioSession! = .init()
    private lazy var spySubject: PassthroughSubject<TrackEvent, Never>! = .init()
    private lazy var mockLocalMediaAdapterA: MockLocalMediaAdapter! = .init()
    private lazy var mockLocalMediaAdapterB: MockLocalMediaAdapter! = .init()
    private lazy var mockLocalMediaAdapterC: MockLocalMediaAdapter! = .init()
    private lazy var audioMediaAdapter: AudioMediaAdapter! = .init(
        sessionID: sessionId,
        peerConnection: mockPeerConnection,
        peerConnectionFactory: peerConnectionFactory,
        localMediaManager: mockLocalMediaAdapterA,
        subject: spySubject,
        audioSession: audioSession
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
        peerType: .publisher,
        peerConnection: mockPeerConnection,
        videoOptions: .init(),
        callSettings: .init(),
        audioSettings: .init(),
        sfuAdapter: mockSFUStack.sfuAdapter,
        audioSession: audioSession,
        mediaAdapter: mediaAdapter
    )

    override func tearDown() {
        subject = nil
        mediaAdapter = nil
        audioMediaAdapter = nil
        videoMediaAdapter = nil
        screenShareMediaAdapter = nil
        mockLocalMediaAdapterA = nil
        mockLocalMediaAdapterB = nil
        mockLocalMediaAdapterC = nil
        spySubject = nil
        audioSession = nil
        mockSFUStack = nil
        peerConnectionFactory = nil
        mockPeerConnection = nil
        sessionId = nil
        super.tearDown()
    }

    // MARK: - setUp(with:ownCapabilities:)

    func test_setUp_setUpWasCalledOnAllMediaAdapters() async throws {
        try await subject.setUp(with: .init(), ownCapabilities: [])

        await fulfillment { [mockLocalMediaAdapterA, mockLocalMediaAdapterB, mockLocalMediaAdapterC] in
            mockLocalMediaAdapterA?.timesCalled(.setUp) == 1
                && mockLocalMediaAdapterB?.timesCalled(.setUp) == 1
                && mockLocalMediaAdapterC?.timesCalled(.setUp) == 1
        }
    }

    // MARK: - didUpdateCallSettings(_:)

    func test_didUpdateCallSettings_setUpWasCalledOnAllMediaAdapters() async throws {
        _ = subject
        try await subject.didUpdateCallSettings(.init())

        await fulfillment { [mockLocalMediaAdapterA, mockLocalMediaAdapterB, mockLocalMediaAdapterC] in
            mockLocalMediaAdapterA?.timesCalled(.didUpdateCallSettings) == 1
                && mockLocalMediaAdapterB?.timesCalled(.didUpdateCallSettings) == 1
                && mockLocalMediaAdapterC?.timesCalled(.didUpdateCallSettings) == 1
        }
    }

    // MARK: - createOffer(constraints:)

    func test_createOffer_peerConnectionWasCalled() async throws {
        try await subject.createOffer()

        await fulfillment { [mockPeerConnection] in
            mockPeerConnection?.timesCalled(.offer) == 1
        }
    }

    // MARK: - createAnswer(constraints:)

    func test_createAnswer_peerConnectionWasCalled() async throws {
        try await subject.createAnswer()

        await fulfillment { [mockPeerConnection] in
            mockPeerConnection?.timesCalled(.answer) == 1
        }
    }

    // MARK: - setLocalDescription(_:)

    func test_setLocalDescription_peerConnectionWasCalled() async throws {
        try await subject.setLocalDescription(.init(type: .answer, sdp: .unique))

        await fulfillment { [mockPeerConnection] in
            mockPeerConnection?.timesCalled(.setLocalDescription) == 1
        }
    }

    // MARK: - setRemoteDescription(_:)

    func test_setRemoteDescription_peerConnectionWasCalled() async throws {
        try await subject.setRemoteDescription(.init(type: .answer, sdp: .unique))

        await fulfillment { [mockPeerConnection] in
            mockPeerConnection?.timesCalled(.setRemoteDescription) == 1
        }
    }

    // MARK: - close

    func test_close_peerConnectionWasCalled() async throws {
        subject.close()

        XCTAssertEqual(mockPeerConnection?.timesCalled(.close), 1)
    }
}
