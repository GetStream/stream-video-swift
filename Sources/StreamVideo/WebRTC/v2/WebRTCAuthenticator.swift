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
        ring: Bool
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
        ring: Bool
    ) async throws -> (sfuAdapter: SFUAdapter, response: JoinCallResponse) {
        let response = try await coordinator
            .callAuthenticator
            .authenticate(
                create: create,
                ring: ring,
                migratingFrom: currentSFU
            )

        await coordinator.stateAdapter.set(
            token: response.credentials.token
        )
        await coordinator.stateAdapter.set(Set(response.ownCapabilities))
        await coordinator.stateAdapter.set(response.call.settings.audio)
        await coordinator.stateAdapter.set(
            ConnectOptions(
                iceServers: response.credentials.iceServers
            )
        )

        if create {
            if let callSettings = await coordinator.stateAdapter.initialCallSettings {
                await coordinator.stateAdapter.set(
                    callSettings
                )
            } else {
                await coordinator.stateAdapter.set(
                    response.call.settings.toCallSettings
                )
            }
        }
        await coordinator.stateAdapter.set(
            VideoOptions(
                targetResolution: response.call.settings.video.targetResolution
            )
        )

        let sfuAdapter = SFUAdapter(
            serviceConfiguration: .init(
                url: .init(string: response.credentials.server.url)!,
                apiKey: coordinator.stateAdapter.apiKey,
                token: await coordinator.stateAdapter.token
            ),
            webSocketConfiguration: .init(
                url: .init(string: response.credentials.server.wsEndpoint)!,
                eventNotificationCenter: .init()
            )
        )

        let statsReporter = await coordinator.stateAdapter.statsReporter
        statsReporter?.interval = TimeInterval(
            response.statsOptions.reportingIntervalMs / 1000
        )

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
            .nextValue(timeout: WebRTCConfiguration.Timeout.authenticate)
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
            .nextValue(timeout: WebRTCConfiguration.Timeout.connect)
    }
}
