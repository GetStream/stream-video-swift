//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

        if create {
            if let callSettings = await coordinator.stateAdapter.initialCallSettings {
                await coordinator.stateAdapter.set(
                    callSettings: callSettings
                )
            } else {
                await coordinator.stateAdapter.set(
                    callSettings: response.call.settings.toCallSettings
                )
            }
        }
        let videoOptions = await coordinator.stateAdapter.videoOptions
        await coordinator.stateAdapter.set(
            videoOptions: videoOptions
                .with(preferredCameraPosition: {
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
        if let statsReporter = await coordinator.stateAdapter.statsReporter {
            statsReporter.interval = TimeInterval(statsReportingInterval)
        } else {
            let statsReporter = WebRTCStatsReporter(
                sessionID: await coordinator.stateAdapter.sessionID
            )
            statsReporter.interval = TimeInterval(statsReportingInterval)
            await coordinator.stateAdapter.set(statsReporter: statsReporter)
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
