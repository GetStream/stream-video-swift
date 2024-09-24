//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Configuration for WebRTC Stack.
enum WebRTCConfiguration {

    struct Timeout {
        var authenticate: TimeInterval
        var connect: TimeInterval
        var join: TimeInterval
        var migrationCompletion: TimeInterval

        /// Timeout for authentication in production environment.
        static let production = Timeout(
            authenticate: 10,
            connect: 10,
            join: 10,
            migrationCompletion: 30
        )

        #if STREAM_TESTS
        /// Timeout for authentication in test environment.
        static let testing = Timeout(
            authenticate: 1,
            connect: 1,
            join: 1,
            migrationCompletion: 1
        )
        #endif
    }

    /// Timeout values for various WebRTC operations.
    static var timeout: Timeout {
        #if STREAM_TESTS
        return .testing
        #else
        return .production
        #endif
    }
}
