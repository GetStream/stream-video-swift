//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Configuration for WebRTC Stack.
enum WebRTCConfiguration {

    /// Timeout values used by WebRTC join/reconnect flows.
    struct Timeout {
        /// Maximum time to wait for authentication response.
        var authenticate: TimeInterval
        /// Maximum time to wait for initial WebSocket connection.
        var connect: TimeInterval
        /// Maximum time to wait for SFU join response.
        var join: TimeInterval
        /// Maximum time to wait for migration completion event.
        var migrationCompletion: TimeInterval
        /// Maximum time to wait for publisher setup before negotiation.
        var publisherSetUpBeforeNegotiation: TimeInterval
        /// Maximum time the join flow waits for audio-session setup to complete.
        var audioSessionConfigurationCompletion: TimeInterval
        /// Maximum time to wait in joined state before forcing a rejoin when
        /// the audio session never becomes fully ready.
        var audioSessionReadinessWatchdog: TimeInterval
        /// Maximum time to wait for both peer connections to reach
        /// `.connected` after the SFU join flow succeeds.
        var peerConnectionReadiness: TimeInterval

        /// Timeout for authentication in production environment.
        static let production = Timeout(
            authenticate: 30,
            connect: 30,
            join: 30,
            migrationCompletion: 10,
            publisherSetUpBeforeNegotiation: 2,
            audioSessionConfigurationCompletion: 2,
            audioSessionReadinessWatchdog: 10,
            peerConnectionReadiness: 5
        )

        #if STREAM_TESTS
        /// Timeout for authentication in test environment.
        static let testing = Timeout(
            authenticate: 5,
            connect: 5,
            join: 5,
            migrationCompletion: 5,
            publisherSetUpBeforeNegotiation: 5,
            audioSessionConfigurationCompletion: 5,
            audioSessionReadinessWatchdog: 5,
            peerConnectionReadiness: 5
        )
        #endif
    }

    /// Timeout values for various WebRTC operations.
    nonisolated(unsafe) static var timeout: Timeout = {
        #if STREAM_TESTS
        return .testing
        #else
        return .production
        #endif
    }()
}
