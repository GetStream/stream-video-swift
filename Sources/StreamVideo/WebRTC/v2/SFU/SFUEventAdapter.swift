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

    /// Observes various SFU events and sets up handlers for each.
    private func observeEvents() {
        disposableBag.removeAll()

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_ConnectionQualityChanged.self)
            .sinkTask { [weak self] in await self?.handle($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_AudioLevelChanged.self)
            .sinkTask { [weak self] in await self?.handle($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_ChangePublishQuality.self)
            .sinkTask { [weak self] in await self?.handle($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_ParticipantJoined.self)
            .sinkTask { [weak self] in await self?.handle($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_ParticipantLeft.self)
            .sinkTask { [weak self] in await self?.handle($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_DominantSpeakerChanged.self)
            .sinkTask { [weak self] in await self?.handle($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_JoinResponse.self)
            .sinkTask { [weak self] in await self?.handle($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_HealthCheckResponse.self)
            .sinkTask { [weak self] in await self?.handle($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_TrackPublished.self)
            .sinkTask { [weak self] in await self?.handle($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_TrackUnpublished.self)
            .sinkTask { [weak self] in await self?.handle($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_PinsChanged.self)
            .sinkTask { [weak self] in await self?.handle($0) }
            .store(in: disposableBag)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_ParticipantUpdated.self)
            .sinkTask { [weak self] in await self?.handle($0) }
            .store(in: disposableBag)
    }

    // MARK: - Event handlers

    /// Handles a ConnectionQualityChanged event.
    ///
    /// - Parameter event: The ConnectionQualityChanged event to handle.
    /// - Note: The handler will **only** update if the event is for the localParticipant.
    private func handle(
        _ event: Stream_Video_Sfu_Event_ConnectionQualityChanged
    ) async {
        guard !event.connectionQualityUpdates.isEmpty else {
            return
        }

        var updatedParticipants = await stateAdapter.participants
        for connectionQualityUpdate in event.connectionQualityUpdates {
            let sessionID = connectionQualityUpdate.sessionID
            guard let participant = updatedParticipants[sessionID] else {
                return
            }

            let updatedParticipant = participant.withUpdated(
                connectionQuality: connectionQualityUpdate.connectionQuality.mapped
            )
            updatedParticipants[sessionID] = updatedParticipant
        }
        await stateAdapter.didUpdateParticipants(updatedParticipants)
    }

    /// Handles an AudioLevelChanged event.
    ///
    /// - Parameter event: The AudioLevelChanged event to handle.
    /// - Note: The handler will update all the participants in the event.
    private func handle(
        _ event: Stream_Video_Sfu_Event_AudioLevelChanged
    ) async {
        var participants = await stateAdapter.participants
        for level in event.audioLevels {
            guard
                let participant = participants[level.sessionID],
                participant.isSpeaking != level.isSpeaking || level.isSpeaking == true
            else {
                continue
            }

            participants[level.sessionID] = participant.withUpdated(
                isSpeaking: level.isSpeaking,
                audioLevel: level.level
            )
        }
        await stateAdapter.didUpdateParticipants(participants)
    }

    /// Handles a ChangePublishQuality event.
    ///
    /// - Parameter event: The ChangePublishQuality event to handle.
    private func handle(
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
    private func handle(
        _ event: Stream_Video_Sfu_Event_ParticipantJoined
    ) async {
        guard
            event.participant.userID != recordingUserId
        else {
            return
        }

        var participants = await stateAdapter.participants
        guard participants[event.participant.sessionID] == nil else {
            return
        }

        let showTrack = participants.count < participantsThreshold
        let participant = (participants[event.participant.sessionID] ?? event.participant.toCallParticipant())
            .withUpdated(showTrack: showTrack)
        participants[event.participant.sessionID] = participant
        await stateAdapter.didUpdateParticipants(participants)
    }

    /// Handles a ParticipantLeft event.
    ///
    /// - Parameter event: The ParticipantLeft event to handle.
    /// - Note: The handler will also post a notification with name `CallNotification.participantLeft`.
    /// ignoring the user if the `userId` matches the `recordingUserId`.
    private func handle(
        _ event: Stream_Video_Sfu_Event_ParticipantLeft
    ) async {
        guard
            event.participant.userID != recordingUserId
        else {
            return
        }
        let participant = event.participant.toCallParticipant()
        var participants = await stateAdapter.participants
        if participants[participant.sessionId] != nil {
            participants[participant.sessionId] = nil
            await stateAdapter.didUpdateParticipants(participants)
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
    private func handle(
        _ event: Stream_Video_Sfu_Event_DominantSpeakerChanged
    ) async {
        var participants = await stateAdapter.participants
        for (key, participant) in participants {
            participants[key] = participant
                .withUpdated(dominantSpeaker: event.sessionID == key)
        }
        await stateAdapter.didUpdateParticipants(participants)
    }

    /// Handles a JoinResponse event.
    ///
    /// - Parameter event: The JoinResponse event to handle.
    private func handle(
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

        await stateAdapter.didUpdateParticipants(callParticipants)
    }

    /// Handles a HealthCheckResponse event and updates the `participantCount` and the
    /// `anonymousParticipantCount`.
    ///
    /// - Parameter event: The HealthCheckResponse event to handle.
    private func handle(
        _ event: Stream_Video_Sfu_Event_HealthCheckResponse
    ) async {
        await stateAdapter.set(event.participantCount.total)
        await stateAdapter.set(anonymous: event.participantCount.anonymous)
    }

    /// Handles a TrackPublished event.
    ///
    /// - Parameter event: The TrackPublished event to handle.
    private func handle(
        _ event: Stream_Video_Sfu_Event_TrackPublished
    ) async {
        let sessionID = event.sessionID
        var participants = await stateAdapter.participants

        guard let participant = participants[sessionID] else {
            return
        }

        switch event.type {
        case .audio:
            participants[sessionID] = participant.withUpdated(audio: true)
            log.debug(
                """
                AudioTrack was published
                name: \(participant.name)
                """,
                subsystems: .webRTC
            )
            await stateAdapter.didUpdateParticipants(participants)
        case .video:
            participants[sessionID] = participant.withUpdated(video: true)
            log.debug(
                """
                VideoTrack was published
                name: \(participant.name)
                """,
                subsystems: .webRTC
            )
            await stateAdapter.didUpdateParticipants(participants)
        case .screenShare:
            participants[sessionID] = participant
                .withUpdated(screensharing: true)
            log.debug(
                """
                ScreenShareTrack was published
                name: \(participant.name)
                """,
                subsystems: .webRTC
            )
            await stateAdapter.didUpdateParticipants(participants)
        default:
            break
        }
    }

    /// Handles a TrackUnpublished event.
    ///
    /// - Parameter event: The TrackUnpublished event to handle.
    private func handle(
        _ event: Stream_Video_Sfu_Event_TrackUnpublished
    ) async {
        let sessionID = event.sessionID
        var participants = await stateAdapter.participants

        guard let participant = participants[sessionID] else {
            return
        }

        switch event.type {
        case .audio:
            participants[sessionID] = participant.withUpdated(audio: false)
            log.debug(
                """
                AudioTrack was unpublished
                name: \(participant.name)
                cause: \(event.cause)
                """,
                subsystems: .webRTC
            )
            await stateAdapter.didUpdateParticipants(participants)

        case .video:
            participants[sessionID] = participant.withUpdated(video: false)
            log.debug(
                """
                VideoTrack was unpublished
                name: \(participant.name)
                cause: \(event.cause)
                """,
                subsystems: .webRTC
            )
            await stateAdapter.didUpdateParticipants(participants)

        case .screenShare:
            participants[sessionID] = participant
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
            await stateAdapter.didUpdateParticipants(participants)

        default:
            break
        }
    }

    /// Handles a PinsChanged event.
    ///
    /// - Parameter event: The PinsChanged event to handle.
    private func handle(
        _ event: Stream_Video_Sfu_Event_PinsChanged
    ) async {
        var participants = await stateAdapter.participants
        let sessionIds = event.pins.map(\.sessionID)

        for (key, participant) in participants {
            if
                sessionIds.contains(key),
                (participant.pin == nil || participant.pin?.isLocal == true)
            {
                participants[key] = participant
                    .withUpdated(pin: .init(isLocal: false, pinnedAt: .init()))
            } else {
                participants[key] = participant.withUpdated(pin: nil)
            }
        }

        await stateAdapter.didUpdateParticipants(participants)
    }

    /// Handles a ParticipantUpdated event.
    ///
    /// - Parameter event: The ParticipantUpdated event to handle.
    private func handle(
        _ event: Stream_Video_Sfu_Event_ParticipantUpdated
    ) async {
        var participants = await stateAdapter.participants
        let existingEntry = participants[event.participant.sessionID]
        let participant = (existingEntry ?? event.participant.toCallParticipant())
            .withUpdated(showTrack: existingEntry?.showTrack ?? true)
            .withUpdated(pin: existingEntry?.pin)
        participants[event.participant.sessionID] = participant
        await stateAdapter.didUpdateParticipants(participants)
    }
}
