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
            handleParticipantCountUpdated()
        }
    }

    weak var call: Call?
    private let user: User
    private let callId: String
    private let callType: String
    private let apiKey: String
    private let defaultAPI: DefaultAPI
    private let videoConfig: VideoConfig
    private let sfuReconnectionTime: CGFloat
    private var reconnectionDate: Date?
    private let environment: CallController.Environment
    private var cachedLocation: String?
    
    init(
        defaultAPI: DefaultAPI,
        user: User,
        callId: String,
        callType: String,
        apiKey: String,
        videoConfig: VideoConfig,
        cachedLocation: String?,
        environment: CallController.Environment = .init()
    ) {
        self.user = user
        self.callId = callId
        self.callType = callType
        self.apiKey = apiKey
        self.videoConfig = videoConfig
        self.sfuReconnectionTime = environment.sfuReconnectionTime
        self.environment = environment
        self.defaultAPI = defaultAPI
        self.cachedLocation = cachedLocation
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
    @discardableResult
    func joinCall(
        create: Bool = true,
        callType: String,
        callId: String,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        options: CreateCallOptions? = nil,
        sessionID: String? = nil,
        ring: Bool = false,
        notify: Bool = false
    ) async throws -> JoinCallResponse {
        let response = try await joinCall(
            create: create,
            callType: callType,
            callId: callId,
            videoOptions: videoOptions,
            options: options,
            ring: ring,
            notify: notify
        )
        
        try await connectToEdge(
            response,
            sessionID: sessionID,
            callType: callType,
            callId: callId,
            callSettings: callSettings,
            videoOptions: videoOptions,
            ring: ring
        )
        
        return response
    }
    
    /// Gets the call on the backend with the given parameters.
    ///
    /// - Parameters:
    ///  - callId: the id of the call.
    ///  - callType: the type of the call.
    ///  - membersLimit: An optional integer specifying the maximum number of members allowed in the call.
    ///  - notify: A boolean value indicating whether members should be notified about the call.
    ///  - ring: A boolean value indicating whether to ring the call.
    /// - Throws: An error if the call doesn't exist.
    /// - Returns: The call's data.
    func getCall(
        callType: String,
        callId: String,
        membersLimit: Int?,
        ring: Bool,
        notify: Bool
    ) async throws -> CallResponse {
        let userAuth = defaultAPI.middlewares.first { $0 is UserAuth } as? UserAuth
        let connectionId = try await userAuth?.connectionId() ?? ""
        let response = try await defaultAPI.getCall(
            type: callType,
            id: callId,
            connectionId: connectionId,
            membersLimit: membersLimit,
            ring: ring,
            notify: notify
        )
        return response.call
    }
    
    /// Gets or creates the call on the backend with the given parameters.
    ///
    /// - Parameters:
    ///  - members: An optional array of Member objects to add to the call.
    ///  - startsAt: An optional Date object representing the time the call is scheduled to start.
    ///  - customData: An optional dictionary of custom data to attach to the call.
    ///  - membersLimit: An optional integer specifying the maximum number of members allowed in the call.
    ///  - ring: A boolean value indicating whether to ring the call.
    ///  - notify: A boolean value indicating whether to notify members.
    /// - Throws: An error if the call creation fails.
    /// - Returns: The call's data.
    func getOrCreateCall(
        members: [Member],
        startsAt: Date?,
        customData: [String: RawJSON],
        membersLimit: Int?,
        ring: Bool,
        notify: Bool
    ) async throws -> CallResponse {
        let data = CallRequest(
            custom: customData,
            members: members.map {
                MemberRequest(
                    custom: $0.customData,
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
        let response = try await defaultAPI.getOrCreateCall(
            type: callType,
            id: callId,
            getOrCreateCallRequest: request
        )
        return response.call
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
    
    func updateOwnCapabilities(ownCapabilities: [OwnCapability]) {
        if ownCapabilities != webRTCClient?.ownCapabilities {
            webRTCClient?.ownCapabilities = ownCapabilities
        }
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
    
    private func connectToEdge(
        _ response: JoinCallResponse,
        sessionID: String?,
        callType: String,
        callId: String,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        ring: Bool
    ) async throws {
        webRTCClient = environment.webRTCBuilder(
            user,
            apiKey,
            response.credentials.server.url,
            response.credentials.server.wsEndpoint,
            response.credentials.token,
            callCid(from: callId, callType: callType),
            sessionID,
            response.ownCapabilities,
            videoConfig,
            response.call.settings.audio,
            .init()
        )
        webRTCClient?.onSignalConnectionStateChange = handleSignalChannelConnectionStateChange(_:)
        
        let connectOptions = ConnectOptions(iceServers: response.credentials.iceServers)
        try await webRTCClient?.connect(
            callSettings: callSettings,
            videoOptions: videoOptions,
            connectOptions: connectOptions
        )
        let sessionId = webRTCClient?.sessionID ?? ""
        executeOnMain {
            self.call?.state.sessionId = sessionId
            self.call?.update(recordingState: response.call.recording ? .recording : .noRecording)
            self.call?.state.ownCapabilities = response.ownCapabilities
            self.call?.state.update(from: response)
        }
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
                self?.call?.state.participants = participants
            }
        }
    }
    
    private func handleParticipantCountUpdated() {
        webRTCClient?.onParticipantCountUpdated = { [weak self] participantCount in
            DispatchQueue.main.async {
                self?.call?.state.participantCount = participantCount
            }
        }
    }
    
    private func handleSignalChannelConnectionStateChange(_ state: WebSocketConnectionState) {
        switch state {
        case .disconnected(let source):
            log.debug("Signal channel disconnected")
            executeOnMain {
                self.handleSignalChannelDisconnect(source: source)
            }
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
    
    @MainActor private func handleSignalChannelDisconnect(
        source: WebSocketConnectionState.DisconnectionSource,
        isRetry: Bool = false
    ) {
        guard let call = call,
              (call.state.reconnectionStatus != .reconnecting || isRetry),
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
                let sessionId = webRTCClient?.sessionID
                await webRTCClient?.cleanUp()
                log.debug("Waiting to reconnect")
                try? await Task.sleep(nanoseconds: 250_000_000)
                log.debug("Retrying to connect to the call")
                self.call?.update(reconnectionStatus: .reconnecting)
                _ = try await joinCall(
                    create: false,
                    callType: call.callType,
                    callId: call.callId,
                    callSettings: webRTCClient?.callSettings ?? CallSettings(),
                    videoOptions: webRTCClient?.videoOptions ?? VideoOptions(),
                    options: nil,
                    sessionID: sessionId
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
    
    private func joinCall(
        create: Bool,
        callType: String,
        callId: String,
        videoOptions: VideoOptions,
        options: CreateCallOptions? = nil,
        ring: Bool,
        notify: Bool
    ) async throws -> JoinCallResponse {
        let location = try await getLocation()
        let response = try await joinCall(
            callId: callId,
            type: callType,
            location: location,
            options: options,
            create: create,
            ring: ring,
            notify: notify
        )
        return response
    }
    
    private func prefetchLocation() {
        Task {
            self.cachedLocation = try await getLocation()
        }
    }

    private func getLocation() async throws -> String {
        if let cachedLocation {
            return cachedLocation
        }
        return try await LocationFetcher.getLocation()
    }

    private func joinCall(
        callId: String,
        type: String,
        location: String,
        options: CreateCallOptions? = nil,
        create: Bool,
        ring: Bool,
        notify: Bool
    ) async throws -> JoinCallResponse {
        var membersRequest = [MemberRequest]()
        options?.memberIds?.forEach {
            membersRequest.append(.init(userId: $0))
        }
        options?.members?.forEach {
            membersRequest.append($0)
        }
        let callRequest = CallRequest(
            custom: options?.custom,
            members: membersRequest,
            settingsOverride: options?.settings,
            startsAt: options?.startsAt,
            team: options?.team
        )
        let joinCall = JoinCallRequest(
            create: create,
            data: callRequest,
            location: location,
            notify: notify,
            ring: ring
        )
        let joinCallResponse = try await defaultAPI.joinCall(
            type: type,
            id: callId,
            joinCallRequest: joinCall
        )
        return joinCallResponse
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
            _ sessionID: String?,
            _ ownCapabilities: [OwnCapability],
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
                sessionID: $6,
                ownCapabilities: $7,
                videoConfig: $8,
                audioSettings: $9,
                environment: $10
            )
        }
        
        var sfuReconnectionTime: CGFloat = 30
    }
}
