//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

class SfuMiddleware: EventMiddleware {
    private let recordingUserId = "recording-egress"
    private let participantsThreshold: Int
    private let sessionID: String
    private let user: User
    private let state: WebRTCClient.State
    private let signalService: Stream_Video_Sfu_Signal_SignalServer
    private var subscriber: PeerConnection?
    private var publisher: PeerConnection?
    var onSocketConnected: (() -> Void)?
    var onParticipantCountUpdated: ((UInt32) -> ())?
    
    init(
        sessionID: String,
        user: User,
        state: WebRTCClient.State,
        signalService: Stream_Video_Sfu_Signal_SignalServer,
        subscriber: PeerConnection? = nil,
        publisher: PeerConnection? = nil,
        participantThreshold: Int
    ) {
        self.sessionID = sessionID
        self.user = user
        self.state = state
        self.signalService = signalService
        self.subscriber = subscriber
        self.publisher = publisher
        participantsThreshold = participantThreshold
    }
    
    func update(subscriber: PeerConnection?) {
        self.subscriber = subscriber
    }
    
    func update(publisher: PeerConnection?) {
        self.publisher = publisher
    }
    
    func handle(event: WrappedEvent) -> WrappedEvent? {
        log.debug("Received an event \(event)")
        Task {
            guard case let .sfuEvent(event) = event else {
                return
            }
            switch event {
            case .subscriberOffer(let event):
                await handleSubscriberEvent(event)
            case .publisherAnswer(_):
                log.warning("Publisher answer event shouldn't be sent")
            case .connectionQualityChanged(let event):
                await handleConnectionQualityChangedEvent(event)
            case .audioLevelChanged(let event):
                await handleAudioLevelsChanged(event)
            case .iceTrickle(let event):
                try await handleICETrickle(event)
            case .changePublishQuality(let event):
                handleChangePublishQualityEvent(event)
            case .participantJoined(let event):
                await handleParticipantJoined(event)
            case .participantLeft(let event):
                await handleParticipantLeft(event)
            case .dominantSpeakerChanged(let event):
                await handleDominantSpeakerChanged(event)
            case .joinResponse(let event):
                onSocketConnected?()
                await loadParticipants(from: event)
            case .healthCheckResponse(let event):
                onParticipantCountUpdated?(event.participantCount.total)
            case .trackPublished(let event):
                await handleTrackPublishedEvent(event)
            case .trackUnpublished(let event):
                await handleTrackUnpublishedEvent(event)
            case .error(let event):
                log.error(event.error.message)
            case .callGrantsUpdated(_):
                log.error("TODO: callGrantsUpdated")
            case .goAway(_):
                log.error("TODO: goAway")
            }
        }
        return event
    }
    
    func cleanUp() {
        onSocketConnected = nil
        onParticipantCountUpdated = nil
    }
    
    private func handleSubscriberEvent(_ event: Stream_Video_Sfu_Event_SubscriberOffer) async {
        do {
            log.debug("Handling subscriber offer")
            let offerSdp = event.sdp
            try await subscriber?.setRemoteDescription(offerSdp, type: .offer)
            let answer = try await subscriber?.createAnswer()
            try await subscriber?.setLocalDescription(answer)
            var sendAnswerRequest = Stream_Video_Sfu_Signal_SendAnswerRequest()
            sendAnswerRequest.sessionID = sessionID
            sendAnswerRequest.peerType = .subscriber
            sendAnswerRequest.sdp = answer?.sdp ?? ""
            log.debug("Sending answer for offer")
            let hostname = signalService.hostname
            try await executeTask(retryPolicy: .fastCheckValue { [weak self] in
                self?.hostnameChanged(hostname) == false
            }) {
                _ = try await signalService.sendAnswer(sendAnswerRequest: sendAnswerRequest)
            }
        } catch {
            log.error("Error handling offer event \(error.localizedDescription)")
        }
    }
    
    private func handleParticipantJoined(_ event: Stream_Video_Sfu_Event_ParticipantJoined) async {
        guard event.participant.userID != recordingUserId else {
            log.debug("Recording user has joined the call")
            return
        }
        let callParticipants = await state.callParticipants
        let showTrack = callParticipants.count < participantsThreshold
        let participant = event.participant.toCallParticipant(showTrack: showTrack)
        await state.update(callParticipant: participant)
        log.debug("Participant \(participant.name) joined the call")
    }
    
    private func handleParticipantLeft(_ event: Stream_Video_Sfu_Event_ParticipantLeft) async {
        guard event.participant.userID != recordingUserId else {
            log.debug("Recording user has left the call")
            return
        }
        let participant = event.participant.toCallParticipant()
        await state.removeCallParticipant(with: participant.id)
        await state.removeTrack(id: participant.trackLookupPrefix ?? participant.id)
        log.debug("Participant \(participant.name) left the call")
        postNotification(
            with: CallNotification.participantLeft,
            userInfo: ["id": participant.id]
        )
    }
    
    private func handleChangePublishQualityEvent(
        _ event: Stream_Video_Sfu_Event_ChangePublishQuality
    ) {
        guard let transceiver = publisher?.transceiver else { return }
        let enabledRids = event.videoSenders.first?.layers
            .filter { $0.active }
            .map(\.name) ?? []
        log.debug("Enabled rids = \(enabledRids)")
        let params = transceiver.sender.parameters
        var updatedEncodings = [RTCRtpEncodingParameters]()
        var changed = false
        log.debug("Current publish quality \(params)")
        for encoding in params.encodings {
            let shouldEnable = enabledRids.contains(encoding.rid ?? UUID().uuidString)
            if shouldEnable && encoding.isActive {
                updatedEncodings.append(encoding)
            } else if !shouldEnable && !encoding.isActive {
                updatedEncodings.append(encoding)
            } else {
                changed = true
                encoding.isActive = shouldEnable
                updatedEncodings.append(encoding)
            }
        }
        if changed {
            log.debug("Updating publish quality with encodings \(updatedEncodings)")
            params.encodings = updatedEncodings
            publisher?.transceiver?.sender.parameters = params
        }
    }
    
    private func handleICETrickle(_ event: Stream_Video_Sfu_Models_ICETrickle) async throws {
        log.debug("Handling ice trickle")
        let peerType = event.peerType
        guard let data = event.iceCandidate.data(
            using: .utf8,
            allowLossyConversion: false
        ) else {
            throw ClientError.Unexpected()
        }
        guard let json = try JSONSerialization.jsonObject(
            with: data,
            options: .mutableContainers
        ) as? [String: Any], let sdp = json["candidate"] as? String else {
            throw ClientError.Unexpected()
        }
        let iceCandidate = RTCIceCandidate(
            sdp: sdp,
            sdpMLineIndex: 0,
            sdpMid: nil
        )
        if peerType == .subscriber, let subscriber = self.subscriber {
            log.debug("Adding ice candidate for the subscriber")
            try await executeTask(retryPolicy: .fastAndSimple) {
                try await subscriber.add(iceCandidate: iceCandidate)
            }
        } else if peerType == .publisherUnspecified, let publisher = self.publisher {
            log.debug("Adding ice candidate for the publisher")
            try await executeTask(retryPolicy: .fastAndSimple) {
                try await publisher.add(iceCandidate: iceCandidate)
            }
        }
    }
    
    private func handleTrackPublishedEvent(_ event: Stream_Video_Sfu_Event_TrackPublished) async {
        let userId = event.sessionID
        log.debug("received track published event for user \(userId)")
        guard let participant = await state.callParticipants[userId] else { return }
        if event.type == .audio {
            let updated = participant.withUpdated(audio: true)
            await state.update(callParticipant: updated)
        } else if event.type == .video {
            let updated = participant.withUpdated(video: true)
            await state.update(callParticipant: updated)
        } else if event.type == .screenShare {
            let updated = participant.withUpdated(screensharing: true)
            await state.update(callParticipant: updated)
        }
    }
    
    private func handleTrackUnpublishedEvent(_ event: Stream_Video_Sfu_Event_TrackUnpublished) async {
        let userId = event.sessionID
        log.debug("received track unpublished event for user \(userId)")
        guard let participant = await state.callParticipants[userId] else { return }
        if event.type == .audio {
            let updated = participant.withUpdated(audio: false)
            await state.update(callParticipant: updated)
        } else if event.type == .video {
            let updated = participant.withUpdated(video: false)
            await state.removeTrack(id: updated.trackLookupPrefix ?? updated.id)
            await state.update(callParticipant: updated)
        } else if event.type == .screenShare {
            let updated = participant
                .withUpdated(screensharing: false)
                .withUpdated(screensharingTrack: nil)
            await state.removeScreensharingTrack(id: updated.trackLookupPrefix ?? updated.id)
            await state.update(callParticipant: updated)
        }
    }
    
    private func handleConnectionQualityChangedEvent(_ event: Stream_Video_Sfu_Event_ConnectionQualityChanged) async {
        guard let connectionQualityInfo = event.connectionQualityUpdates.last else { return }
        let userId = connectionQualityInfo.sessionID
        let participant = await state.callParticipants[userId]
        if let updated = participant?.withUpdated(connectionQuality: connectionQualityInfo.connectionQuality.mapped) {
            await state.update(callParticipant: updated)
        }
    }
    
    private func handleAudioLevelsChanged(_ event: Stream_Video_Sfu_Event_AudioLevelChanged) async {
        let participants = await state.callParticipants
        for level in event.audioLevels {
            let participant = participants[level.sessionID]
            if participant?.isSpeaking != level.isSpeaking || level.isSpeaking == true {
                if let updated = participant?.withUpdated(
                    isSpeaking: level.isSpeaking,
                    audioLevel: level.level
                ) {
                    await state.update(callParticipant: updated)
                }
            }
        }
    }
    
    private func loadParticipants(from response: Stream_Video_Sfu_Event_JoinResponse) async {
        log.debug("Loading participants from joinResponse")
        let participants = response.callState.participants
        // For more than threshold participants, the activation of track is on view appearance.
        let showTrack = participants.count < participantsThreshold
        var temp = [String: CallParticipant]()
        for participant in participants {
            if participant.userID != recordingUserId {
                let mapped = participant.toCallParticipant(showTrack: showTrack)
                temp[mapped.id] = mapped
            }
        }
        await state.update(callParticipants: temp)
    }
    
    private func handleDominantSpeakerChanged(_ event: Stream_Video_Sfu_Event_DominantSpeakerChanged) async {
        let participants = await state.callParticipants
        for (key, participant) in participants {
            if event.sessionID == key {
                let updated = participant.withUpdated(dominantSpeaker: true)
                await state.update(callParticipant: updated)
            } else if participant.isDominantSpeaker {
                let updated = participant.withUpdated(dominantSpeaker: false)
                await state.update(callParticipant: updated)
            }
        }
    }
    
    private func hostnameChanged(_ hostname: String) -> Bool {
        signalService.hostname != hostname
    }
}
