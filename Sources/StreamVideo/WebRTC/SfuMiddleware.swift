//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import WebRTC

class SfuMiddleware: EventMiddleware {
    private let participantsThreshold = 4
    private let sessionID: String
    private let userInfo: UserInfo
    private let state: WebRTCClient.State
    private let signalService: Stream_Video_Sfu_Signal_SignalServer
    private var subscriber: PeerConnection?
    private var publisher: PeerConnection?
    var onParticipantEvent: ((ParticipantEvent) -> Void)?
    
    init(
        sessionID: String,
        userInfo: UserInfo,
        state: WebRTCClient.State,
        signalService: Stream_Video_Sfu_Signal_SignalServer,
        subscriber: PeerConnection? = nil,
        publisher: PeerConnection? = nil,
        onParticipantEvent: ((ParticipantEvent) -> Void)? = nil
    ) {
        self.sessionID = sessionID
        self.userInfo = userInfo
        self.state = state
        self.signalService = signalService
        self.subscriber = subscriber
        self.publisher = publisher
        self.onParticipantEvent = onParticipantEvent
    }
    
    func update(subscriber: PeerConnection?) {
        self.subscriber = subscriber
    }
    
    func update(publisher: PeerConnection?) {
        self.publisher = publisher
    }
    
    func handle(event: Event) -> Event? {
        log.debug("Received an event \(event)")
        Task {
            if let event = event as? Stream_Video_Sfu_Event_SubscriberOffer {
                await handleSubscriberEvent(event)
            } else if let event = event as? Stream_Video_Sfu_Event_ParticipantJoined {
                await handleParticipantJoined(event)
            } else if let event = event as? Stream_Video_Sfu_Event_ParticipantLeft {
                await handleParticipantLeft(event)
            } else if let event = event as? Stream_Video_Sfu_Event_ChangePublishQuality {
                handleChangePublishQualityEvent(event)
            } else if let event = event as? Stream_Video_Sfu_Event_DominantSpeakerChanged {
                await handleDominantSpeakerChanged(event)
            } else if let event = event as? Stream_Video_Sfu_Event_MuteStateChanged {
                await handleMuteStateChangedEvent(event)
            } else if let event = event as? Stream_Video_Sfu_Models_ICETrickle {
                try await handleICETrickle(event)
            } else if let event = event as? Stream_Video_Sfu_Event_JoinResponse {
                await loadParticipants(from: event)
            }
        }
        return event
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
            _ = try await signalService.sendAnswer(sendAnswerRequest: sendAnswerRequest)
        } catch {
            log.error("Error handling offer event \(error.localizedDescription)")
        }
    }
    
    private func handleParticipantJoined(_ event: Stream_Video_Sfu_Event_ParticipantJoined) async {
        let callParticipants = await state.callParticipants
        let showTrack = (callParticipants.count + 1) < participantsThreshold
        let participant = event.participant.toCallParticipant(showTrack: showTrack)
        await state.update(callParticipant: participant)
        let event = ParticipantEvent(
            id: participant.id,
            action: .join,
            user: participant.name,
            imageURL: participant.profileImageURL
        )
        log.debug("Participant \(participant.name) joined the call")
        onParticipantEvent?(event)
    }
    
    private func handleParticipantLeft(_ event: Stream_Video_Sfu_Event_ParticipantLeft) async {
        let participant = event.participant.toCallParticipant()
        await state.removeCallParticipant(with: participant.id)
        let event = ParticipantEvent(
            id: participant.id,
            action: .leave,
            user: participant.name,
            imageURL: participant.profileImageURL
        )
        log.debug("Participant \(participant.name) left the call")
        onParticipantEvent?(event)
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
        ) as? [String: Any], let sdp = json["sdp"] as? String else {
            throw ClientError.Unexpected()
        }
        let iceCandidate = RTCIceCandidate(
            sdp: sdp,
            sdpMLineIndex: 0,
            sdpMid: nil
        )
        if peerType == .subscriber, let subscriber = self.subscriber {
            log.debug("Adding ice candidate for the subscriber")
            subscriber.add(iceCandidate: iceCandidate)
        } else if peerType == .publisherUnspecified, let publisher = self.publisher {
            log.debug("Adding ice candidate for the publisher")
            publisher.add(iceCandidate: iceCandidate)
        }
    }
    
    private func handleDominantSpeakerChanged(_ event: Stream_Video_Sfu_Event_DominantSpeakerChanged) async {
        let userId = event.userID
        var temp = [String: CallParticipant]()
        let callParticipants = await state.callParticipants
        for (key, participant) in callParticipants {
            let updated: CallParticipant
            if key == userId {
                updated = participant.withUpdated(
                    layoutPriority: .high,
                    isDominantSpeaker: true
                )
                log.debug("Participant \(participant.name) is the dominant speaker")
                resetDominantSpeaker(participant)
            } else {
                updated = participant.withUpdated(
                    layoutPriority: .normal,
                    isDominantSpeaker: false
                )
            }
            temp[key] = updated
        }
        await state.update(callParticipants: temp)
    }
    
    private func resetDominantSpeaker(_ participant: CallParticipant) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self = self else { return }
            let updated = participant.withUpdated(
                layoutPriority: .normal,
                isDominantSpeaker: false
            )
            Task {
                await self.state.update(callParticipant: updated)
            }
        }
    }
    
    private func handleMuteStateChangedEvent(_ event: Stream_Video_Sfu_Event_MuteStateChanged) async {
        let userId = event.userID
        guard let participant = await state.callParticipants[userId] else { return }
        var updated = participant.withUpdated(audio: !event.audioMuted)
        updated = updated.withUpdated(video: !event.videoMuted)
        await state.update(callParticipant: updated)
    }
    
    private func loadParticipants(from response: Stream_Video_Sfu_Event_JoinResponse) async {
        log.debug("Loading participants from joinResponse")
        let participants = response.callState.participants
        // For more than threshold participants, the activation of track is on view appearance.
        let showTrack = participants.count < participantsThreshold
        var temp = [String: CallParticipant]()
        for participant in participants {
            temp[participant.user.id] = participant.toCallParticipant(showTrack: showTrack)
        }
        await state.update(callParticipants: temp)
    }
}
