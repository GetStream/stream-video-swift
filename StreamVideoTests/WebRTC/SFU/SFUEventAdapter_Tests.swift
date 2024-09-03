//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class SFUEventAdapter_Tests: XCTestCase, @unchecked Sendable {

    private lazy var mockService: MockSignalServer! = .init()
    private lazy var mockWebSocket: MockWebSocketClient! = .init(webSocketClientType: .sfu)
    private lazy var sfuAdapter: SFUAdapter! = .init(
        signalService: mockService,
        webSocket: mockWebSocket
    )
    private lazy var stateAdapter: WebRTCStateAdapter! = .init(
        user: .dummy(),
        apiKey: .unique,
        callCid: .unique,
        videoConfig: .dummy(),
        rtcPeerConnectionCoordinatorFactory: MockRTCPeerConnectionCoordinatorFactory()
    )
    private lazy var subject: SFUEventAdapter! = .init(
        sfuAdapter: sfuAdapter,
        stateAdapter: stateAdapter
    )

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        await stateAdapter.set(sfuAdapter: sfuAdapter)
        _ = subject
    }

    override func tearDown() {
        subject = nil
        stateAdapter = nil
        sfuAdapter = nil
        mockWebSocket = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_init_givenValidAdapters_whenInitialized_thenNotNil() {
        XCTAssertNotNil(subject)
        XCTAssertIdentical(subject.sfuAdapter as AnyObject, sfuAdapter as AnyObject)
    }

    // MARK: - Event Handling Tests

    // MARK: connectionQualityChanged

    func test_handleConnectionQualityChanged_givenEvent_whenPublished_thenUpdatesParticipantQuality() async throws {
        let participantA = CallParticipant.dummy()
        let participantB = CallParticipant.dummy()
        var event = Stream_Video_Sfu_Event_ConnectionQualityChanged()
        event.connectionQualityUpdates = [participantA, participantB]
            .enumerated()
            .map { entry in
                var connectionQualityInfo = Stream_Video_Sfu_Event_ConnectionQualityInfo()
                connectionQualityInfo.sessionID = entry.element.sessionId
                connectionQualityInfo.connectionQuality = entry.offset == 0 ? .good : .excellent
                return connectionQualityInfo
            }

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.connectionQualityChanged(event)),
            initialState: [participantA, participantB].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) {
            XCTAssertEqual($0[participantA.sessionId]?.connectionQuality, .good)
            XCTAssertEqual($0[participantB.sessionId]?.connectionQuality, .excellent)
        }
    }

    // MARK: audioLevelChanged

    func test_handleAudioLevelChanged_givenEvent_whenPublished_thenUpdatesParticipantAudioProperties() async throws {
        let participantA = CallParticipant.dummy()
        let participantB = CallParticipant.dummy()
        var event = Stream_Video_Sfu_Event_AudioLevelChanged()
        event.audioLevels = [participantA, participantB]
            .enumerated()
            .map { entry in
                var value = Stream_Video_Sfu_Event_AudioLevel()
                value.sessionID = entry.element.sessionId
                value.isSpeaking = entry.offset == 0
                value.level = entry.offset == 0 ? 0.8 : 0.3
                return value
            }

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.audioLevelChanged(event)),
            initialState: [participantA, participantB].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) {
            XCTAssertEqual($0[participantA.sessionId]?.audioLevel, 0.8)
            XCTAssertEqual($0[participantB.sessionId]?.audioLevel, 0)
        }
    }

    // MARK: publishQualityChanged

    func test_handleChangePublishQuality_givenEvent_whenPublished_thenUpdatesPublisherQuality() async throws {
        try await stateAdapter.configurePeerConnections()
        let publisher = await stateAdapter.publisher

        let participantA = CallParticipant.dummy()
        let participantB = CallParticipant.dummy()
        var event = Stream_Video_Sfu_Event_ChangePublishQuality()
        var videoSender = Stream_Video_Sfu_Event_VideoSender()
        var layerSetting = Stream_Video_Sfu_Event_VideoLayerSetting()
        layerSetting.active = true
        layerSetting.name = "q"
        videoSender.layers = [layerSetting]
        event.videoSenders = [videoSender]

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.changePublishQuality(event)),
            initialState: [participantA, participantB].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) { _ in
            let mockPublisher = try XCTUnwrap(publisher as? MockRTCPeerConnectionCoordinator)
            let changePublishQualityCall = try XCTUnwrap(mockPublisher.stubbedFunctionInput[.changePublishQuality]?.first)

            switch changePublishQualityCall {
            case let .changePublishQuality(activeEncodings):
                XCTAssertEqual(activeEncodings, .init(["q"]))
            }
        }
    }

    // MARK: participantJoined

    func test_handleParticipantJoined_givenEventWithUserOtherThanRecordingWithLessThanParticipantsThreshold_whenPublished_thenAddsParticipant(
    ) async throws {
        let participant = CallParticipant.dummy()
        var event = Stream_Video_Sfu_Event_ParticipantJoined()
        event.participant = .init()
        event.participant.userID = participant.sessionId
        event.participant.sessionID = participant.sessionId

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.participantJoined(event)),
            initialState: [.dummy()].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) {
            XCTAssertNotNil($0[participant.sessionId])
            XCTAssertTrue($0[participant.sessionId]?.showTrack ?? false)
        }
    }

    func test_handleParticipantJoined_givenEventWithRecording_whenPublished_thenDoesNotAddParticipant() async throws {
        let participant = CallParticipant.dummy()
        var event = Stream_Video_Sfu_Event_ParticipantJoined()
        event.participant = .init()
        event.participant.userID = "recording-egress"
        event.participant.sessionID = participant.sessionId

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.participantJoined(event)),
            initialState: [.dummy()].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) {
            XCTAssertNil($0[participant.sessionId])
        }
    }

    func test_handleParticipantJoined_givenEventWithUserOtherThanRecordingWithMoreThanParticipantsThreshold_whenPublished_thenAddsParticipant(
    ) async throws {
        let participant = CallParticipant.dummy()
        var event = Stream_Video_Sfu_Event_ParticipantJoined()
        event.participant = .init()
        event.participant.userID = participant.sessionId
        event.participant.sessionID = participant.sessionId

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.participantJoined(event)),
            initialState: [
                .dummy(),
                .dummy(),
                .dummy(),
                .dummy(),
                .dummy(),
                .dummy(),
                .dummy(),
                .dummy(),
                .dummy(),
                .dummy()
            ].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) {
            XCTAssertNotNil($0[participant.sessionId])
            XCTAssertFalse($0[participant.sessionId]?.showTrack ?? true)
        }
    }

    // MARK: participantLeft

    func test_handleParticipantLeft_givenEventWithUserOtherThanRecording_whenPublished_thenRemovesParticipantAndTracks(
    ) async throws {
        let participant = CallParticipant.dummy(trackLookupPrefix: .unique)
        var event = Stream_Video_Sfu_Event_ParticipantLeft()
        event.participant = .init()
        event.participant.userID = participant.sessionId
        event.participant.sessionID = participant.sessionId
        event.participant.trackLookupPrefix = try XCTUnwrap(participant.trackLookupPrefix)

        await stateAdapter.didAddTrack(
            .dummy(
                kind: .audio,
                peerConnectionFactory: await stateAdapter.peerConnectionFactory
            ),
            type: .audio,
            for: participant.sessionId
        )
        await stateAdapter.didAddTrack(
            .dummy(
                kind: .video,
                peerConnectionFactory: await stateAdapter.peerConnectionFactory
            ),
            type: .video,
            for: participant.sessionId
        )
        await stateAdapter.didAddTrack(
            .dummy(
                kind: .screenshare,
                peerConnectionFactory: await stateAdapter.peerConnectionFactory
            ),
            type: .video,
            for: participant.sessionId
        )

        let trackLookupPrefix = try XCTUnwrap(participant.trackLookupPrefix)
        await stateAdapter.didAddTrack(
            .dummy(
                kind: .audio,
                peerConnectionFactory: await stateAdapter.peerConnectionFactory
            ),
            type: .audio,
            for: trackLookupPrefix
        )
        await stateAdapter.didAddTrack(
            .dummy(
                kind: .video,
                peerConnectionFactory: await stateAdapter.peerConnectionFactory
            ),
            type: .video,
            for: trackLookupPrefix
        )
        await stateAdapter.didAddTrack(
            .dummy(
                kind: .screenshare,
                peerConnectionFactory: await stateAdapter.peerConnectionFactory
            ),
            type: .video,
            for: trackLookupPrefix
        )

        let participantLeftNotificationExpectation = expectation(description: "Participant left notification received.")
        let cancellable = NotificationCenter
            .default
            .publisher(for: .init(CallNotification.participantLeft))
            .sink {
                XCTAssertEqual($0.userInfo?["id"] as? String, participant.id)
                participantLeftNotificationExpectation.fulfill()
            }
        _ = cancellable

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.participantLeft(event)),
            initialState: [participant].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) { [trackLookupPrefix] participants in
            XCTAssertTrue(participants.isEmpty)
            let audioTrack = await stateAdapter.track(for: participant.sessionId, of: .audio)
            XCTAssertNil(audioTrack)
            let videoTrack = await stateAdapter.track(for: participant.sessionId, of: .video)
            XCTAssertNil(videoTrack)
            let screenShareTrack = await stateAdapter.track(for: participant.sessionId, of: .screenshare)
            XCTAssertNil(screenShareTrack)

            let prefix_audioTrack = await stateAdapter.track(for: trackLookupPrefix, of: .audio)
            XCTAssertNil(prefix_audioTrack)
            let prefix_videoTrack = await stateAdapter.track(for: trackLookupPrefix, of: .video)
            XCTAssertNil(prefix_videoTrack)
            let prefix_screenShareTrack = await stateAdapter.track(for: trackLookupPrefix, of: .screenshare)
            XCTAssertNil(prefix_screenShareTrack)

            await fulfillment(of: [participantLeftNotificationExpectation], timeout: defaultTimeout)
        }
    }

    func test_handleParticipantLeft_givenEventWithRecordingUser_whenPublished_thenParticipantsAndTracksNotChanging() async throws {
        let participant = CallParticipant.dummy(trackLookupPrefix: .unique)
        var event = Stream_Video_Sfu_Event_ParticipantLeft()
        event.participant = .init()
        event.participant.userID = "recording-egress"
        event.participant.sessionID = participant.sessionId
        event.participant.trackLookupPrefix = try XCTUnwrap(participant.trackLookupPrefix)

        let participantLeftNotificationExpectation = expectation(description: "Participant left notification received.")
        participantLeftNotificationExpectation.isInverted = true
        let cancellable = NotificationCenter
            .default
            .publisher(for: .init(CallNotification.participantLeft))
            .sink { _ in participantLeftNotificationExpectation.fulfill() }
        _ = cancellable

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.participantLeft(event)),
            initialState: [participant].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) { participants in
            XCTAssertFalse(participants.isEmpty)
            await fulfillment(of: [participantLeftNotificationExpectation], timeout: 2)
        }
    }

    // MARK: dominantSpeakerChanged

    func test_handleDominantSpeakerChanged_givenEvent_whenPublished_thenUpdatesDominantSpeaker() async throws {
        let participantA = CallParticipant.dummy()
        let participantB = CallParticipant.dummy(isDominantSpeaker: true)
        var event = Stream_Video_Sfu_Event_DominantSpeakerChanged()
        event.userID = participantA.sessionId
        event.sessionID = participantA.sessionId

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.dominantSpeakerChanged(event)),
            initialState: [participantA, participantB].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) {
            XCTAssertTrue($0[participantA.sessionId]?.isDominantSpeaker ?? false)
            XCTAssertFalse($0[participantB.sessionId]?.isDominantSpeaker ?? false)
        }
    }

    // MARK: joinResponse

    func test_handleJoinResponse_givenEvent_whenPublished_thenUpdatesParticipantsAndPins() async throws {
        var event = Stream_Video_Sfu_Event_JoinResponse()
        event.callState = .init()
        event.callState.participants = [
            .init(.dummy()),
            .init(.dummy()),
            .init(.dummy()),
            .init(.dummy()),
            .init(.dummy()),
            .init(.dummy()),
            .init(.dummy()),
            .init(.dummy()),
            .init(.dummy()),
            .init(.dummy()),
            .init(.dummy(id: "recording-egress")),
            .init(.dummy())
        ]
        try await assert(
            event,
            wrappedEvent: .sfuEvent(.joinResponse(event)),
            initialState: [:]
        ) { participants in
            XCTAssertEqual(participants.count, 11)
            XCTAssertEqual(participants.filter { !$0.value.showTrack }.count, 1)
        }
    }

    // MARK: healthCheckResponse

    func test_handleHealthCheckResponse_givenEvent_whenPublished_thenUpdatesParticipantCounts() async throws {
        var event = Stream_Video_Sfu_Event_HealthCheckResponse()
        event.participantCount = .init()
        event.participantCount.total = 23
        event.participantCount.anonymous = 4

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.healthCheckResponse(event)),
            initialState: [:]
        ) { _ in
            let participantsCount = await stateAdapter.participantsCount
            let anonymousCount = await stateAdapter.anonymousCount
            XCTAssertEqual(participantsCount, 23)
            XCTAssertEqual(anonymousCount, 4)
        }
    }

    // MARK: trackPublished

    func test_handleTrackPublished_givenAudioEvent_whenPublished_thenUpdatesParticipantAudioStatus() async throws {
        let participant = CallParticipant.dummy()
        var event = Stream_Video_Sfu_Event_TrackPublished()
        event.sessionID = participant.sessionId
        event.type = .audio

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.trackPublished(event)),
            initialState: [participant].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) {
            XCTAssertEqual($0.count, 1)
            XCTAssertTrue($0[participant.sessionId]?.hasAudio ?? false)
        }
    }

    func test_handleTrackPublished_givenVideoEvent_whenPublished_thenUpdatesParticipantVideoStatus() async throws {
        let participant = CallParticipant.dummy()
        var event = Stream_Video_Sfu_Event_TrackPublished()
        event.sessionID = participant.sessionId
        event.type = .video

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.trackPublished(event)),
            initialState: [participant].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) {
            XCTAssertEqual($0.count, 1)
            XCTAssertTrue($0[participant.sessionId]?.hasVideo ?? false)
        }
    }

    func test_handleTrackPublished_givenScreenShareEvent_whenPublished_thenUpdatesParticipantScreenShareStatus() async throws {
        let participant = CallParticipant.dummy()
        var event = Stream_Video_Sfu_Event_TrackPublished()
        event.sessionID = participant.sessionId
        event.type = .screenShare

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.trackPublished(event)),
            initialState: [participant].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) {
            XCTAssertEqual($0.count, 1)
            XCTAssertTrue($0[participant.sessionId]?.isScreensharing ?? false)
        }
    }

    // MARK: trackUnpublished

    func test_handleTrackUnpublished_givenAudioEvent_whenPublished_thenUpdatesParticipantAudioStatus() async throws {
        let participant = CallParticipant.dummy(hasAudio: true)
        var event = Stream_Video_Sfu_Event_TrackUnpublished()
        event.sessionID = participant.sessionId
        event.type = .audio

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.trackUnpublished(event)),
            initialState: [participant].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) {
            XCTAssertEqual($0.count, 1)
            XCTAssertFalse($0[participant.sessionId]?.hasAudio ?? true)
        }
    }

    func test_handleTrackUnpublished_givenVideoEvent_whenPublished_thenUpdatesParticipantVideoStatus() async throws {
        let participant = CallParticipant.dummy(hasVideo: true)
        var event = Stream_Video_Sfu_Event_TrackUnpublished()
        event.sessionID = participant.sessionId
        event.type = .video

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.trackUnpublished(event)),
            initialState: [participant].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) {
            XCTAssertEqual($0.count, 1)
            XCTAssertFalse($0[participant.sessionId]?.hasVideo ?? true)
        }
    }

    func test_handleTrackUnpublished_givenScreenShareEvent_whenPublished_thenUpdatesParticipantScreenShareStatus() async throws {
        let participant = CallParticipant.dummy(isScreenSharing: true)
        var event = Stream_Video_Sfu_Event_TrackUnpublished()
        event.sessionID = participant.sessionId
        event.type = .screenShare

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.trackUnpublished(event)),
            initialState: [participant].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) {
            XCTAssertEqual($0.count, 1)
            XCTAssertFalse($0[participant.sessionId]?.isSpeaking ?? true)
        }
    }

    // MARK: pinsChanged

    func test_handlePinsChanged_givenEvent_whenPublished_thenUpdatesPinnedParticipants() async throws {
        let participantA = CallParticipant.dummy()
        let participantB = CallParticipant.dummy()
        var event = Stream_Video_Sfu_Event_PinsChanged()
        event.pins = .init()
        var pinInfo = Stream_Video_Sfu_Models_Pin()
        pinInfo.sessionID = participantA.sessionId
        event.pins = [pinInfo]

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.pinsUpdated(event)),
            initialState: [participantA, participantB].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) {
            XCTAssertNotNil($0[participantA.sessionId]?.pin)
            XCTAssertNil($0[participantB.sessionId]?.pin)
        }
    }

    func test_handlePinsChanged_givenEvent_whenPublished_thenReplacesLocalPinnedParticipants() async throws {
        let participantA = CallParticipant.dummy(pin: .init(isLocal: true, pinnedAt: .init()))
        let participantB = CallParticipant.dummy()
        var event = Stream_Video_Sfu_Event_PinsChanged()
        event.pins = .init()
        var pinInfo = Stream_Video_Sfu_Models_Pin()
        pinInfo.sessionID = participantA.sessionId
        event.pins = [pinInfo]

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.pinsUpdated(event)),
            initialState: [participantA, participantB].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) {
            XCTAssertFalse($0[participantA.sessionId]?.pin?.isLocal ?? true)
            XCTAssertNil($0[participantB.sessionId]?.pin)
        }
    }

    func test_handlePinsChanged_givenEvent_whenPublished_thenRemovesNonLocalPinnedParticipantsThatHaveBeenRemoved() async throws {
        let participantA = CallParticipant.dummy()
        let participantB = CallParticipant.dummy(pin: .init(isLocal: false, pinnedAt: .init()))
        var event = Stream_Video_Sfu_Event_PinsChanged()
        event.pins = .init()
        var pinInfo = Stream_Video_Sfu_Models_Pin()
        pinInfo.sessionID = participantA.sessionId
        event.pins = [pinInfo]

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.pinsUpdated(event)),
            initialState: [participantA, participantB].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) {
            XCTAssertNotNil($0[participantA.sessionId]?.pin)
            XCTAssertNil($0[participantB.sessionId]?.pin)
        }
    }

    // MARK: participantUpdated

    func test_handleParticipantUpdated_givenEvent_whenPublished_thenUpdatesParticipant() async throws {
        let pinnedAt = Date(timeIntervalSince1970: 100)
        let participant = CallParticipant.dummy(showTrack: false, pin: .init(isLocal: true, pinnedAt: pinnedAt))
        var event = Stream_Video_Sfu_Event_ParticipantUpdated()
        let expectedParticipant = CallParticipant.dummy(
            id: participant.id,
            name: participant.name,
            showTrack: false,
            pin: .init(isLocal: true, pinnedAt: pinnedAt)
        )
        event.participant = .init(expectedParticipant)

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.participantUpdated(event)),
            initialState: [participant].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) {
            XCTAssertEqual($0.count, 1)
            XCTAssertEqual($0[expectedParticipant.sessionId], expectedParticipant)
        }
    }

    // MARK: - Private helpers

    private func assert<T>(
        _ event: T,
        wrappedEvent: WrappedEvent,
        initialState: [String: CallParticipant],
        handler: ([String: CallParticipant]) async throws -> Void
    ) async throws {
        await stateAdapter.didUpdateParticipants(initialState)

        let eventExpectation = expectation(description: "Event \(type(of: event)) received.")
        let cancellable = sfuAdapter
            .publisher(eventType: type(of: event))
            .sink { _ in eventExpectation.fulfill() }
        mockWebSocket.eventSubject.send(wrappedEvent)
        await fulfillment(of: [eventExpectation], timeout: defaultTimeout)

        try await handler(await stateAdapter.participants)
    }
}