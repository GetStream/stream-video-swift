//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A class that adapts SFU (Selective Forwarding Unit) events to the application's state.
final class SFUEventAdapter: @unchecked Sendable {

    /// The SFU adapter instance. Observes events when set.
    var sfuAdapter: SFUAdapter { didSet { observeEvents() } }

    /// The WebRTC state adapter instance.
    private let stateAdapter: WebRTCStateAdapter

    /// A bag to store disposable resources.
    private let disposableBag: DisposableBag = .init()

    /// The user ID used for recording.
    private let recordingUserId = "recording-egress"

    /// The threshold of participants above which certain behaviors change.
    private let participantsThreshold = 10

    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

    var isActive: Bool { !disposableBag.isEmpty }

    /// Initializes a new instance of SFUEventAdapter.
    ///
    /// - Parameters:
    ///   - sfuAdapter: The SFU adapter to use.
    ///   - stateAdapter: The WebRTC state adapter to use.
    init(
        sfuAdapter: SFUAdapter,
        stateAdapter: WebRTCStateAdapter
    ) {
        self.sfuAdapter = sfuAdapter
        self.stateAdapter = stateAdapter
        observeEvents()
    }

    /// Stop event observation. Useful when reconnection, to avoid any unnecessary updates on the UI.
    func stopObserving() {
        disposableBag.removeAll()
    }

    /// Observes various SFU events and sets up handlers for each.
    private func observeEvents() {
        disposableBag.removeAll()

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_ConnectionQualityChanged.self)
            .log(.debug, subsystems: .sfu) {
                "Processing SFU event of type:\($0.name) for userIds:\($0.connectionQualityUpdates.map(\.userID).joined(separator: ","))."
            }
            .sinkTask(queue: processingQueue) { [weak self] in await self?.handleConnectionQualityChanged($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_AudioLevelChanged.self)
            .log(.debug, subsystems: .sfu) {
                "Processing SFU event of type:\($0.name) for userIds:\($0.audioLevels.map(\.userID).joined(separator: ","))."
            }
            .sinkTask(queue: processingQueue) { [weak self] in await self?.handleAudioLevelChanged($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_ChangePublishQuality.self)
            .log(.debug, subsystems: .sfu) {
                "Processing SFU event of type:\($0.name) with \($0.audioSenders.endIndex) audioRenders and \($0.videoSenders.endIndex) videoRenderers."
            }
            .sinkTask(queue: processingQueue) { [weak self] in await self?.handleChangePublishQuality($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_ParticipantJoined.self)
            .log(.debug, subsystems: .sfu) {
                "Processing SFU event of type:\($0.name) on callCid:\($0.callCid) for participant:\($0.participant.name)."
            }
            .sinkTask(queue: processingQueue) { [weak self] in await self?.handleParticipantJoined($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_ParticipantLeft.self)
            .log(.debug, subsystems: .sfu) {
                "Processing SFU event of type:\($0.name) on callCid:\($0.callCid) for participant:\($0.participant.name)."
            }
            .sinkTask(queue: processingQueue) { [weak self] in await self?.handleParticipantLeft($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_DominantSpeakerChanged.self)
            .log(.debug, subsystems: .sfu) { "Processing SFU event of type:\($0.name) for userId:\($0.userID)." }
            .sinkTask(queue: processingQueue) { [weak self] in await self?.handleDominantSpeakerChanged($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_HealthCheckResponse.self)
            .log(.debug, subsystems: .sfu) {
                "Processing SFU event of type:\($0.name) with anonymous:\($0.participantCount.anonymous) total:\($0.participantCount.total)."
            }
            .sinkTask(queue: processingQueue) { [weak self] in await self?.handleHealthCheckResponse($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_TrackPublished.self)
            .log(.debug, subsystems: .sfu) {
                "Processing SFU event of type:\($0.name) for userID:\($0.userID) trackType:\($0.type.rawValue)."
            }
            .sinkTask(queue: processingQueue) { [weak self] in await self?.handleTrackPublished($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_TrackUnpublished.self)
            .log(.debug, subsystems: .sfu) {
                "Processing SFU event of type:\($0.name) for userID:\($0.userID) trackType:\($0.type.rawValue)."
            }
            .sinkTask(queue: processingQueue) { [weak self] in await self?.handleTrackUnpublished($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_PinsChanged.self)
            .log(.debug, subsystems: .sfu) { "Processing SFU event of type:\(type(of: $0))." }
            .sinkTask(queue: processingQueue) { [weak self] in await self?.handlePinsChanged($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_ParticipantUpdated.self)
            .log(.debug, subsystems: .sfu) {
                "Processing SFU event of type:\(type(of: $0)) on callCid:\($0.callCid) participant:\($0.participant.name)."
            }
            .sinkTask(queue: processingQueue) { [weak self] in await self?.handleParticipantUpdated($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_ChangePublishOptions.self)
            .log(.debug, subsystems: .sfu) {
                "Processing SFU event of type:\(type(of: $0)) on callCid:\($0.publishOptions.map(\.trackType.description).joined(separator: ",")) reason:\($0.reason)."
            }
            .sinkTask(queue: processingQueue) { [weak self] in await self?.handleChangePublishOptions($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_InboundStateNotification.self)
            .log(.debug, subsystems: .sfu) {
                "Processing SFU event of type:\(type(of: $0)) for userID:\($0.inboundVideoStates.map { "(userID:\($0.userID) trackType:\(TrackType($0.trackType)) isPaused:\($0.paused))" }.joined(separator: ", "))"
            }
            .sinkTask(queue: processingQueue) { [weak self] in await self?.handleInboundVideoState($0) }
            .store(in: disposableBag)
    }

    // MARK: - Event handlers

    /// Handles a ConnectionQualityChanged event.
    ///
    /// - Parameter event: The ConnectionQualityChanged event to handle.
    /// - Note: The handler will **only** update if the event is for the localParticipant.
    private func handleConnectionQualityChanged(
        _ event: Stream_Video_Sfu_Event_ConnectionQualityChanged
    ) async {
        guard !event.connectionQualityUpdates.isEmpty else {
            return
        }

        await stateAdapter.enqueue { participants in
            var updatedParticipants = participants

            for connectionQualityUpdate in event.connectionQualityUpdates {
                let sessionID = connectionQualityUpdate.sessionID
                guard let participant = updatedParticipants[sessionID] else {
                    continue
                }

                let updatedParticipant = participant.withUpdated(
                    connectionQuality: connectionQualityUpdate.connectionQuality.mapped
                )
                updatedParticipants[sessionID] = updatedParticipant
            }

            return updatedParticipants
        }
    }

    /// Handles an AudioLevelChanged event.
    ///
    /// - Parameter event: The AudioLevelChanged event to handle.
    /// - Note: The handler will update all the participants in the event.
    private func handleAudioLevelChanged(
        _ event: Stream_Video_Sfu_Event_AudioLevelChanged
    ) async {
        await stateAdapter.enqueue { participants in
            var updatedParticipants = participants

            for level in event.audioLevels {
                guard
                    let participant = updatedParticipants[level.sessionID],
                    participant.isSpeaking != level.isSpeaking || level.isSpeaking == true
                else {
                    continue
                }

                updatedParticipants[level.sessionID] = participant.withUpdated(
                    isSpeaking: level.isSpeaking,
                    audioLevel: level.level
                )
            }
            return updatedParticipants
        }
    }

    /// Handles a ChangePublishQuality event.
    ///
    /// - Parameter event: The ChangePublishQuality event to handle.
    private func handleChangePublishQuality(
        _ event: Stream_Video_Sfu_Event_ChangePublishQuality
    ) async {
        await stateAdapter
            .publisher?
            .changePublishQuality(with: event)
    }

    /// Handles a ParticipantJoined event.
    ///
    /// - Parameter event: The ParticipantJoined event to handle.
    /// - Note: The handler will ignore the participant if the userID matches the `recordingUserId`.
    /// Additionally, the `showTrack` property will be set based on the number of the current participants
    /// and the `participantsThreshold`.
    private func handleParticipantJoined(
        _ event: Stream_Video_Sfu_Event_ParticipantJoined
    ) async {
        guard
            event.participant.userID != recordingUserId
        else {
            log.debug("enqueue participant invalid")
            return
        }

        log.debug("Will enqueue participant joined event: \(event.participant.name)")
        await stateAdapter.enqueue { [participantsThreshold] participants in
            var updatedParticipants = participants

            guard updatedParticipants[event.participant.sessionID] == nil else {
                log.debug("enqueue participant failed, already exist: \(event.participant.name)")
                return participants
            }

            let showTrack = updatedParticipants.count < participantsThreshold
            let participant = event.participant.toCallParticipant()
                .withUpdated(showTrack: showTrack)
            updatedParticipants[event.participant.sessionID] = participant
            log.debug("Enqueue participant joined event: \(event.participant.name) success!")

            return updatedParticipants
        }
    }

    /// Handles a ParticipantLeft event.
    ///
    /// - Parameter event: The ParticipantLeft event to handle.
    /// - Note: The handler will also post a notification with name `CallNotification.participantLeft`.
    /// ignoring the user if the `userId` matches the `recordingUserId`.
    private func handleParticipantLeft(
        _ event: Stream_Video_Sfu_Event_ParticipantLeft
    ) async {
        guard
            event.participant.userID != recordingUserId
        else {
            return
        }
        let participant = event.participant.toCallParticipant()

        await stateAdapter.enqueue { participants in
            var updatedParticipants = participants

            if updatedParticipants[participant.sessionId] != nil {
                updatedParticipants[participant.sessionId] = nil
            }

            return updatedParticipants
        }

        await stateAdapter.didRemoveTrack(for: participant.sessionId)
        if let trackLookupPrefix = participant.trackLookupPrefix {
            await stateAdapter.didRemoveTrack(for: trackLookupPrefix)
        }

        postNotification(
            with: CallNotification.participantLeft,
            userInfo: ["id": participant.id]
        )
    }

    /// Handles a DominantSpeakerChanged event.
    ///
    /// - Parameter event: The DominantSpeakerChanged event to handle.
    /// - Note: The handler will set the participant in the event as dominant speaker and every other
    /// participant in the call as not.
    private func handleDominantSpeakerChanged(
        _ event: Stream_Video_Sfu_Event_DominantSpeakerChanged
    ) async {
        await stateAdapter.enqueue { participants in
            participants.reduce(into: [String: CallParticipant]()) { partialResult, entry in
                partialResult[entry.key] = entry
                    .value
                    .withUpdated(dominantSpeaker: event.sessionID == entry.key)
            }
        }
    }

    /// Handles a HealthCheckResponse event and updates the `participantCount` and the
    /// `anonymousParticipantCount`.
    ///
    /// - Parameter event: The HealthCheckResponse event to handle.
    private func handleHealthCheckResponse(
        _ event: Stream_Video_Sfu_Event_HealthCheckResponse
    ) async {
        await stateAdapter.set(participantsCount: event.participantCount.total)
        await stateAdapter.set(anonymousCount: event.participantCount.anonymous)
    }

    /// Handles a TrackPublished event.
    ///
    /// - Parameter event: The TrackPublished event to handle.
    private func handleTrackPublished(
        _ event: Stream_Video_Sfu_Event_TrackPublished
    ) async {
        let sessionID = event.sessionID

        await stateAdapter.enqueue { participants in
            var updatedParticipants = participants

            let participant = updatedParticipants[sessionID] ?? event.participant.toCallParticipant()

            switch event.type {
            case .audio:
                updatedParticipants[sessionID] = participant.withUpdated(audio: true)
                log.debug(
                    """
                    AudioTrack was published
                    name: \(participant.name)
                    """,
                    subsystems: .webRTC
                )

            case .video:
                updatedParticipants[sessionID] = participant.withUpdated(video: true)
                log.debug(
                    """
                    VideoTrack was published
                    name: \(participant.name)
                    """,
                    subsystems: .webRTC
                )

            case .screenShare:
                updatedParticipants[sessionID] = participant
                    .withUpdated(screensharing: true)
                log.debug(
                    """
                    ScreenShareTrack was published
                    name: \(participant.name)
                    """,
                    subsystems: .webRTC
                )

            default:
                break
            }

            if event.hasParticipant, let participant = updatedParticipants[sessionID] {
                updatedParticipants[sessionID] = participant
                    .withUpdated(trackLookupPrefix: event.participant.trackLookupPrefix)
            }

            return updatedParticipants
        }
    }

    /// Handles a TrackUnpublished event.
    ///
    /// - Parameter event: The TrackUnpublished event to handle.
    private func handleTrackUnpublished(
        _ event: Stream_Video_Sfu_Event_TrackUnpublished
    ) async {
        let sessionID = event.sessionID

        await stateAdapter.enqueue { participants in
            var updatedParticipants = participants

            let participant = updatedParticipants[sessionID] ?? event.participant.toCallParticipant()

            switch event.type {
            case .audio:
                updatedParticipants[sessionID] = participant
                    .withUpdated(audio: false)
                    .withUnpausedTrack(.audio)
                log.debug(
                    """
                    AudioTrack was unpublished
                    name: \(participant.name)
                    cause: \(event.cause)
                    """,
                    subsystems: .webRTC
                )

            case .video:
                updatedParticipants[sessionID] = participant
                    .withUpdated(video: false)
                    .withUnpausedTrack(.video)
                log.debug(
                    """
                    VideoTrack was unpublished
                    name: \(participant.name)
                    cause: \(event.cause)
                    """,
                    subsystems: .webRTC
                )

            case .screenShare:
                updatedParticipants[sessionID] = participant
                    .withUpdated(screensharing: false)
                    .withUpdated(screensharingTrack: nil)
                    .withUnpausedTrack(.screenshare)
                log.debug(
                    """
                    ScreenShareTrack was unpublished
                    name: \(participant.name)
                    cause: \(event.cause)
                    """,
                    subsystems: .webRTC
                )

            default:
                break
            }

            if event.hasParticipant, let participant = updatedParticipants[sessionID] {
                updatedParticipants[sessionID] = participant
                    .withUpdated(trackLookupPrefix: event.participant.trackLookupPrefix)
            }

            return updatedParticipants
        }

        await stateAdapter.updateCallSettings(from: event)
    }

    /// Handles a PinsChanged event.
    ///
    /// - Parameter event: The PinsChanged event to handle.
    private func handlePinsChanged(
        _ event: Stream_Video_Sfu_Event_PinsChanged
    ) async {
        await stateAdapter.enqueue { participants in
            var updatedParticipants = participants
            let sessionIds = event.pins.map(\.sessionID)

            for (key, participant) in updatedParticipants {
                if
                    sessionIds.contains(key),
                    (participant.pin == nil || participant.pin?.isLocal == true) {
                    updatedParticipants[key] = participant
                        .withUpdated(pin: .init(isLocal: false, pinnedAt: .init()))
                } else {
                    updatedParticipants[key] = participant.withUpdated(pin: nil)
                }
            }

            return updatedParticipants
        }
    }

    /// Handles a ParticipantUpdated event.
    ///
    /// - Parameter event: The ParticipantUpdated event to handle.
    private func handleParticipantUpdated(
        _ event: Stream_Video_Sfu_Event_ParticipantUpdated
    ) async {
        await stateAdapter.enqueue { participants in
            var updatedParticipants = participants

            if let participant = updatedParticipants[event.participant.sessionID] {
                updatedParticipants[event.participant.sessionID] = event
                    .participant
                    .toCallParticipant()
                    .withUpdated(showTrack: participant.showTrack)
                    .withUpdated(pin: participant.pin)
                    .withUpdated(track: participant.track)
                    .withUpdated(screensharingTrack: participant.screenshareTrack)
            } else {
                updatedParticipants[event.participant.sessionID] = event
                    .participant
                    .toCallParticipant()
            }

            return updatedParticipants
        }
    }

    /// Handles a ChangePublishOptions event.
    ///
    /// - Parameter event: The ChangePublishOptions event to handle.
    private func handleChangePublishOptions(
        _ event: Stream_Video_Sfu_Event_ChangePublishOptions
    ) async {
        await stateAdapter
            .set(publishOptions: .init(event.publishOptions))
    }

    /// Handles an InboundStateNotification event and updates paused track state.
    ///
    /// - Parameter event: The InboundStateNotification event to handle.
    ///
    /// This event is sent by the SFU to indicate whether a track (e.g., video,
    /// screenshare) for a given participant is paused or resumed. The method
    /// updates the corresponding participant's state accordingly.
    private func handleInboundVideoState(
        _ event: Stream_Video_Sfu_Event_InboundStateNotification
    ) async {
        await stateAdapter.enqueue { participants in
            var updatedParticipants = participants

            for inboundVideoState in event.inboundVideoStates {
                let trackType = TrackType(inboundVideoState.trackType)
                guard
                    let participant = updatedParticipants[inboundVideoState.sessionID],
                    trackType != .unknown
                else {
                    continue
                }

                var updatedParticipant = participant
                if inboundVideoState.paused {
                    updatedParticipant = participant.withPausedTrack(trackType)
                } else {
                    updatedParticipant = participant.withUnpausedTrack(trackType)
                }

                updatedParticipants[inboundVideoState.sessionID] = updatedParticipant
            }

            return updatedParticipants
        }
    }
}
