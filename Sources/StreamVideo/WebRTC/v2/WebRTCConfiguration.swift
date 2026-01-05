//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Configuration for WebRTC Stack.
enum WebRTCConfiguration {

    struct Timeout {
        var authenticate: TimeInterval
        var connect: TimeInterval
        var join: TimeInterval
        var migrationCompletion: TimeInterval
        var publisherSetUpBeforeNegotiation: TimeInterval

        /// Timeout for authentication in production environment.
        static let production = Timeout(
            authenticate: 30,
            connect: 30,
            join: 30,
            migrationCompletion: 10,
            publisherSetUpBeforeNegotiation: 2
        )

        #if STREAM_TESTS
        /// Timeout for authentication in test environment.
        static let testing = Timeout(
            authenticate: 5,
            connect: 5,
            join: 5,
            migrationCompletion: 5,
            publisherSetUpBeforeNegotiation: 5
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
