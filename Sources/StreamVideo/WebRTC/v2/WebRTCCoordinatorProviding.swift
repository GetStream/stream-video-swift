//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol that defines a factory for creating instances of `WebRTCCoordinator`.
/// The factory requires user details, API key, call identifier, video
/// configuration, and an authentication handler.
protocol WebRTCCoordinatorProviding {

    /// Builds a `WebRTCCoordinator` instance.
    ///
    /// - Parameters:
    ///   - user: The user participating in the WebRTC session.
    ///   - apiKey: The API key for authenticating WebRTC calls.
    ///   - callCid: The call identifier (callCid) for the session.
    ///   - videoConfig: The video configuration settings for the session.
    ///   - clientEventReporter: Reports client-side join-lifecycle events.
    ///   - callAuthentication: A closure to handle authentication when
    ///     joining the call.
    /// - Returns: An instance of `WebRTCCoordinator`.
    func buildCoordinator(
        user: User,
        apiKey: String,
        callCid: String,
        videoConfig: VideoConfig,
        callSettings: CallSettings,
        clientEventReporter: ClientEventReporting,
        callAuthentication: @escaping WebRTCCoordinator.AuthenticationHandler
    ) -> WebRTCCoordinator
}

/// A concrete implementation of the `WebRTCCoordinatorProviding` protocol.
/// The `WebRTCCoordinatorFactory` provides an implementation of the
/// `buildCoordinator` method that creates and returns a `WebRTCCoordinator`.
struct WebRTCCoordinatorFactory: WebRTCCoordinatorProviding {

    /// An optional preconfigured factory forwarded to each coordinator.
    ///
    /// A `nil` value preserves the default production WebRTC audio and video
    /// pipeline.
    private let peerConnectionFactory: PeerConnectionFactory?

    /// Creates a coordinator factory with an optional peer-connection factory
    /// override.
    ///
    /// - Parameter peerConnectionFactory: A preconfigured factory to forward
    ///   to coordinators, or `nil` to let each coordinator build its default.
    init(peerConnectionFactory: PeerConnectionFactory? = nil) {
        self.peerConnectionFactory = peerConnectionFactory
    }

    /// Builds and returns a `WebRTCCoordinator` using the provided parameters.
    ///
    /// - Parameters:
    ///   - user: The user participating in the WebRTC session.
    ///   - apiKey: The API key for authenticating WebRTC calls.
    ///   - callCid: The call identifier (callCid) for the session.
    ///   - videoConfig: The video configuration settings for the session.
    ///   - callAuthentication: A closure to handle authentication when
    ///     joining the call.
    /// - Returns: A newly initialized `WebRTCCoordinator` instance.
    /// - Note: Uses the ``StreamRTCPeerConnectionCoordinatorFactory`` for the provided
    ///  `RTCPeerConnectionCoordinatorProviding`.
    func buildCoordinator(
        user: User,
        apiKey: String,
        callCid: String,
        videoConfig: VideoConfig,
        callSettings: CallSettings,
        clientEventReporter: ClientEventReporting,
        callAuthentication: @escaping WebRTCCoordinator.AuthenticationHandler
    ) -> WebRTCCoordinator {
        .init(
            user: user,
            apiKey: apiKey,
            callCid: callCid,
            videoConfig: videoConfig,
            callSettings: callSettings,
            clientEventReporter: clientEventReporter,
            peerConnectionFactory: peerConnectionFactory,
            callAuthentication: callAuthentication
        )
    }
}
