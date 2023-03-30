//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

/// Class that handles a particular call.
public class CallController {
    
    public var onCallUpdated: ((Call?) -> ())?
    
    private var webRTCClient: WebRTCClient? {
        didSet {
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
    private let videoConfig: VideoConfig
    private let sfuReconnectionTime: CGFloat = 30
    private var reconnectionDate: Date?
    
    init(
        callCoordinatorController: CallCoordinatorController,
        user: User,
        callId: String,
        callType: CallType,
        apiKey: String,
        videoConfig: VideoConfig
    ) {
        self.user = user
        self.callId = callId
        self.callType = callType
        self.callCoordinatorController = callCoordinatorController
        self.apiKey = apiKey
        self.videoConfig = videoConfig
    }
    
    /// Joins a call with the provided information.
    /// - Parameters:
    ///  - callType: the type of the call
    ///  - callId: the id of the call
    ///  - callSettings: the current call settings
    ///  - videoOptions: configuration options about the video
    ///  - participantIds: array of the ids of the participants
    ///  - ring: whether ringing events should be handled
    /// - Returns: a newly created `Call`.
    public func joinCall(
        callType: CallType,
        callId: String,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        participants: [User],
        ring: Bool = false
    ) async throws -> Call {
        let edgeServer = try await callCoordinatorController.joinCall(
            callType: callType,
            callId: callId,
            videoOptions: videoOptions,
            participants: participants,
            ring: ring
        )
        
        return try await connectToEdge(
            edgeServer,
            callType: callType,
            callId: callId,
            callSettings: callSettings,
            videoOptions: videoOptions,
            ring: ring
        )
    }
    
    /// Joins a call on the specified `edgeServer` with the given `callType`, `callId`, `callSettings`, and `videoOptions`.
    /// - Parameters:
    ///   - edgeServer: The `EdgeServer` to join the call on.
    ///   - callType: The `CallType` of the call.
    ///   - callId: The unique identifier for the call.
    ///   - callSettings: The settings to use for the call.
    ///   - videoOptions: The `VideoOptions` for the call.
    /// - Returns: A `Call` instance representing the joined call.
    /// - Throws: An error if the call could not be joined.
    public func joinCall(
        on edgeServer: EdgeServer,
        callType: CallType,
        callId: String,
        callSettings: CallSettings,
        videoOptions: VideoOptions
    ) async throws -> Call {
        try await connectToEdge(
            edgeServer,
            callType: callType,
            callId: callId,
            callSettings: callSettings,
            videoOptions: videoOptions,
            ring: false
        )
    }

    /// Selects an `EdgeServer` for a call with the specified `videoOptions` and `participants`.
    /// - Parameters:
    ///   - videoOptions: The `VideoOptions` for the call.
    ///   - participants: An array of `User` instances representing the participants in the call.
    /// - Returns: An `EdgeServer` instance representing the selected server.
    /// - Throws: An error if an `EdgeServer` could not be selected.
    public func selectEdgeServer(
        videoOptions: VideoOptions,
        participants: [User]
    ) async throws -> EdgeServer {
        try await callCoordinatorController.joinCall(
            callType: callType,
            callId: callId,
            videoOptions: videoOptions,
            participants: participants,
            ring: false
        )
    }
    
    /// Starts capturing the local video.
    public func startCapturingLocalVideo() {
        webRTCClient?.startCapturingLocalVideo(cameraPosition: .front)
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
    
    /// Changes the availability of sound during the call.
    /// - Parameter isEnabled: whether the sound should be enabled.
    public func changeSoundState(isEnabled: Bool) async throws {
        let webRTCClient = try currentWebRTCClient()
        try await webRTCClient.changeSoundState(isEnabled: isEnabled)
    }
    
    /// Changes the camera position (front/back) for the current user.
    /// - Parameters:
    ///  - position: the new camera position.
    ///  - completion: called when the camera position is changed.
    public func changeCameraMode(position: CameraPosition, completion: @escaping () -> ()) {
        webRTCClient?.changeCameraMode(position: position, completion: completion)
    }
    
    /// Changes the track visibility for a participant (not visible if they go off-screen).
    /// - Parameters:
    ///  - participant: the participant whose track visibility would be changed.
    ///  - isVisible: whether the track should be visible.
    public func changeTrackVisibility(for participant: CallParticipant, isVisible: Bool) async {
        await webRTCClient?.changeTrackVisibility(for: participant, isVisible: isVisible)
    }
    
    /// Adds members with the specified `ids` to the current call.
    /// - Parameter ids: An array of `String` values representing the member IDs to add.
    /// - Throws: An error if the members could not be added to the call.
    public func addMembersToCall(ids: [String]) async throws {
        let callCid = "\(callType.name):\(callId)"
        try await callCoordinatorController.addMembersToCall(with: callCid, memberIds: ids)
    }
    
    /// Sets a `videoFilter` for the current call.
    /// - Parameter videoFilter: A `VideoFilter` instance representing the video filter to set.
    public func setVideoFilter(_ videoFilter: VideoFilter?) {
        webRTCClient?.setVideoFilter(videoFilter)
    }
    
    /// Cleans up the call controller.
    func cleanUp() {
        call = nil
        Task {
            await webRTCClient?.cleanUp()
            webRTCClient = nil
        }
    }
    
    func update(callInfo: CallInfo) {
        if callInfo.cId == call?.cId {
            call?.update(callInfo: callInfo)
        } else {
            log.warning("Received call info that doesn't match the active call")
        }
    }
    
    func updateCall(from recordingEvent: RecordingEvent) {
        if recordingEvent.callCid == call?.cId {
            call?.update(recordingState: recordingEvent.action.toState)
        } else {
            log.warning("Received recording event that doesn't match the active call")
        }
    }
    
    // MARK: - private
    
    private func connectToEdge(
        _ edgeServer: EdgeServer,
        callType: CallType,
        callId: String,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        ring: Bool
    ) async throws -> Call {
        webRTCClient = WebRTCClient(
            user: user,
            apiKey: apiKey,
            hostname: edgeServer.url,
            token: edgeServer.token,
            callCid: "\(callType.name):\(callId)",
            callCoordinatorController: callCoordinatorController,
            videoConfig: videoConfig
        )
        webRTCClient?.onSignalConnectionStateChange = handleSignalChannelConnectionStateChange(_:)
        
        let connectOptions = ConnectOptions(
            iceServers: edgeServer.iceServers.map { $0.toICEServerConfig() }
        )
        try await webRTCClient?.connect(
            callSettings: callSettings,
            videoOptions: videoOptions,
            connectOptions: connectOptions
        )
        let sessionId = webRTCClient?.sessionID ?? ""
        let currentCall = Call.create(
            callId: callId,
            callType: callType,
            sessionId: sessionId,
            callSettingsInfo: edgeServer.callSettings,
            recordingState: edgeServer.callSettings.recording ? .recording : .noRecording
        )
        call = currentCall
        return currentCall
    }
    
    private func currentWebRTCClient() throws -> WebRTCClient {
        guard let webRTCClient = webRTCClient else {
            throw ClientError.Unexpected()
        }
        return webRTCClient
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
    
    private func handleSignalChannelConnectionStateChange(_ state: WebSocketConnectionState) {
        switch state {
        case .disconnected(let source):
            log.debug("Signal channel disconnected")
            handleSignalChannelDisconnect(source: source)
        case .connected(healthCheckInfo: _):
            log.debug("Signal channel connected")
            if reconnectionDate != nil {
                reconnectionDate = nil
            }
            call?.update(isReconnecting: false)
        default:
            log.debug("Signal connection state changed to \(state)")
        }
    }
    
    private func handleSignalChannelDisconnect(
        source: WebSocketConnectionState.DisconnectionSource
    ) {
        guard let call = call, source != .userInitiated else { return }
        if reconnectionDate == nil {
            reconnectionDate = Date()
        }
        let diff = Date().timeIntervalSince(reconnectionDate ?? Date())
        if diff > sfuReconnectionTime {
            log.debug("Stopping retry mechanism, SFU not available more than 15 seconds")
            handleReconnectionError()
            reconnectionDate = nil
            return
        }
        Task {
            do {
                log.debug("Waiting to reconnect")
                try? await Task.sleep(nanoseconds: 250_000_000)
                log.debug("Retrying to connect to the call")
                self.call = try await joinCall(
                    callType: call.callType,
                    callId: call.callId,
                    callSettings: webRTCClient?.callSettings ?? CallSettings(),
                    videoOptions: webRTCClient?.videoOptions ?? VideoOptions(),
                    participants: []
                )
                self.call?.update(isReconnecting: true)
                self.onCallUpdated?(self.call)
            } catch {
                self.handleReconnectionError()
            }
        }
    }
    
    private func handleReconnectionError() {
        log.error("Error while reconnecting to the call")
        self.call = nil
        self.onCallUpdated?(nil)
    }
    
}
