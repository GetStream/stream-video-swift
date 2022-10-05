//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

public class CallController {
    
    private var webRTCClient: WebRTCClient? {
        didSet {
            handleLocalTrackUpdate()
            handleParticipantsUpdated()
            handleParticipantEvent()
        }
    }

    private(set) var call: Call?
    private let userInfo: UserInfo
    private let callId: String
    private let callType: CallType
    private let callCoordinatorController: CallCoordinatorController
    private let apiKey: String
    private let tokenProvider: TokenProvider
    
    init(
        callCoordinatorController: CallCoordinatorController,
        userInfo: UserInfo,
        callId: String,
        callType: CallType,
        apiKey: String,
        tokenProvider: @escaping TokenProvider
    ) {
        self.userInfo = userInfo
        self.callId = callId
        self.callType = callType
        self.callCoordinatorController = callCoordinatorController
        self.apiKey = apiKey
        self.tokenProvider = tokenProvider
    }
    
    public func joinCall(
        callType: CallType,
        callId: String,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        participantIds: [String]
    ) async throws -> Call {
        let edgeServer = try await callCoordinatorController.joinCall(
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
        try await webRTCClient?.connect(callSettings: callSettings, videoOptions: videoOptions)
        let currentCall = Call.create()
        call = currentCall
        return currentCall
    }
    
    public func testSFU(callSettings: CallSettings, url: String, token: String) async throws -> Call? {
        webRTCClient = WebRTCClient(
            userInfo: userInfo,
            apiKey: apiKey,
            hostname: url,
            token: token,
            tokenProvider: tokenProvider
        )
    
        let webRTCClient = try currentWebRTCClient()
        try await webRTCClient.connect(callSettings: callSettings, videoOptions: VideoOptions())
        call = Call.create()
        return call
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
    
    public func changeTrackVisibility(for participant: CallParticipant, isVisible: Bool) async {
        await webRTCClient?.changeTrackVisibility(for: participant, isVisible: isVisible)
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
            if let participant = self?.call?.participants[userId] {
                let updated = participant.withUpdated(track: localVideoTrack)
                self?.call?.participants[userId] = updated
            } else {
                // TODO: temporarly create the participant
                let participant = CallParticipant(
                    id: userId,
                    role: "user",
                    name: self?.userInfo.name ?? userId,
                    profileImageURL: self?.userInfo.imageURL,
                    isOnline: true,
                    hasVideo: true,
                    hasAudio: true,
                    showTrack: true
                )
                let updated = participant.withUpdated(track: localVideoTrack)
                self?.call?.participants[userId] = updated
            }
        }
    }
    
    private func handleParticipantsUpdated() {
        webRTCClient?.onParticipantsUpdated = { [weak self] participants in
            self?.call?.participants = participants
        }
    }
    
    private func handleParticipantEvent() {
        webRTCClient?.onParticipantEvent = { [weak self] event in
            self?.call?.onParticipantEvent?(event)
        }
    }
}
