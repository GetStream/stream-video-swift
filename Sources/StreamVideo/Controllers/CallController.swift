//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

/// Class that handles a particular call.
public class CallController {
    
    private var webRTCClient: WebRTCClient? {
        didSet {
            handleLocalTrackUpdate()
            handleParticipantsUpdated()
            handleParticipantEvent()
        }
    }

    private(set) var call: Call?
    private let user: User
    private let callId: String
    private let callType: CallType
    private let callCoordinatorController: CallCoordinatorController
    private let apiKey: String
    private let videoEnabled: Bool
    private let tokenProvider: UserTokenProvider
    
    init(
        callCoordinatorController: CallCoordinatorController,
        user: User,
        callId: String,
        callType: CallType,
        apiKey: String,
        videoEnabled: Bool,
        tokenProvider: @escaping UserTokenProvider
    ) {
        self.user = user
        self.callId = callId
        self.callType = callType
        self.callCoordinatorController = callCoordinatorController
        self.apiKey = apiKey
        self.tokenProvider = tokenProvider
        self.videoEnabled = videoEnabled
    }
    
    /// Joins a call with the provided information.
    /// - Parameters:
    ///  - callType: the type of the call
    ///  - callId: the id of the call
    ///  - callSettings: the current call settings
    ///  - videoOptions: configuration options about the video
    ///  - participantIds: array of the ids of the participants
    /// - Returns: a newly created `Call`.
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
            user: user,
            apiKey: apiKey,
            hostname: edgeServer.url,
            token: edgeServer.token,
            videoEnabled: videoEnabled,
            callCid: "\(callType)-\(callId)",
            callCoordinatorController: callCoordinatorController,
            tokenProvider: tokenProvider
        )
        
        let connectOptions = ConnectOptions(
            iceServers: edgeServer.iceServers.map { $0.toICEServerConfig() }
        )
        try await webRTCClient?.connect(
            callSettings: callSettings,
            videoOptions: videoOptions,
            connectOptions: connectOptions
        )
        let currentCall = Call.create(callId: callId, callType: callType)
        call = currentCall
        return currentCall
    }
    
    /// Renders the local video in the provided renderer.
    /// - Parameter renderer: Any view (both UIKit and SwiftUI) implementing the `RTCVideoRenderer` protocol.
    public func renderLocalVideo(renderer: RTCVideoRenderer) {
        webRTCClient?.startCapturingLocalVideo(renderer: renderer, cameraPosition: .front)
    }
    
    /// Changes the audio state for the current user.
    /// - Parameter isEnabled: whether audio should be enabled.
    public func changeAudioState(isEnabled: Bool) async throws {
        let webRTCClient = try currentWebRTCClient()
        try await webRTCClient.changeAudioState(isEnabled: isEnabled)
    }
    
    /// Changes the video state for the current user.
    /// - Parameter isEnabled: whether video should be enabled.
    public func changeVideoState(isEnabled: Bool) async throws {
        let webRTCClient = try currentWebRTCClient()
        try await webRTCClient.changeVideoState(isEnabled: isEnabled)
    }
    
    /// Changes the camera position (front/back) for the current user.
    /// - Parameter position: the new camera position.
    public func changeCameraMode(position: CameraPosition) {
        webRTCClient?.changeCameraMode(position: position)
    }
    
    /// Changes the track visibility for a participant (not visible if they go off-screen).
    /// - Parameters:
    ///  - participant: the participant whose track visibility would be changed.
    ///  - isVisible: whether the track should be visible.
    public func changeTrackVisibility(for participant: CallParticipant, isVisible: Bool) async {
        await webRTCClient?.changeTrackVisibility(for: participant, isVisible: isVisible)
    }
    
    public func addMembersToCall(ids: [String]) async throws {
        let callCid = "\(callType.name):\(callId)"
        try await callCoordinatorController.addMembersToCall(with: callCid, memberIds: ids)
    }
    
    /// Cleans up the call controller.
    func cleanUp() {
        call = nil
        Task {
            await webRTCClient?.cleanUp()
            webRTCClient = nil
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
            guard let userId = self?.user.id else { return }
            if let participant = self?.call?.participants[userId] {
                let updated = participant.withUpdated(track: localVideoTrack)
                self?.call?.participants[userId] = updated
            } else {
                // TODO: temporarly create the participant
                let participant = CallParticipant(
                    id: userId,
                    role: "user",
                    name: self?.user.name ?? userId,
                    profileImageURL: self?.user.imageURL,
                    trackLookupPrefix: userId,
                    isOnline: true,
                    hasVideo: true,
                    hasAudio: true,
                    isScreenSharing: false,
                    showTrack: true,
                    sessionId: ""
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
