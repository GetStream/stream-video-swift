//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class RTCPeerConnectionCoordinator_Tests: XCTestCase {

    private lazy var sessionId: String! = .unique
    private lazy var peerType: PeerConnectionType! = .publisher
    private lazy var mockPeerConnection: MockRTCPeerConnection! = .init()
    private lazy var peerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var mockSFUStack: MockSFUStack! = .init()
    private lazy var audioSession: StreamAudioSessionAdapter! = .init()
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
        sfuAdapter: mockSFUStack.adapter,
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
        await subject.close()

        XCTAssertEqual(mockPeerConnection?.timesCalled(.close), 1)
    }

    // MARK: - negotiate

    // MARK: publisher

    func test_negotiate_subjectIsPublisher_callsOfferOnPeerConnection() async throws {
        _ = subject

        mockPeerConnection
            .subject
            .send(StreamRTCPeerConnection.ShouldNegotiateEvent())

        await fulfillment { [mockPeerConnection] in
            mockPeerConnection?.timesCalled(.offer) == 1
        }
    }

    func test_negotiate_subjectIsPublisher_callsSetLocalDescriptionWithExpectedOffer() async throws {
        _ = subject
        let offer = "useinbandfec=1;\r\n00:11 opus/;\r\n12:13: red/48000/2"
        let expectedOffer = "useinbandfec=1;usedtx=1;\r\n00:11 opus/;\r\n12:13: red/48000/2"

        mockPeerConnection.stub(
            for: .offer,
            with: RTCSessionDescription(type: .offer, sdp: offer)
        )

        mockPeerConnection
            .subject
            .send(StreamRTCPeerConnection.ShouldNegotiateEvent())

        await fulfillment { [mockPeerConnection] in
            mockPeerConnection?.timesCalled(.setLocalDescription) == 1
        }

        XCTAssertEqual(
            mockPeerConnection.recordedInputPayload(
                RTCSessionDescription.self,
                for: .setLocalDescription
            )?.first?.sdp,
            expectedOffer
        )
    }

    func test_negotiate_subjectIsPublisher_setUpCompletes_callsSetPublisherOnSFU() async throws {
        mockSFUStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        _ = subject

        let offer = "useinbandfec=1;\r\n00:11 opus/;\r\n12:13: red/48000/2"
        let expectedOffer = "useinbandfec=1;usedtx=1;\r\n00:11 opus/;\r\n12:13: red/48000/2"
        mockPeerConnection.stub(
            for: .offer,
            with: RTCSessionDescription(type: .offer, sdp: offer)
        )
        try await simulateConcurrentPeerConnectionSetUp {
            self.mockPeerConnection
                .subject
                .send(StreamRTCPeerConnection.ShouldNegotiateEvent())
        }

        await fulfillment { [mockSFUStack] in
            mockSFUStack?.service.setPublisherWasCalledWithRequest != nil
        }

        XCTAssertEqual(
            mockSFUStack.service.setPublisherWasCalledWithRequest?.sessionID,
            sessionId
        )
        XCTAssertEqual(
            mockSFUStack.service.setPublisherWasCalledWithRequest?.tracks,
            []
        )
        XCTAssertEqual(
            mockSFUStack.service.setPublisherWasCalledWithRequest?.sdp,
            expectedOffer
        )
    }

    func test_negotiate_subjectIsPublisher_setUpTimesOut_callsSetPublisherOnSFU() async throws {
        mockSFUStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        _ = subject

        let offer = "useinbandfec=1;\r\n00:11 opus/;\r\n12:13: red/48000/2"
        let expectedOffer = "useinbandfec=1;usedtx=1;\r\n00:11 opus/;\r\n12:13: red/48000/2"
        mockPeerConnection.stub(
            for: .offer,
            with: RTCSessionDescription(type: .offer, sdp: offer)
        )
        try await simulateConcurrentPeerConnectionSetUp(shouldFail: true) {
            self.mockPeerConnection
                .subject
                .send(StreamRTCPeerConnection.ShouldNegotiateEvent())
        }

        await wait(for: WebRTCConfiguration.timeout.publisherSetUpBeforeNegotiation)
        XCTAssertNil(mockSFUStack?.service.setPublisherWasCalledWithRequest)
    }

    func test_negotiate_subjectIsPublisher_setUpCompletes_callsSetRemoteDescriptionWithExpectedOffer() async throws {
        mockSFUStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        _ = subject
        mockPeerConnection.stub(
            for: .offer,
            with: RTCSessionDescription(type: .offer, sdp: .unique)
        )
        var response = Stream_Video_Sfu_Signal_SetPublisherResponse()
        let expectedAnswer = String.unique
        response.sdp = expectedAnswer
        mockSFUStack.service.stub(for: .setPublisher, with: response)

        try await simulateConcurrentPeerConnectionSetUp {
            self
                .mockPeerConnection
                .subject
                .send(StreamRTCPeerConnection.ShouldNegotiateEvent())
        }

        await fulfillment { [mockPeerConnection] in
            mockPeerConnection?.timesCalled(.setRemoteDescription) == 1
        }

        XCTAssertEqual(
            mockPeerConnection.recordedInputPayload(
                RTCSessionDescription.self,
                for: .setRemoteDescription
            )?.first?.sdp,
            expectedAnswer
        )
        XCTAssertEqual(
            mockPeerConnection.recordedInputPayload(
                RTCSessionDescription.self,
                for: .setRemoteDescription
            )?.first?.type,
            .answer
        )
    }

    func test_negotiate_subjectIsPublisher_setUpTimesOut_callsSetRemoteDescriptionWithExpectedOffer() async throws {
        mockSFUStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        _ = subject
        mockPeerConnection.stub(
            for: .offer,
            with: RTCSessionDescription(type: .offer, sdp: .unique)
        )
        var response = Stream_Video_Sfu_Signal_SetPublisherResponse()
        let expectedAnswer = String.unique
        response.sdp = expectedAnswer
        mockSFUStack.service.stub(for: .setPublisher, with: response)

        try await simulateConcurrentPeerConnectionSetUp(shouldFail: true) {
            self
                .mockPeerConnection
                .subject
                .send(StreamRTCPeerConnection.ShouldNegotiateEvent())
        }

        await wait(for: WebRTCConfiguration.timeout.publisherSetUpBeforeNegotiation)
        XCTAssertEqual(mockPeerConnection?.timesCalled(.setRemoteDescription), 0)
    }

    // MARK: subscriber

    func test_negotiate_subjectIsSubscriber_doesNotCallCreateOfferOnPeerConnection() async throws {
        peerType = .subscriber
        _ = subject

        mockPeerConnection
            .subject
            .send(StreamRTCPeerConnection.ShouldNegotiateEvent())

        await wait(for: 1)

        XCTAssertEqual(mockPeerConnection?.timesCalled(.offer), 0)
    }

    // MARK: - handleSubscriberOffer

    // MARK: publisher

    func test_handleSubscriberOffer_subjectIsPublisher_doesNotCallSetRemoteDescription() async throws {
        _ = subject

        mockSFUStack.receiveEvent(.sfuEvent(.subscriberOffer(Stream_Video_Sfu_Event_SubscriberOffer())))

        await wait(for: 1)
        XCTAssertEqual(mockPeerConnection?.timesCalled(.setRemoteDescription), 0)
    }

    // MARK: subscriber

    func test_handleSubscriberOffer_subjectIsSubscriber_callsSetRemoteDescription() async throws {
        peerType = .subscriber
        _ = subject

        var offer = Stream_Video_Sfu_Event_SubscriberOffer()
        offer.sdp = .unique
        mockSFUStack.receiveEvent(.sfuEvent(.subscriberOffer(offer)))

        await fulfillment { [mockPeerConnection] in
            mockPeerConnection?.timesCalled(.setRemoteDescription) == 1
        }
        XCTAssertEqual(
            mockPeerConnection.recordedInputPayload(
                RTCSessionDescription.self,
                for: .setRemoteDescription
            )?.first?.sdp,
            offer.sdp
        )
    }

    func test_handleSubscriberOffer_subjectIsSubscriber_callsCreateAnswer() async throws {
        peerType = .subscriber
        _ = subject
        mockPeerConnection.stub(for: .answer, with: RTCSessionDescription(type: .answer, sdp: .unique))

        var offer = Stream_Video_Sfu_Event_SubscriberOffer()
        offer.sdp = .unique
        mockSFUStack.receiveEvent(.sfuEvent(.subscriberOffer(offer)))

        await fulfillment { [mockPeerConnection] in
            mockPeerConnection?.timesCalled(.answer) == 1
        }
    }

    func test_handleSubscriberOffer_subjectIsSubscriber_callsSetLocalDescription() async throws {
        peerType = .subscriber
        _ = subject
        let sdp = String.unique
        mockPeerConnection.stub(for: .answer, with: RTCSessionDescription(type: .answer, sdp: sdp))

        var offer = Stream_Video_Sfu_Event_SubscriberOffer()
        offer.sdp = .unique
        mockSFUStack.receiveEvent(.sfuEvent(.subscriberOffer(offer)))

        await fulfillment { [mockPeerConnection] in
            mockPeerConnection?.timesCalled(.setLocalDescription) == 1
        }

        XCTAssertEqual(
            mockPeerConnection.recordedInputPayload(
                RTCSessionDescription.self,
                for: .setLocalDescription
            )?.first?.sdp,
            sdp
        )
    }

    func test_negotiate_subjectIsPublisher_callsSendAnswerOnSFU() async throws {
        mockSFUStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        peerType = .subscriber
        _ = subject
        let sdp = String.unique
        mockPeerConnection.stub(
            for: .answer,
            with: RTCSessionDescription(type: .offer, sdp: sdp)
        )

        mockSFUStack.receiveEvent(.sfuEvent(.subscriberOffer(Stream_Video_Sfu_Event_SubscriberOffer())))

        await fulfillment { [mockSFUStack] in
            mockSFUStack?.service.sendAnswerWasCalledWithRequest != nil
        }

        XCTAssertEqual(
            mockSFUStack.service.sendAnswerWasCalledWithRequest?.sessionID,
            sessionId
        )
        XCTAssertEqual(
            mockSFUStack.service.sendAnswerWasCalledWithRequest?.peerType,
            .subscriber
        )
        XCTAssertEqual(
            mockSFUStack.service.sendAnswerWasCalledWithRequest?.sdp,
            sdp
        )
    }

    // MARK: - Private helpers

    private func simulateConcurrentPeerConnectionSetUp(
        callSettings: CallSettings = .init(),
        ownCapabilities: [OwnCapability] = [],
        setUpDelay: TimeInterval = 0,
        shouldFail: Bool = false,
        _ operation: @escaping () async throws -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                guard !shouldFail else { return }
                if setUpDelay > 0 {
                    await self.wait(for: setUpDelay)
                }
                try await self.subject.setUp(
                    with: callSettings,
                    ownCapabilities: ownCapabilities
                )
            }

            group.addTask {
                try await operation()
            }

            try await group.waitForAll()
        }
    }
}
