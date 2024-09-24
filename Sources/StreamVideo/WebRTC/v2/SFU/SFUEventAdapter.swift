//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A class that adapts SFU (Selective Forwarding Unit) events to the application's state.
final class SFUEventAdapter {

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
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.handleConnectionQualityChanged($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_AudioLevelChanged.self)
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.handleAudioLevelChanged($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_ChangePublishQuality.self)
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.handleChangePublishQuality($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_ParticipantJoined.self)
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.handleParticipantJoined($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_ParticipantLeft.self)
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.handleParticipantLeft($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_DominantSpeakerChanged.self)
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.handleDominantSpeakerChanged($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_JoinResponse.self)
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.handleJoinResponse($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_HealthCheckResponse.self)
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.handleHealthCheckResponse($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_TrackPublished.self)
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.handleTrackPublished($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_TrackUnpublished.self)
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.handleTrackUnpublished($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_PinsChanged.self)
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.handlePinsChanged($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_ParticipantUpdated.self)
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.handleParticipantUpdated($0) }
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

        await stateAdapter.performParticipantOperation { participants in
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
        await stateAdapter.performParticipantOperation { participants in
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
        guard
            let enabledRIds = event
                .videoSenders
                .first?
                .layers
                .filter(\.active)
                .map(\.name)
        else {
            return
        }

        await stateAdapter
            .publisher?
            .changePublishQuality(with: .init(enabledRIds))
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
            return
        }

        await stateAdapter.performParticipantOperation { [participantsThreshold] participants in
            var updatedParticipants = participants

            guard updatedParticipants[event.participant.sessionID] == nil else {
                return participants
            }

            let showTrack = updatedParticipants.count < participantsThreshold
            updatedParticipants[event.participant.sessionID] = event
                .participant
                .toCallParticipant()
                .withUpdated(showTrack: showTrack)

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

        await stateAdapter.performParticipantOperation { participants in
            var updatedParticipants = participants

            if updatedParticipants[event.participant.sessionID] != nil {
                updatedParticipants[event.participant.sessionID] = nil
            }

            return updatedParticipants
        }
        await stateAdapter.didRemoveTrack(for: event.participant.sessionID)
        if !event.participant.trackLookupPrefix.isEmpty {
            await stateAdapter.didRemoveTrack(for: event.participant.trackLookupPrefix)
        }

        postNotification(
            with: CallNotification.participantLeft,
            userInfo: ["id": event.participant.userID]
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
        await stateAdapter.performParticipantOperation { participants in
            var updatedParticipants = participants

            for (key, participant) in updatedParticipants {
                updatedParticipants[key] = participant
                    .withUpdated(dominantSpeaker: event.sessionID == key)
            }

            return updatedParticipants
        }
    }

    /// Handles a JoinResponse event.
    ///
    /// - Parameter event: The JoinResponse event to handle.
    private func handleJoinResponse(
        _ event: Stream_Video_Sfu_Event_JoinResponse
    ) async {
        let participants = event
            .callState
            .participants
            .filter { $0.userID != recordingUserId }

        // For more than threshold participants, the activation of track is on
        // view appearance.
        let pins = event
            .callState
            .pins
            .map(\.sessionID)

        var callParticipants: [String: CallParticipant] = [:]
        for (index, participant) in participants.enumerated() {
            let pin: PinInfo? = pins.contains(participant.sessionID)
            ? PinInfo(isLocal: false, pinnedAt: .init())
            : nil

            let callParticipant = participant.toCallParticipant(
                showTrack: index < participantsThreshold,
                pin: pin
            )
            callParticipants[callParticipant.sessionId] = callParticipant
        }

        await stateAdapter.performParticipantOperation { [callParticipants] _ in
            callParticipants
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
        await stateAdapter.performParticipantOperation { participants in
            var updatedParticipants = participants

            guard let participant = participants[sessionID] else {
                return participants
            }

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
        await stateAdapter.performParticipantOperation { participants in
            var updatedParticipants = participants

            guard let participant = participants[sessionID] else {
                return participants
            }

            switch event.type {
            case .audio:
                updatedParticipants[sessionID] = participant.withUpdated(audio: false)
                log.debug(
                """
                AudioTrack was unpublished
                name: \(participant.name)
                cause: \(event.cause)
                """,
                subsystems: .webRTC
                )


            case .video:
                updatedParticipants[sessionID] = participant.withUpdated(video: false)
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

            return updatedParticipants
        }
    }

    /// Handles a PinsChanged event.
    ///
    /// - Parameter event: The PinsChanged event to handle.
    private func handlePinsChanged(
        _ event: Stream_Video_Sfu_Event_PinsChanged
    ) async {
        await stateAdapter.performParticipantOperation { participants in
            var updatedParticipants = participants
            let sessionIds = event.pins.map(\.sessionID)

            for (key, participant) in updatedParticipants {
                if
                    sessionIds.contains(key),
                    (participant.pin == nil || participant.pin?.isLocal == true)
                {
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
        await stateAdapter.performParticipantOperation { participants in
            var updatedParticipants = participants

            guard
                let participant = updatedParticipants[event.participant.sessionID]
            else {
                return participants
            }

            updatedParticipants[event.participant.sessionID] = event
                .participant
                .toCallParticipant()
                .withUpdated(showTrack: participant.showTrack)
                .withUpdated(pin: participant.pin)

            return updatedParticipants
        }
    }
}
