//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

/// Class that handles a particular call.
class CallController {
        
    private var webRTCClient: WebRTCClient? {
        didSet {
            handleParticipantsUpdated()
            handleParticipantEvent()
            handleParticipantCountUpdated()
            if let allEventsMiddleware {
                webRTCClient?.eventNotificationCenter.add(middleware: allEventsMiddleware)
            }
        }
    }

    weak var call: Call?
    private let user: User
    private let callId: String
    private let callType: String
    internal let callCoordinatorController: CallCoordinatorController
    private let apiKey: String
    private let videoConfig: VideoConfig
    private let sfuReconnectionTime: CGFloat
    private var reconnectionDate: Date?
    private var allEventsMiddleware: AllEventsMiddleware?
    private let environment: CallController.Environment
    
    init(
        callCoordinatorController: CallCoordinatorController,
        user: User,
        callId: String,
        callType: String,
        apiKey: String,
        videoConfig: VideoConfig,
        allEventsMiddleware: AllEventsMiddleware?,
        environment: CallController.Environment = .init()
    ) {
        self.user = user
        self.callId = callId
        self.callType = callType
        self.callCoordinatorController = callCoordinatorController
        self.allEventsMiddleware = allEventsMiddleware
        self.apiKey = apiKey
        self.videoConfig = videoConfig
        self.sfuReconnectionTime = environment.sfuReconnectionTime
        self.environment = environment
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
    func joinCall(
        callType: String,
        callId: String,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        members: [User],
        ring: Bool = false,
        notify: Bool = false
    ) async throws {
        let edgeServer = try await callCoordinatorController.joinCall(
            callType: callType,
            callId: callId,
            videoOptions: videoOptions,
            members: members,
            ring: ring,
            notify: notify
        )
        
        try await connectToEdge(
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
    ///   - callType: The type of the call.
    ///   - callId: The unique identifier for the call.
    ///   - callSettings: The settings to use for the call.
    ///   - videoOptions: The `VideoOptions` for the call.
    /// - Throws: An error if the call could not be joined.
    func joinCall(
        on edgeServer: EdgeServer,
        callType: String,
        callId: String,
        callSettings: CallSettings,
        videoOptions: VideoOptions
    ) async throws {
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
    ///   - members: An array of `User` instances representing the members in the call.
    /// - Returns: An `EdgeServer` instance representing the selected server.
    /// - Throws: An error if an `EdgeServer` could not be selected.
    func selectEdgeServer(
        videoOptions: VideoOptions,
        members: [User]
    ) async throws -> EdgeServer {
        try await callCoordinatorController.joinCall(
            callType: callType,
            callId: callId,
            videoOptions: videoOptions,
            members: members,
            ring: false,
            notify: false
        )
    }
    
    /// Gets the call on the backend with the given parameters.
    ///
    /// - Parameters:
    ///  - callId: the id of the call.
    ///  - type: the type of the call.
    ///  - membersLimit: An optional integer specifying the maximum number of members allowed in the call.
    ///  - notify: A boolean value indicating whether members should be notified about the call.
    ///  - ring: A boolean value indicating whether to ring the call.
    /// - Throws: An error if the call doesn't exist.
    /// - Returns: The call's data.
    func getCall(
        callId: String,
        type: String,
        membersLimit: Int?,
        ring: Bool,
        notify: Bool
    ) async throws -> CallData {
        let response = try await callCoordinatorController.coordinatorClient.getCall(
            callId: callId,
            type: type,
            membersLimit: membersLimit,
            ring: ring,
            notify: notify
        )
        return response.call.toCallData(
            members: response.members,
            blockedUsers: response.blockedUsers
        )
    }
    
    /// Gets or creates the call on the backend with the given parameters.
    ///
    /// - Parameters:
    ///  - members: An optional array of User objects to add to the call.
    ///  - startsAt: An optional Date object representing the time the call is scheduled to start.
    ///  - customData: An optional dictionary of custom data to attach to the call.
    ///  - membersLimit: An optional integer specifying the maximum number of members allowed in the call.
    ///  - ring: A boolean value indicating whether to ring the call.
    ///  - notify: A boolean value indicating whether to notify members.
    /// - Throws: An error if the call creation fails.
    /// - Returns: The call's data.
    func getOrCreateCall(
        members: [User],
        startsAt: Date?,
        customData: [String: RawJSON],
        membersLimit: Int?,
        ring: Bool,
        notify: Bool
    ) async throws -> CallData {
        let data = CallRequest(
            custom: RawJSON.convert(customData: customData),
            members: members.map {
                MemberRequest(
                    custom: RawJSON.convert(customData: $0.customData),
                    role: $0.role,
                    userId: $0.id
                )
            },
            startsAt: startsAt
        )
        let request = GetOrCreateCallRequest(
            data: data,
            membersLimit: membersLimit,
            notify: notify,
            ring: ring
        )
        let response = try await callCoordinatorController.coordinatorClient.getOrCreateCall(
            with: request,
            callId: callId,
            callType: callType
        )
        return response.call.toCallData(members: response.members, blockedUsers: response.blockedUsers)
    }
    
    /// Starts capturing the local video.
    func startCapturingLocalVideo() {
        webRTCClient?.startCapturingLocalVideo(cameraPosition: .front)
    }
    
    /// Changes the audio state for the current user.
    /// - Parameter isEnabled: whether audio should be enabled.
    func changeAudioState(isEnabled: Bool) async throws {
        let webRTCClient = try currentWebRTCClient()
        try await webRTCClient.changeAudioState(isEnabled: isEnabled)
    }
    
    /// Changes the video state for the current user.
    /// - Parameter isEnabled: whether video should be enabled.
    func changeVideoState(isEnabled: Bool) async throws {
        let webRTCClient = try currentWebRTCClient()
        try await webRTCClient.changeVideoState(isEnabled: isEnabled)
    }
    
    /// Changes the availability of sound during the call.
    /// - Parameter isEnabled: whether the sound should be enabled.
    func changeSoundState(isEnabled: Bool) async throws {
        let webRTCClient = try currentWebRTCClient()
        try await webRTCClient.changeSoundState(isEnabled: isEnabled)
    }
    
    /// Changes the camera position (front/back) for the current user.
    /// - Parameters:
    ///  - position: the new camera position.
    ///  - completion: called when the camera position is changed.
    func changeCameraMode(position: CameraPosition, completion: @escaping () -> ()) {
        webRTCClient?.changeCameraMode(position: position, completion: completion)
    }
    
    /// Changes the track visibility for a participant (not visible if they go off-screen).
    /// - Parameters:
    ///  - participant: the participant whose track visibility would be changed.
    ///  - isVisible: whether the track should be visible.
    func changeTrackVisibility(for participant: CallParticipant, isVisible: Bool) async {
        await webRTCClient?.changeTrackVisibility(for: participant, isVisible: isVisible)
    }
    
    /// Adds members with the specified `ids` to the current call.
    /// - Parameter ids: An array of `String` values representing the member IDs to add.
    /// - Throws: An error if the members could not be added to the call.
    func addMembersToCall(ids: [String]) async throws -> [User] {
        try await callCoordinatorController.updateCallMembers(
            callId: callId,
            callType: callType,
            updateMembers: ids.map { MemberRequest(userId: $0) },
            removedIds: []
        )
    }
    
    /// Removes members with the specified `ids` from the current call.
    /// - Parameter ids: An array of `String` values representing the member IDs to remove.
    /// - Throws: An error if the members could not be removed from the call.
    func removeMembersFromCall(ids: [String]) async throws -> [User] {
        try await callCoordinatorController.updateCallMembers(
            callId: callId,
            callType: callType,
            updateMembers: [],
            removedIds: ids
        )
    }
    
    /// Sets a `videoFilter` for the current call.
    /// - Parameter videoFilter: A `VideoFilter` instance representing the video filter to set.
    func setVideoFilter(_ videoFilter: VideoFilter?) {
        webRTCClient?.setVideoFilter(videoFilter)
    }
    
    /// Updates the track size for the provided participant.
    /// - Parameters:
    ///  - trackSize: the size of the track.
    ///  - participant: the call participant.
    func updateTrackSize(_ trackSize: CGSize, for participant: CallParticipant) async {
        await webRTCClient?.updateTrackSize(trackSize, for: participant)
    }
    
    /// Cleans up the call controller.
    func cleanUp() {
        call = nil
        Task {
            await webRTCClient?.cleanUp()
            webRTCClient = nil
        }
    }
    
    func update(state: CallData) {
        if state.callCid == call?.cId {
            call?.update(state: state)
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
        callType: String,
        callId: String,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        ring: Bool
    ) async throws {
        webRTCClient = environment.webRTCBuilder(
            user,
            apiKey,
            edgeServer.url,
            edgeServer.webSocketURL,
            edgeServer.token,
            callCid(from: callId, callType: callType),
            callCoordinatorController,
            videoConfig,
            edgeServer.callSettings.callSettings.audio,
            .init()
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
        call?.sessionId = sessionId
        call?.update(recordingState: edgeServer.callSettings.recording ? .recording : .noRecording)
        call?.update(state: edgeServer.callSettings.state)
    }
    
    private func currentWebRTCClient() throws -> WebRTCClient {
        guard let webRTCClient = webRTCClient else {
            throw ClientError.Unexpected()
        }
        return webRTCClient
    }
    
    private func handleParticipantsUpdated() {
        webRTCClient?.onParticipantsUpdated = { [weak self] participants in
            DispatchQueue.main.async {
                self?.call?.participants = participants
            }
        }
    }
    
    private func handleParticipantEvent() {
        webRTCClient?.onParticipantEvent = { [weak self] event in
            self?.call?.onParticipantEvent?(event)
        }
    }
    
    private func handleParticipantCountUpdated() {
        webRTCClient?.onParticipantCountUpdated = { [weak self] participantCount in
            DispatchQueue.main.async {
                self?.call?.participantCount = participantCount
            }
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
            call?.update(reconnectionStatus: .connected)
        default:
            log.debug("Signal connection state changed to \(state)")
        }
    }
    
    private func handleSignalChannelDisconnect(
        source: WebSocketConnectionState.DisconnectionSource,
        isRetry: Bool = false
    ) {
        guard let call = call,
                (call.reconnectionStatus != .reconnecting || isRetry),
                source != .userInitiated else {
            return            
        }
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
                await webRTCClient?.cleanUp()
                log.debug("Waiting to reconnect")
                try? await Task.sleep(nanoseconds: 250_000_000)
                log.debug("Retrying to connect to the call")
                self.call?.update(reconnectionStatus: .reconnecting)
                try await joinCall(
                    callType: call.callType,
                    callId: call.callId,
                    callSettings: webRTCClient?.callSettings ?? CallSettings(),
                    videoOptions: webRTCClient?.videoOptions ?? VideoOptions(),
                    members: []
                )
            } catch {
                if diff > sfuReconnectionTime {
                    self.handleReconnectionError()
                } else {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    self.handleSignalChannelDisconnect(source: source, isRetry: true)
                }
            }
        }
    }
    
    private func handleReconnectionError() {
        log.error("Error while reconnecting to the call")
        self.call?.update(reconnectionStatus: .disconnected)
        self.cleanUp()
    }
    
}

extension CallController {
    struct Environment {
        var webRTCBuilder: (
            _ user: User,
            _ apiKey: String,
            _ hostname: String,
            _ webSocketURLString: String,
            _ token: String,
            _ callCid: String,
            _ callCoordinatorController: CallCoordinatorController,
            _ videoConfig: VideoConfig,
            _ audioSettings: AudioSettings,
            _ environment: WebSocketClient.Environment
        ) -> WebRTCClient = {
            WebRTCClient(
                user: $0,
                apiKey: $1,
                hostname: $2,
                webSocketURLString: $3,
                token: $4,
                callCid: $5,
                callCoordinatorController: $6,
                videoConfig: $7,
                audioSettings: $8,
                environment: $9
            )
        }
        
        var sfuReconnectionTime: CGFloat = 30
    }
}
