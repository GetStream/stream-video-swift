//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

public class CallController {
    
    private let webRTCClient: WebRTCClient
    private(set) var room: Room?
    private let userInfo: UserInfo
    private let callId: String
    private let callType: CallType
    
    init(
        webRTCClient: WebRTCClient,
        userInfo: UserInfo,
        callId: String,
        callType: CallType
    ) {
        self.webRTCClient = webRTCClient
        self.userInfo = userInfo
        self.callId = callId
        self.callType = callType
        handleLocalTrackUpdate()
        handleRemoteStreamAdded()
        handleRemoteStreamRemoved()
        handleParticipantsUpdated()
        handleParticipantEvent()
    }
    
    public func testSFU(callSettings: CallSettings) async throws -> Room? {
        try await webRTCClient.connect(callSettings: callSettings)
        room = Room.create()
        return room
    }
    
    public func renderLocalVideo(renderer: RTCVideoRenderer) {
        webRTCClient.startCapturingLocalVideo(renderer: renderer, cameraPosition: .front)
    }
    
    public func changeAudioState(isEnabled: Bool) async throws {
        try await webRTCClient.changeAudioState(isEnabled: isEnabled)
    }
    
    public func changeVideoState(isEnabled: Bool) async throws {
        try await webRTCClient.changeVideoState(isEnabled: isEnabled)
    }
    
    public func changeCameraMode(position: CameraPosition) {
        webRTCClient.changeCameraMode(position: position)
    }
    
    // MARK: - private
    
    private func handleLocalTrackUpdate() {
        webRTCClient.onLocalVideoTrackUpdate = { [weak self] localVideoTrack in
            guard let userId = self?.userInfo.id else { return }
            if let participant = self?.room?.participants[userId] {
                participant.track = localVideoTrack
                self?.room?.participants[userId] = participant
            } else {
                // TODO: temporarly create the participant
                let participant = CallParticipant(
                    id: userId,
                    role: "user",
                    name: self?.userInfo.name ?? userId,
                    profileImageURL: self?.userInfo.imageURL,
                    isOnline: true,
                    hasVideo: true,
                    hasAudio: true
                )
                participant.track = localVideoTrack
                self?.room?.participants[userId] = participant
            }
        }
    }
    
    private func handleRemoteStreamAdded() {
        webRTCClient.onRemoteStreamAdded = { [weak self] stream in
            let trackId = stream?.streamId.components(separatedBy: ":").first ?? UUID().uuidString
            var participant = self?.room?.participants[trackId]
            if participant == nil {
                participant = CallParticipant(
                    id: trackId,
                    role: "member",
                    name: trackId,
                    profileImageURL: nil,
                    isOnline: true,
                    hasVideo: true,
                    hasAudio: true
                )
            }
            participant?.track = stream?.videoTracks.first
            if let participant = participant {
                self?.room?.add(participant: participant)
            }
        }
    }
    
    private func handleRemoteStreamRemoved() {
        webRTCClient.onRemoteStreamRemoved = { [weak self] stream in
            let trackId = stream?.streamId.components(separatedBy: ":").first ?? UUID().uuidString
            self?.room?.removeParticipant(with: trackId)
        }
    }
    
    private func handleParticipantsUpdated() {
        webRTCClient.onParticipantsUpdated = { [weak self] participants in
            self?.room?.participants = participants
        }
    }
    
    private func handleParticipantEvent() {
        webRTCClient.onParticipantEvent = { [weak self] event in
            self?.room?.onParticipantEvent?(event)
        }
    }
}
