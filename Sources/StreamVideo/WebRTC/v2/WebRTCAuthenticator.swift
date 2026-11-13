//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Protocol defining the authentication process for WebRTC.
protocol WebRTCAuthenticating {

    /// Authenticates the WebRTC connection.
    /// - Parameters:
    ///   - coordinator: The WebRTC coordinator.
    ///   - currentSFU: The current SFU, if any.
    ///   - migratingFromList: A list of SFU edge names that have already been
    ///     rejected for this join flow. Passing this list lets the backend
    ///     avoid assigning the same exhausted SFU again.
    ///   - create: Whether to create a new call.
    ///   - ring: Whether to ring the call.
    ///   - notify: Whether notification side effects should be emitted.
    ///   - options: Additional join/create options sent to the backend.
    ///   - declaresPlaybackCapabilities: Whether the join request declares
    ///     that the client can play HLS.
    /// - Returns: A tuple containing the SFU adapter and join call response.
    ///   The SFU adapter is `nil` when the backend granted HLS playback.
    /// - Throws: An error if authentication fails.
    func authenticate(
        coordinator: WebRTCCoordinator,
        currentSFU: String?,
        migratingFromList: [String]?,
        create: Bool,
        ring: Bool,
        notify: Bool,
        options: CreateCallOptions?,
        declaresPlaybackCapabilities: Bool
    ) async throws -> (sfuAdapter: SFUAdapter?, response: JoinCallResponse)

    /// Awaits the SFU to allow authentication
    /// - Parameter sfuAdapter: The SFU adapter to authenticate with.
    /// - Throws: An error if connection fails.
    func waitForAuthentication(on sfuAdapter: SFUAdapter) async throws

    /// Awaits for the connectionState to the SFU to change to `.connected`.
    /// - Parameter sfuAdapter: The SFU adapter to connect.
    /// - Throws: An error if connection fails.
    func waitForConnect(on sfuAdapter: SFUAdapter) async throws
}

/// Concrete implementation of WebRTCAuthenticating.
struct WebRTCAuthenticator: WebRTCAuthenticating {

    @Injected(\.audioStore) private var audioStore

    /// Authenticates the WebRTC connection.
    /// - Parameters:
    ///   - coordinator: The WebRTC coordinator.
    ///   - currentSFU: The current SFU, if any.
    ///   - migratingFromList: A list of SFU edge names already tried during
    ///     migration retries.
    ///   - create: Whether to create a new call.
    ///   - ring: Whether to ring the call.
    ///   - notify: Whether to notify other participants.
    ///   - options: Additional call creation options for the join request.
    ///   - declaresPlaybackCapabilities: Whether the join request declares
    ///     that the client can play HLS.
    /// - Returns: A tuple containing the SFU adapter and join call response.
    ///   The SFU adapter is `nil` when the backend granted HLS playback.
    /// - Throws: An error if authentication fails.
    func authenticate(
        coordinator: WebRTCCoordinator,
        currentSFU: String?,
        migratingFromList: [String]?,
        create: Bool,
        ring: Bool,
        notify: Bool,
        options: CreateCallOptions?,
        declaresPlaybackCapabilities: Bool
    ) async throws -> (sfuAdapter: SFUAdapter?, response: JoinCallResponse) {
        let response = try await coordinator
            .callAuthentication(
                create,
                ring,
                currentSFU,
                migratingFromList,
                notify,
                options,
                declaresPlaybackCapabilities
            )

        return try await apply(
            response,
            declaresPlaybackCapabilities: declaresPlaybackCapabilities,
            to: coordinator.stateAdapter
        )
    }

    private func apply(
        _ response: JoinCallResponse,
        declaresPlaybackCapabilities: Bool,
        to stateAdapter: isolated WebRTCStateAdapter
    ) async throws -> (sfuAdapter: SFUAdapter?, response: JoinCallResponse) {
        try Task.checkCancellation()

        /// A grant the client did not ask for would end a rejoin or a
        /// migration in HLS playback in the middle of a call.
        if let playback = response.playback {
            guard declaresPlaybackCapabilities else {
                throw ClientError("Received a playback grant that was not requested.")
            }
            _ = try playback.hlsPlaylistURL()
        }

        await stateAdapter.enqueueOwnCapabilities { Set(response.ownCapabilities) }
        // Cleanup can run while capability changes stop screen sharing.
        try Task.checkCancellation()

        /// With an HLS grant the credentials are blank and the client never
        /// connects to an SFU. Skipping the rest keeps the SFU, ICE, stats and
        /// tracing setup out of the HLS path. Audio and video go off, because
        /// a viewer never publishes, and the audio recorder starts when the
        /// call settings have audio on and the session is active.
        if response.playback != nil {
            stateAdapter.enqueueCallSettings {
                $0.withUpdatedAudioState(false).withUpdatedVideoState(false)
            }
            return (nil, response)
        }

        stateAdapter.set(
            token: response.credentials.token
        )
        stateAdapter.set(audioSettings: response.call.settings.audio)
        stateAdapter.set(
            connectOptions: ConnectOptions(
                iceServers: response.credentials.iceServers
            )
        )

        /// Sets the initial call settings for the coordinator's state adapter.
        ///
        /// - First, retrieves the initial call settings, if any, that may have been
        ///   stored previously on the coordinator.
        /// - Then, constructs new call settings based on the remote values received
        ///   from the backend.
        /// - If there are no locally stored settings, defaults to the remote settings.
        /// - If the current audio route is external (e.g., Bluetooth, AirPlay),
        ///   and the settings indicate that the speaker should be on, updates
        ///   the settings to turn the speaker off. This prevents external
        ///   devices from mistakenly having the speaker route enabled.
        /// - Finally, applies the determined call settings to the state adapter.
        let initialCallSettings = stateAdapter.initialCallSettings
        let remoteCallSettings = CallSettings(response.call.settings)
        let callSettings = {
            var result = initialCallSettings ?? remoteCallSettings
            if audioStore.state.currentRoute.isExternal, result.speakerOn {
                result = result.withUpdatedSpeakerState(false)
            }

            if result.audioOn, !response.ownCapabilities.contains(.sendAudio) {
                result = result.withUpdatedAudioState(false)
            }

            if result.videoOn, !response.ownCapabilities.contains(.sendVideo) {
                result = result.withUpdatedVideoState(false)
            }

            return result
        }()

        log.debug("CallSettings when joining speakerOn:\(callSettings.speakerOn)", subsystems: .webRTC)

        stateAdapter.enqueueCallSettings { _ in callSettings }

        stateAdapter.set(
            videoOptions: .init(preferredCameraPosition: {
                switch response.call.settings.video.cameraFacing {
                case .back:
                    return .back
                case .external:
                    return .front
                case .front:
                    return .front
                case .unknown:
                    return .front
                }
            }())
        )

        stateAdapter.set(
            isTracingEnabled: response.statsOptions.enableRtcStats
        )

        let sfuAdapter = SFUAdapter(
            serviceConfiguration: .init(
                url: try unwrap(
                    .init(string: response.credentials.server.url),
                    errorMessage: "Server URL is invalid."
                ),
                apiKey: stateAdapter.apiKey,
                token: stateAdapter.token
            ),
            webSocketConfiguration: .init(
                url: try unwrap(
                    .init(string: response.credentials.server.wsEndpoint),
                    errorMessage: "WebSocket URL is invalid."
                )
            )
        )

        let statsReportingInterval = response.statsOptions.reportingIntervalMs / 1000
        if let statsReporter = stateAdapter.statsAdapter {
            statsReporter.deliveryInterval = TimeInterval(statsReportingInterval)
        } else {
            let statsReporter = WebRTCStatsAdapter(
                sessionID: stateAdapter.sessionID,
                unifiedSessionID: stateAdapter.unifiedSessionId,
                isTracingEnabled: stateAdapter.isTracingEnabled,
                trackStorage: stateAdapter.trackStorage
            )
            statsReporter.deliveryInterval = TimeInterval(statsReportingInterval)
            stateAdapter.set(statsAdapter: statsReporter)
        }

        return (sfuAdapter, response)
    }

    /// Awaits the SFU to allow authentication
    /// - Parameter sfuAdapter: The SFU adapter to authenticate with.
    /// - Throws: An error if connection fails.
    func waitForAuthentication(on sfuAdapter: SFUAdapter) async throws {
        sfuAdapter.connect()
        _ = try await sfuAdapter
            .connectionStatePublisher
            .filter {
                switch $0 {
                case .authenticating:
                    return true
                default:
                    return false
                }
            }
            .nextValue(timeout: WebRTCConfiguration.timeout.authenticate)
    }

    /// Awaits for the connectionState to the SFU to change to `.connected`.
    /// - Parameter sfuAdapter: The SFU adapter to connect.
    /// - Throws: An error if connection fails.
    func waitForConnect(on sfuAdapter: SFUAdapter) async throws {
        _ = try await sfuAdapter
            .connectionStatePublisher
            .filter {
                switch $0 {
                case .connected:
                    return true
                default:
                    return false
                }
            }
            .nextValue(timeout: WebRTCConfiguration.timeout.connect)
    }
}
