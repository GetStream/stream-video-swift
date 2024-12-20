//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class SFUEventAdapter_Tests: XCTestCase, @unchecked Sendable {

    private static var videoConfig: VideoConfig! = .dummy()

    private lazy var mockService: MockSignalServer! = .init()
    private lazy var mockWebSocket: MockWebSocketClient! = .init(webSocketClientType: .sfu)
    private lazy var sfuAdapter: SFUAdapter! = .init(
        signalService: mockService,
        webSocket: mockWebSocket,
        webSocketFactory: MockWebSocketClientFactory()
    )
    private lazy var stateAdapter: WebRTCStateAdapter! = .init(
        user: .dummy(),
        apiKey: .unique,
        callCid: .unique,
        videoConfig: Self.videoConfig,
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

    override class func tearDown() {
        Self.videoConfig = nil
        super.tearDown()
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
            $0[participantA.sessionId]?.connectionQuality == .good && $0[participantB.sessionId]?.connectionQuality == .excellent
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
            $0[participantA.sessionId]?.audioLevel == 0.8 && $0[participantB.sessionId]?.audioLevel == 0
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
        ) { [event] _ in
            let mockPublisher = try XCTUnwrap(publisher as? MockRTCPeerConnectionCoordinator)
            return mockPublisher
                .recordedInputPayload(Stream_Video_Sfu_Event_ChangePublishQuality.self, for: .changePublishQuality)?
                .first == event
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
            $0[participant.sessionId] != nil && $0[participant.sessionId]?.showTrack == true
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
            $0[participant.sessionId] == nil
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
            $0[participant.sessionId] != nil && $0[participant.sessionId]?.showTrack == false
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
            let audioTrack = await self.stateAdapter.track(for: participant.sessionId, of: .audio)
            let videoTrack = await self.stateAdapter.track(for: participant.sessionId, of: .video)
            let screenShareTrack = await self.stateAdapter.track(for: participant.sessionId, of: .screenshare)
            let prefix_audioTrack = await self.stateAdapter.track(for: trackLookupPrefix, of: .audio)
            let prefix_videoTrack = await self.stateAdapter.track(for: trackLookupPrefix, of: .video)
            let prefix_screenShareTrack = await self.stateAdapter.track(for: trackLookupPrefix, of: .screenshare)

            return screenShareTrack == nil &&
                videoTrack == nil &&
                audioTrack == nil &&
                prefix_audioTrack == nil &&
                prefix_videoTrack == nil &&
                prefix_screenShareTrack == nil
        }
        await fulfillment(of: [participantLeftNotificationExpectation], timeout: defaultTimeout)
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
            participants.isEmpty == false
        }
        await fulfillment(of: [participantLeftNotificationExpectation], timeout: 2)
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
            $0[participantA.sessionId]?.isDominantSpeaker == true
                && $0[participantB.sessionId]?.isDominantSpeaker == false
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
            participants.count == 11
                && participants.filter { !$0.value.showTrack }.count == 1
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
            let participantsCount = await self.stateAdapter.participantsCount
            let anonymousCount = await self.stateAdapter.anonymousCount
            return participantsCount == 23 && anonymousCount == 4
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
            $0.count == 1 && $0[participant.sessionId]?.hasAudio == true
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
            $0.count == 1 && $0[participant.sessionId]?.hasVideo == true
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
            $0.count == 1 && $0[participant.sessionId]?.isScreensharing == true
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
            $0.count == 1 && $0[participant.sessionId]?.hasAudio == false
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
            $0.count == 1 && $0[participant.sessionId]?.hasVideo == false
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
            $0.count == 1 && $0[participant.sessionId]?.isScreensharing == false
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
            $0[participantA.sessionId]?.pin != nil && $0[participantB.sessionId]?.pin == nil
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
            $0[participantA.sessionId]?.pin?.isLocal == false && $0[participantB.sessionId]?.pin == nil
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
            $0[participantA.sessionId]?.pin != nil && $0[participantB.sessionId]?.pin == nil
        }
    }

    // MARK: participantUpdated

    func test_handleParticipantUpdated_givenEvent_whenPublished_thenUpdatesParticipant() async throws {
        let pinnedAt = Date(timeIntervalSince1970: 100)
        let participant = CallParticipant.dummy(showTrack: true, pin: .init(isLocal: true, pinnedAt: pinnedAt))
        var event = Stream_Video_Sfu_Event_ParticipantUpdated()
        let expectedParticipant = CallParticipant.dummy(
            id: participant.id,
            name: participant.name + "_newName",
            showTrack: true,
            audioLevels: [0],
            pin: .init(isLocal: true, pinnedAt: pinnedAt)
        )
        event.participant = .init(expectedParticipant)

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.participantUpdated(event)),
            initialState: [participant].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) {
            $0.count == 1 && $0[expectedParticipant.sessionId] == expectedParticipant
        }
    }

    // MARK: publishOptionsChanged

    func test_handleChangePublishOptions_givenEvent_whenPublished_thenUpdatesPublishOptions() async throws {
        try await stateAdapter.configurePeerConnections()
        let publisher = await stateAdapter.publisher

        let participantA = CallParticipant.dummy()
        let participantB = CallParticipant.dummy()
        var event = Stream_Video_Sfu_Event_ChangePublishOptions()
        var option = Stream_Video_Sfu_Models_PublishOption()
        option.bitrate = 100
        option.codec = .dummy(name: "av1")
        option.trackType = .video
        event.publishOptions = [option]
        event.reason = .unique
        let expected = PublishOptions(event.publishOptions)

        try await assert(
            event,
            wrappedEvent: .sfuEvent(.changePublishOptions(event)),
            initialState: [participantA, participantB].reduce(into: [String: CallParticipant]()) { $0[$1.sessionId] = $1 }
        ) { _ in await self.stateAdapter.publishOptions == expected }
    }

    // MARK: - Private helpers

    private func assert<T>(
        _ event: T,
        wrappedEvent: WrappedEvent,
        initialState: [String: CallParticipant],
        handler: @Sendable @escaping ([String: CallParticipant]) async throws -> Bool
    ) async throws {
        await stateAdapter.enqueue { _ in initialState }
        let eventExpectation = expectation(description: "Event \(type(of: event)) received.")
        let cancellable = sfuAdapter
            .publisher(eventType: type(of: event))
            .sink { _ in eventExpectation.fulfill() }

        /// We add a group that concurrently updates the participants and awaits for an update as internally
        /// the stateAdapter spins up another task to complete the update.
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                self.mockWebSocket.eventSubject.send(wrappedEvent)
                await self.fulfillment(of: [eventExpectation], timeout: defaultTimeout)
            }
            group.addTask {
                _ = try? await self.stateAdapter.$participants.nextValue(
                    timeout: defaultTimeout
                )
            }
            await group.waitForAll()
        }
        cancellable.cancel()

        await fulfillment {
            do {
                return try await handler(await self.stateAdapter.participants)
            } catch {
                return false
            }
        }
    }
}
