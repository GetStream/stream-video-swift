//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class RTCPeerConnectionCoordinator_Tests: XCTestCase, @unchecked Sendable {

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
    private lazy var iceConnectionStateAdapter: ICEConnectionStateAdapter! = .init()
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
        iceConnectionStateAdapter: iceConnectionStateAdapter,
        clientCapabilities: []
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
        mockSFUStack = nil
        peerConnectionFactory = nil
        mockPeerConnection = nil
        sessionId = nil
        iceConnectionStateAdapter = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init_peerConnectionCoordinatorWasSetOnICEConnectionStateAdapter() {
        _ = subject

        XCTAssertTrue(iceConnectionStateAdapter.peerConnectionCoordinator === subject)
    }

    // MARK: - isHealthy

    func test_isHealthy_ICEConnectionFailed_ConnectionStateHealthy_returnsFalse() {
        mockPeerConnection.stub(for: \.iceConnectionState, with: .failed)
        mockPeerConnection.stub(for: \.connectionState, with: .connected)

        XCTAssertFalse(subject.isHealthy)
    }

    func test_isHealthy_ICEConnectionClose_ConnectionStateHealthy_returnsFalse() {
        mockPeerConnection.stub(for: \.iceConnectionState, with: .closed)
        mockPeerConnection.stub(for: \.connectionState, with: .connected)

        XCTAssertFalse(subject.isHealthy)
    }

    func test_isHealthy_ICEConnectionHealthy_ConnectionStateFailed_returnsTrue() {
        mockPeerConnection.stub(for: \.iceConnectionState, with: .connected)
        mockPeerConnection.stub(for: \.connectionState, with: .failed)

        XCTAssertFalse(subject.isHealthy)
    }

    func test_isHealthy_ICEConnectionHealthy_ConnectionStateClosed_returnsTrue() {
        mockPeerConnection.stub(for: \.iceConnectionState, with: .connected)
        mockPeerConnection.stub(for: \.connectionState, with: .closed)

        XCTAssertFalse(subject.isHealthy)
    }

    func test_isHealthy_ICEConnectionHealthy_ConnectionStateHealthy_returnsTrue() {
        mockPeerConnection.stub(for: \.iceConnectionState, with: .connected)
        mockPeerConnection.stub(for: \.connectionState, with: .connected)

        XCTAssertTrue(subject.isHealthy)
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
        _ = try await subject.createOffer()

        await fulfillment { [mockPeerConnection] in
            mockPeerConnection?.timesCalled(.offer) == 1
        }
    }

    func test_createOffer_eventWasPublished() async throws {
        let offer = RTCSessionDescription(type: .offer, sdp: .unique)
        mockPeerConnection.stub(for: .offer, with: offer)

        let expectation = self.expectation(description: "CreateOfferEvent was not received.")
        let cancellable: AnyCancellable? = mockPeerConnection
            .publisher
            .compactMap { $0 as? StreamRTCPeerConnection.CreateOfferEvent }
            .filter { $0.sessionDescription.sdp == offer.sdp }
            .sink { _ in expectation.fulfill() }
        defer { cancellable?.cancel() }

        _ = try await subject.createOffer()

        await safeFulfillment(of: [expectation])
    }

    // MARK: - createAnswer(constraints:)

    func test_createAnswer_peerConnectionWasCalled() async throws {
        _ = try await subject.createAnswer()

        await fulfillment { [mockPeerConnection] in
            mockPeerConnection?.timesCalled(.answer) == 1
        }
    }

    func test_createAnswer_eventWasPublished() async throws {
        let answer = RTCSessionDescription(type: .offer, sdp: .unique)
        mockPeerConnection.stub(for: .answer, with: answer)

        let expectation = self.expectation(description: "CreateAnswerEvent was not received.")
        let cancellable: AnyCancellable? = mockPeerConnection
            .publisher
            .compactMap { $0 as? StreamRTCPeerConnection.CreateAnswerEvent }
            .filter { $0.sessionDescription.sdp == answer.sdp }
            .sink { _ in expectation.fulfill() }
        defer { cancellable?.cancel() }

        _ = try await subject.createAnswer()

        await safeFulfillment(of: [expectation])
    }

    // MARK: - setLocalDescription(_:)

    func test_setLocalDescription_peerConnectionWasCalled() async throws {
        try await subject.setLocalDescription(.init(type: .answer, sdp: .unique))

        await fulfillment { [mockPeerConnection] in
            mockPeerConnection?.timesCalled(.setLocalDescription) == 1
        }
    }

    func test_setLocalDescription_eventWasPublished() async throws {
        let value = RTCSessionDescription(type: .offer, sdp: .unique)
        mockPeerConnection.stub(for: .setLocalDescription, with: value)

        let expectation = self.expectation(description: "setLocalDescription was not received.")
        let cancellable: AnyCancellable? = mockPeerConnection
            .publisher
            .compactMap { $0 as? StreamRTCPeerConnection.SetLocalDescriptionEvent }
            .filter { $0.sessionDescription.sdp == value.sdp }
            .sink { _ in expectation.fulfill() }
        defer { cancellable?.cancel() }

        _ = try await subject.setLocalDescription(value)

        await safeFulfillment(of: [expectation])
    }

    // MARK: - setRemoteDescription(_:)

    func test_setRemoteDescription_peerConnectionWasCalled() async throws {
        try await subject.setRemoteDescription(.init(type: .answer, sdp: .unique))

        await fulfillment { [mockPeerConnection] in
            mockPeerConnection?.timesCalled(.setRemoteDescription) == 1
        }
    }

    func test_setRemoteDescription_eventWasPublished() async throws {
        let value = RTCSessionDescription(type: .offer, sdp: .unique)
        mockPeerConnection.stub(for: .setRemoteDescription, with: value)

        let expectation = self.expectation(description: "setRemoteDescription was not received.")
        let cancellable: AnyCancellable? = mockPeerConnection
            .publisher
            .compactMap { $0 as? StreamRTCPeerConnection.SetRemoteDescriptionEvent }
            .filter { $0.sessionDescription.sdp == value.sdp }
            .sink { _ in expectation.fulfill() }
        defer { cancellable?.cancel() }

        _ = try await subject.setRemoteDescription(value)

        await safeFulfillment(of: [expectation])
    }

    // MARK: - close

    func test_close_peerConnectionWasCalled() async throws {
        await subject.close()

        XCTAssertEqual(mockPeerConnection?.timesCalled(.close), 1)
    }

    func test_close_eventWasPublished() async throws {
        let expectation = self.expectation(description: "CloseEvent was not received.")
        let cancellable: AnyCancellable? = mockPeerConnection
            .publisher
            .compactMap { $0 as? StreamRTCPeerConnection.CloseEvent }
            .sink { _ in expectation.fulfill() }
        defer { cancellable?.cancel() }

        await subject.close()

        await safeFulfillment(of: [expectation])
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
        let expectedOffer = "useinbandfec=1;\r\n00:11 opus/;\r\n12:13: red/48000/2"

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
        let expectedOffer = "useinbandfec=1;\r\n00:11 opus/;\r\n12:13: red/48000/2"
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

    func test_negotiate_subjectIsPublisher_multipleRequests_callSetPublisherOnSFUOnlyOnce(
    ) async throws {
        _ = subject
        let offerA = RTCSessionDescription(
            type: .offer,
            sdp: "useinbandfec=1;\r\n00:11 opus/;\r\n12:13: red/48000/2l;offerA"
        )
        let offerB = RTCSessionDescription(
            type: .offer,
            sdp: "useinbandfec=1;\r\n00:11 opus/;\r\n12:13: red/48000/2l;offerB"
        )

        mockPeerConnection.stub(
            for: .offer,
            with: StubVariantResultProvider { iteration in
                iteration == 0 ? offerA : offerB
            }
        )

        await withTaskGroup(of: Void.self) { [mockPeerConnection] group in
            group.addTask {
                mockPeerConnection?
                    .subject
                    .send(StreamRTCPeerConnection.ShouldNegotiateEvent())
            }

            group.addTask {
                mockPeerConnection?
                    .subject
                    .send(StreamRTCPeerConnection.ShouldNegotiateEvent())
            }
        }

        await fulfillment { [mockPeerConnection] in
            mockPeerConnection?.timesCalled(.setLocalDescription) == 1
        }

        let expected = [offerA.sdp]
        let recordedInput = try XCTUnwrap(
            mockPeerConnection.recordedInputPayload(
                RTCSessionDescription.self,
                for: .setLocalDescription
            )?.filter { $0.sdp.isEmpty == false }
        )
        var actual: [String] = []
        for item in recordedInput {
            actual.append(item.sdp)
        }

        XCTAssertEqual(actual, expected)
    }

    func test_negotiate_subjectIsPublisher_multipleRequestsExecuteSerially_callSetPublisherOnSFUWithCorrectOfferEveryTime(
    ) async throws {
        _ = subject
        let offerA = RTCSessionDescription(
            type: .offer,
            sdp: "useinbandfec=1;\r\n00:11 opus/;\r\n12:13: red/48000/2l;offerA"
        )
        let offerB = RTCSessionDescription(
            type: .offer,
            sdp: "useinbandfec=1;\r\n00:11 opus/;\r\n12:13: red/48000/2l;offerB"
        )

        mockPeerConnection.stub(
            for: .offer,
            with: StubVariantResultProvider { iteration in
                iteration == 0 ? offerA : offerB
            }
        )

        await withTaskGroup(of: Void.self) { [mockPeerConnection] group in
            group.addTask {
                mockPeerConnection?
                    .subject
                    .send(StreamRTCPeerConnection.ShouldNegotiateEvent())
            }

            group.addTask {
                await self.wait(for: 0.6)
                mockPeerConnection?
                    .subject
                    .send(StreamRTCPeerConnection.ShouldNegotiateEvent())
            }
        }

        await fulfillment { [mockPeerConnection] in
            mockPeerConnection?.timesCalled(.setLocalDescription) == 2
        }

        let expected = [offerA.sdp, offerB.sdp]
        let recordedInput = try XCTUnwrap(
            mockPeerConnection.recordedInputPayload(
                RTCSessionDescription.self,
                for: .setLocalDescription
            )?.filter { $0.sdp.isEmpty == false }
        )
        var actual: [String] = []
        for item in recordedInput {
            actual.append(item.sdp)
        }

        XCTAssertEqual(actual, expected)
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

    // MARK: - restartICE

    // MARK: publisher

    func test_restartICE_subjectIsPublisher_withPublishedTracks_triggersNegotiation() async throws {
        _ = subject
        mockLocalMediaAdapterA.stub(for: .trackInfo, with: [Stream_Video_Sfu_Models_TrackInfo()])

        subject.restartICE()

        await fulfillment { [mockPeerConnection] in
            mockPeerConnection?.timesCalled(.offer) == 1
        }

        XCTAssertEqual(
            mockPeerConnection.recordedInputPayload(
                RTCMediaConstraints.self,
                for: .offer
            )?.first,
            .iceRestartConstraints
        )
    }

    func test_restartICE_subjectIsPublisher_withoutPublishedTracks_doesNotTriggerNegotiation() async throws {
        _ = subject

        subject.restartICE()

        await wait(for: 1)
        XCTAssertEqual(mockPeerConnection?.timesCalled(.offer), 0)
    }

    func test_restartICE_subjectIsPublisher_eventWasPublished() async throws {
        _ = subject
        let expectation = self.expectation(description: "RestartICEEvent was not received.")
        let cancellable: AnyCancellable? = mockPeerConnection
            .publisher
            .compactMap { $0 as? StreamRTCPeerConnection.RestartICEEvent }
            .sink { _ in expectation.fulfill() }
        defer { cancellable?.cancel() }

        subject.restartICE()

        await safeFulfillment(of: [expectation])
    }

    // MARK: subscriber

    func test_restartICE_subjectIsSubscriber_callsRestartICEOnSFU() async throws {
        peerType = .subscriber
        _ = subject

        subject.restartICE()

        await fulfillment { [mockSFUStack] in
            mockSFUStack?.service.iceRestartWasCalledWithRequest?.sessionID == self.sessionId
        }

        XCTAssertEqual(mockSFUStack?.service.iceRestartWasCalledWithRequest?.peerType, .subscriber)
    }

    func test_restartICE_subjectIsSubscriber_eventWasPublished() async throws {
        peerType = .subscriber
        _ = subject
        let expectation = self.expectation(description: "RestartICEEvent was not received.")
        let cancellable: AnyCancellable? = mockPeerConnection
            .publisher
            .compactMap { $0 as? StreamRTCPeerConnection.RestartICEEvent }
            .sink { _ in expectation.fulfill() }
        defer { cancellable?.cancel() }

        subject.restartICE()

        await safeFulfillment(of: [expectation])
    }

    // MARK: - restartICE SFU Event

    // MARK: publisher

    func test_restartICE_subjectIsPublisher_withPublishedTracks_whenSFUEventReceived_triggersNegotiation() async throws {
        _ = subject
        mockLocalMediaAdapterA.stub(for: .trackInfo, with: [Stream_Video_Sfu_Models_TrackInfo()])

        var payload = Stream_Video_Sfu_Event_ICERestart()
        payload.peerType = .publisherUnspecified
        mockSFUStack.receiveEvent(.sfuEvent(.iceRestart(payload)))

        await fulfillment { [mockPeerConnection] in
            mockPeerConnection?.timesCalled(.offer) == 1
        }

        XCTAssertEqual(
            mockPeerConnection.recordedInputPayload(
                RTCMediaConstraints.self,
                for: .offer
            )?.first,
            .iceRestartConstraints
        )
    }

    func test_restartICE_subjectIsPublisher_withoutPublishedTracks_whenSFUEventReceived_doesNotTriggerNegotiation() async throws {
        _ = subject

        var payload = Stream_Video_Sfu_Event_ICERestart()
        payload.peerType = .publisherUnspecified
        mockSFUStack.receiveEvent(.sfuEvent(.iceRestart(payload)))

        await wait(for: 1)
        XCTAssertEqual(mockPeerConnection?.timesCalled(.offer), 0)
    }

    func test_restartICE_subjectIsPublisher_withPublishedTracks_whenSFUEventReceivedWithPeerTypeNonPublisher_doesNotTriggerNegotiation(
    ) async throws {
        _ = subject
        mockLocalMediaAdapterA.stub(for: .trackInfo, with: [Stream_Video_Sfu_Models_TrackInfo()])

        var payload = Stream_Video_Sfu_Event_ICERestart()
        payload.peerType = .subscriber
        mockSFUStack.receiveEvent(.sfuEvent(.iceRestart(payload)))

        await wait(for: 1)
        XCTAssertEqual(mockPeerConnection?.timesCalled(.offer), 0)
    }

    // MARK: subscriber

    func test_restartICE_subjectIsSubscribers_whenSFUEventReceived_callsRestartICEOnSFU() async throws {
        peerType = .subscriber
        _ = subject

        var payload = Stream_Video_Sfu_Event_ICERestart()
        payload.peerType = .subscriber
        mockSFUStack.receiveEvent(.sfuEvent(.iceRestart(payload)))

        await fulfillment { [mockSFUStack] in
            mockSFUStack?.service.iceRestartWasCalledWithRequest?.sessionID == self.sessionId
        }
    }

    func test_restartICE_subjectIsSubscribers_whenSFUEventReceivedWithPeerTypeNonSubscriber_noCallsRestartICEOnSFUHappen(
    ) async throws {
        peerType = .subscriber
        _ = subject

        var payload = Stream_Video_Sfu_Event_ICERestart()
        payload.peerType = .publisherUnspecified
        mockSFUStack.receiveEvent(.sfuEvent(.iceRestart(payload)))

        await wait(for: 1)
        XCTAssertNil(mockSFUStack?.service.iceRestartWasCalledWithRequest)
    }

    // MARK: - Private helpers

    private func simulateConcurrentPeerConnectionSetUp(
        callSettings: CallSettings = .init(),
        ownCapabilities: [OwnCapability] = [],
        setUpDelay: TimeInterval = 0,
        shouldFail: Bool = false,
        _ operation: @escaping @Sendable () async throws -> Void
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
                self.subject.completeSetUp()
            }

            group.addTask {
                try await operation()
            }

            try await group.waitForAll()
        }
    }
}
