//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Combine
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
    private var currentSFU: String?
    private var statsCancellable: AnyCancellable?
    
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
    ///  - options: create call options
    ///  - migratingFrom: if SFU migration is being performed
    ///  - ring: whether ringing events should be handled
    ///  - notify: whether uses should be notified about the call
    /// - Returns: a newly created `Call`.
    @discardableResult
    func joinCall(
        create: Bool = true,
        callType: String,
        callId: String,
        callSettings: CallSettings?,
        options: CreateCallOptions? = nil,
        migratingFrom: String? = nil,
        sessionID: String? = nil,
        ring: Bool = false,
        notify: Bool = false
    ) async throws -> JoinCallResponse {
        let response = try await joinCall(
            create: create,
            callType: callType,
            callId: callId,
            options: options,
            migratingFrom: migratingFrom,
            ring: ring,
            notify: notify
        )

        self.currentSFU = response.credentials.server.edgeName
        let settings = callSettings ?? response.call.settings.toCallSettings
        
        try await connectToEdge(
            response,
            sessionID: sessionID,
            callType: callType,
            callId: callId,
            callSettings: settings,
            ring: ring,
            migratingFrom: migratingFrom
        )
        
        setupStatsTimer()
        
        return response
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
    func changeCameraMode(position: CameraPosition) async throws {
        try await webRTCClient?.changeCameraMode(position: position)
    }
    
    /// Changes the speaker state.
    /// - Parameter isEnabled: whether the speaker should be enabled.
    func changeSpeakerState(isEnabled: Bool) async throws {
        let webRTCClient = try currentWebRTCClient()
        try await webRTCClient.changeSpeakerState(isEnabled: isEnabled)
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
    
    func startScreensharing(type: ScreensharingType) async throws {
        let webRTCClient = try currentWebRTCClient()
        try await webRTCClient.startScreensharing(type: type)
    }
    
    func stopScreensharing() async throws {
        let webRTCClient = try currentWebRTCClient()
        try await webRTCClient.stopScreensharing()
    }
    
    func changePinState(
        isEnabled: Bool,
        sessionId: String
    ) async throws {
        let webRTCClient = try currentWebRTCClient()
        try await webRTCClient.changePinState(
            isEnabled: isEnabled,
            sessionId: sessionId
        )
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

    /// Initiates a focus operation at a specific point on the camera's view.
    ///
    /// This method attempts to focus the camera at the given point by calling the `focus(at:)` 
    /// method on the current WebRTC client. The focus point is specified as a `CGPoint` within the
    /// coordinate space of the view.
    ///
    /// - Parameter point: A `CGPoint` value representing the location within the view where the 
    /// camera should attempt to focus. The coordinate space of the point is typically normalized to the
    /// range [0, 1], where (0, 0) represents the top-left corner of the view, and (1, 1) represents the
    /// bottom-right corner.
    /// - Throws: An error if the focus operation cannot be completed. This might occur if there is no 
    /// current WebRTC client available, if the camera does not support tap to focus, or if an internal error
    /// occurs within the WebRTC client.
    ///
    /// - Note: Before calling this method, ensure that the device's camera supports tap to focus 
    /// functionality and that the current WebRTC client is properly configured and connected. Otherwise,
    /// the method may throw an error.
   func focus(at point: CGPoint) throws {
       try currentWebRTCClient().focus(at: point)
   }

    /// Cleans up the call controller.
    func cleanUp() {
        guard call != nil else { return }
        call = nil
        statsCancellable?.cancel()
        statsCancellable = nil
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
        ring: Bool,
        migratingFrom: String?
    ) async throws {
        if let migratingFrom {
            executeOnMain { [weak self] in
                self?.call?.state.reconnectionStatus = .migrating
            }
            webRTCClient?.prepareForMigration(
                url: response.credentials.server.url,
                token: response.credentials.token,
                webSocketURL: response.credentials.server.wsEndpoint,
                fromSfuName: migratingFrom
            )
        } else {
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
            webRTCClient?.onSignalConnectionStateChange = { [weak self] state in
                self?.handleSignalChannelConnectionStateChange(state)
            }
            webRTCClient?.onSessionMigrationEvent = { [weak self] in
                self?.handleSessionMigrationEvent()
            }
            webRTCClient?.onSessionMigrationCompleted = { [weak self] in
                self?.call?.update(reconnectionStatus: .connected)
            }
        }
        
        let videoOptions = VideoOptions(
            targetResolution: response.call.settings.video.targetResolution
        )
        let connectOptions = ConnectOptions(iceServers: response.credentials.iceServers)
        try await webRTCClient?.connect(
            callSettings: callSettings,
            videoOptions: videoOptions,
            connectOptions: connectOptions,
            migrating: migratingFrom != nil
        )
        let sessionId = webRTCClient?.sessionID ?? ""
        executeOnMain { [weak self] in
            self?.call?.state.sessionId = sessionId
            self?.call?.update(recordingState: response.call.recording ? .recording : .noRecording)
            self?.call?.state.ownCapabilities = response.ownCapabilities
            self?.call?.state.update(from: response)
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
                self?.call?.state.participantsMap = participants
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
            executeOnMain { [weak self] in
                self?.handleSignalChannelDisconnect(source: source)
            }
        case .connected(healthCheckInfo: _):
            log.debug("Signal channel connected")
            if reconnectionDate != nil {
                reconnectionDate = nil
            }
            executeOnMain { [weak self] in
                guard let self else { return }
                let status = self.call?.state.reconnectionStatus
                if status != .migrating {
                    self.call?.update(reconnectionStatus: .connected)
                }
            }
        default:
            log.debug("Signal connection state changed to \(state)")
        }
    }
    
    @MainActor private func handleSignalChannelDisconnect(
        source: WebSocketConnectionState.DisconnectionSource,
        isRetry: Bool = false
    ) {
        guard let call = call, call.state.reconnectionStatus != .migrating else {
            return
        }
        guard (call.state.reconnectionStatus != .reconnecting || isRetry),
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
                    options: nil,
                    migratingFrom: nil,
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
    
    private func handleSessionMigrationEvent() {
        Task {
            let state = await call?.state.reconnectionStatus
            if state == .migrating {
                log.debug("Migration already in progress")
                return
            }
            try await joinCall(
                callType: callType,
                callId: callId,
                callSettings: call?.state.callSettings ?? CallSettings(),
                migratingFrom: currentSFU,
                sessionID: webRTCClient?.sessionID,
                ring: false,
                notify: false
            )
        }
    }
    
    private func joinCall(
        create: Bool,
        callType: String,
        callId: String,
        options: CreateCallOptions? = nil,
        migratingFrom: String?,
        ring: Bool,
        notify: Bool
    ) async throws -> JoinCallResponse {
        let location = try await getLocation()
        let response = try await joinCall(
            callId: callId,
            type: callType,
            location: location,
            options: options,
            migratingFrom: migratingFrom,
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
        migratingFrom: String?,
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
            migratingFrom: migratingFrom,
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
    
    private func setupStatsTimer() {
        statsCancellable?.cancel()
        statsCancellable = Foundation.Timer.publish(
            every: 5,
            on: .main,
            in: .default
        )
        .autoconnect()
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.collectStats()
        }
    }
    
    private func collectStats() {
        Task {
            let stats = try await webRTCClient?.collectStats()
            await call?.state.update(statsReport: stats)
        }
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
