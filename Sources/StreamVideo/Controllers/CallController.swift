//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

public class CallController {
    
    private var webRTCClient: WebRTCClient? {
        didSet {
            handleLocalTrackUpdate()
            handleRemoteStreamAdded()
            handleRemoteStreamRemoved()
            handleParticipantsUpdated()
            handleParticipantEvent()
        }
    }

    private(set) var room: Room?
    private let userInfo: UserInfo
    private let callId: String
    private let callType: CallType
    private let callCoordinatorController: CallCoordinatorController
    private let token: Token
    private let apiKey: String
    private let tokenProvider: TokenProvider
    
    init(
        callCoordinatorController: CallCoordinatorController,
        userInfo: UserInfo,
        callId: String,
        callType: CallType,
        token: Token,
        apiKey: String,
        tokenProvider: @escaping TokenProvider
    ) {
        self.userInfo = userInfo
        self.callId = callId
        self.callType = callType
        self.callCoordinatorController = callCoordinatorController
        self.token = token
        self.apiKey = apiKey
        self.tokenProvider = tokenProvider
    }
    
    public func startCall(
        callType: CallType,
        callId: String,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        participantIds: [String]
    ) async throws -> Room {
        let edgeServer = try await callCoordinatorController.startCall(
            callType: callType,
            callId: callId,
            videoOptions: videoOptions,
            participantIds: participantIds
        )
        
        webRTCClient = WebRTCClient(
            userInfo: userInfo,
            apiKey: apiKey,
            hostname: edgeServer.url,
            token: edgeServer.token,
            tokenProvider: tokenProvider
        )
        try await webRTCClient?.connect(callSettings: callSettings)
        let currentRoom = Room.create()
        room = currentRoom
        return currentRoom
    }
    
    public func joinCall(
        callType: CallType,
        callId: String,
        callSettings: CallSettings,
        videoOptions: VideoOptions
    ) async throws -> Room {
        let edgeServer = try await callCoordinatorController.joinCall(
            callType: callType,
            callId: callId,
            videoOptions: videoOptions
        )
        
        webRTCClient = WebRTCClient(
            userInfo: userInfo,
            apiKey: apiKey,
            hostname: edgeServer.url,
            token: edgeServer.token,
            tokenProvider: tokenProvider
        )
        try await webRTCClient?.connect(callSettings: callSettings)
        let currentRoom = Room.create()
        room = currentRoom
        return currentRoom
    }
    
    public func testSFU(callSettings: CallSettings) async throws -> Room? {
        webRTCClient = WebRTCClient(
            userInfo: userInfo,
            apiKey: apiKey,
            hostname: "http://192.168.0.132:3031/twirp",
            token: token.rawValue,
            tokenProvider: tokenProvider
        )
    
        let webRTCClient = try currentWebRTCClient()
        try await webRTCClient.connect(callSettings: callSettings)
        room = Room.create()
        return room
    }
    
    public func renderLocalVideo(renderer: RTCVideoRenderer) {
        webRTCClient?.startCapturingLocalVideo(renderer: renderer, cameraPosition: .front)
    }
    
    public func changeAudioState(isEnabled: Bool) async throws {
        let webRTCClient = try currentWebRTCClient()
        try await webRTCClient.changeAudioState(isEnabled: isEnabled)
    }
    
    public func changeVideoState(isEnabled: Bool) async throws {
        let webRTCClient = try currentWebRTCClient()
        try await webRTCClient.changeVideoState(isEnabled: isEnabled)
    }
    
    public func changeCameraMode(position: CameraPosition) {
        webRTCClient?.changeCameraMode(position: position)
    }
    
    public func loadParticipants(for call: IncomingCall) async throws -> [CallParticipant] {
        try await callCoordinatorController.loadParticipants(for: call)
    }
    
    func cleanUp() {
        Task {
            await webRTCClient?.cleanUp()
        }
    }
    
    // MARK: - private
    
    private func currentWebRTCClient() throws -> WebRTCClient {
        guard let webRTCClient = webRTCClient else {
            throw ClientError.Unexpected()
        }
        return webRTCClient
    }
    
    private func handleLocalTrackUpdate() {
        webRTCClient?.onLocalVideoTrackUpdate = { [weak self] localVideoTrack in
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
        webRTCClient?.onRemoteStreamAdded = { [weak self] stream in
            let idParts = stream?.streamId.components(separatedBy: ":")
            let trackId = idParts?.first ?? UUID().uuidString
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
            if idParts?.last == "video" || stream?.videoTracks.first != nil {
                participant?.track = stream?.videoTracks.first
            }
            if let participant = participant {
                self?.room?.add(participant: participant)
            }
        }
    }
    
    private func handleRemoteStreamRemoved() {
        webRTCClient?.onRemoteStreamRemoved = { [weak self] stream in
            let trackId = stream?.streamId.components(separatedBy: ":").first ?? UUID().uuidString
            self?.room?.removeParticipant(with: trackId)
        }
    }
    
    private func handleParticipantsUpdated() {
        webRTCClient?.onParticipantsUpdated = { [weak self] participants in
            self?.room?.participants = participants
        }
    }
    
    private func handleParticipantEvent() {
        webRTCClient?.onParticipantEvent = { [weak self] event in
            self?.room?.onParticipantEvent?(event)
        }
    }
}
