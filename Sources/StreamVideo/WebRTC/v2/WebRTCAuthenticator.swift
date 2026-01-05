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
    ///   - create: Whether to create a new call.
    ///   - ring: Whether to ring the call.
    /// - Returns: A tuple containing the SFU adapter and join call response.
    /// - Throws: An error if authentication fails.
    func authenticate(
        coordinator: WebRTCCoordinator,
        currentSFU: String?,
        create: Bool,
        ring: Bool,
        notify: Bool,
        options: CreateCallOptions?
    ) async throws -> (sfuAdapter: SFUAdapter, response: JoinCallResponse)

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
    ///   - create: Whether to create a new call.
    ///   - ring: Whether to ring the call.
    /// - Returns: A tuple containing the SFU adapter and join call response.
    /// - Throws: An error if authentication fails.
    func authenticate(
        coordinator: WebRTCCoordinator,
        currentSFU: String?,
        create: Bool,
        ring: Bool,
        notify: Bool,
        options: CreateCallOptions?
    ) async throws -> (sfuAdapter: SFUAdapter, response: JoinCallResponse) {
        let response = try await coordinator
            .callAuthentication(
                create,
                ring,
                currentSFU,
                notify,
                options
            )

        await coordinator.stateAdapter.set(
            token: response.credentials.token
        )
        await coordinator.stateAdapter.set(ownCapabilities: Set(response.ownCapabilities))
        await coordinator.stateAdapter.set(audioSettings: response.call.settings.audio)
        await coordinator.stateAdapter.set(
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
        let initialCallSettings = await coordinator.stateAdapter.initialCallSettings
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

        await coordinator
            .stateAdapter
            .enqueueCallSettings { _ in callSettings }

        await coordinator.stateAdapter.set(
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

        await coordinator.stateAdapter.set(
            isTracingEnabled: response.statsOptions.enableRtcStats
        )

        let sfuAdapter = SFUAdapter(
            serviceConfiguration: .init(
                url: try unwrap(
                    .init(string: response.credentials.server.url),
                    errorMessage: "Server URL is invalid."
                ),
                apiKey: coordinator.stateAdapter.apiKey,
                token: await coordinator.stateAdapter.token
            ),
            webSocketConfiguration: .init(
                url: try unwrap(
                    .init(string: response.credentials.server.wsEndpoint),
                    errorMessage: "WebSocket URL is invalid."
                ),
                eventNotificationCenter: .init()
            )
        )

        let statsReportingInterval = response.statsOptions.reportingIntervalMs / 1000
        if let statsReporter = await coordinator.stateAdapter.statsAdapter {
            statsReporter.deliveryInterval = TimeInterval(statsReportingInterval)
        } else {
            let statsReporter = WebRTCStatsAdapter(
                sessionID: await coordinator.stateAdapter.sessionID,
                unifiedSessionID: coordinator.stateAdapter.unifiedSessionId,
                isTracingEnabled: await coordinator.stateAdapter.isTracingEnabled,
                trackStorage: coordinator.stateAdapter.trackStorage
            )
            statsReporter.deliveryInterval = TimeInterval(statsReportingInterval)
            await coordinator.stateAdapter.set(statsAdapter: statsReporter)
        }

        return (sfuAdapter, response)
    }

    /// Awaits the SFU to allow authentication
    /// - Parameter sfuAdapter: The SFU adapter to authenticate with.
    /// - Throws: An error if connection fails.
    func waitForAuthentication(on sfuAdapter: SFUAdapter) async throws {
        sfuAdapter.connect()
        _ = try await sfuAdapter
            .$connectionState
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
            .$connectionState
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
