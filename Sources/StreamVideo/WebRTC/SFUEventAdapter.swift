//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

final class SFUEventAdapter {

    var sfuAdapter: SFUAdapter { didSet { observeEvents() } }
    private let stateAdapter: WebRTCStateAdapter
    private let disposableBag: DisposableBag = .init()
    private let recordingUserId = "recording-egress"
    private let participantsThreshold = 10

    init(
        sfuAdapter: SFUAdapter,
        stateAdapter: WebRTCStateAdapter
    ) {
        self.sfuAdapter = sfuAdapter
        self.stateAdapter = stateAdapter
        observeEvents()
    }

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

    private func handle(
        _ event: Stream_Video_Sfu_Event_ConnectionQualityChanged
    ) async {
        guard
            let connectionQualityInfo = event.connectionQualityUpdates.last
        else {
            return
        }

        let sessionID = connectionQualityInfo.sessionID
        var participants = await stateAdapter.participants
        guard let participant = participants[sessionID] else {
            return
        }

        let updatedParticipant = participant.withUpdated(
            connectionQuality: connectionQualityInfo.connectionQuality.mapped
        )
        participants[sessionID] = updatedParticipant
        await stateAdapter.didUpdateParticipants(participants)
    }

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
        //        stateAdapter.participantsUpdateSubject.send(participants)
        await stateAdapter.didUpdateParticipants(participants)
    }

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

    private func handle(
        _ event: Stream_Video_Sfu_Event_JoinResponse
    ) async {
        let participants = event
            .callState
            .participants
            .filter { $0.userID != recordingUserId }

        // For more than threshold participants, the activation of track is on
        // view appearance.
        let showTrack = participants.count < participantsThreshold
        let pins = event
            .callState
            .pins
            .map(\.sessionID)

        var callParticipants: [String: CallParticipant] = [:]
        for participant in participants {
            let pin: PinInfo? = pins.contains(participant.sessionID)
                ? PinInfo(isLocal: false, pinnedAt: .init())
                : nil

            let callParticipant = participant.toCallParticipant(
                showTrack: showTrack,
                pin: pin
            )
            callParticipants[callParticipant.sessionId] = callParticipant
        }

        await stateAdapter.didUpdateParticipants(callParticipants)
    }

    private func handle(
        _ event: Stream_Video_Sfu_Event_HealthCheckResponse
    ) async {
        await stateAdapter.set(event.participantCount.total)
        await stateAdapter.set(anonymous: event.participantCount.anonymous)
    }

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
