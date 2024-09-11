//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Configuration for WebRTC Stack.
enum WebRTCConfiguration {

    /// Timeout values for various WebRTC operations.
    enum Timeout {
        #if STREAM_TESTS
        /// Timeout for authentication in test environment.
        static let authenticate: TimeInterval = 1

        /// Timeout for connection in test environment.
        static let connect: TimeInterval = 1

        /// Timeout for joining in test environment.
        static let join: TimeInterval = 1

        /// Timeout for migration completion in test environment.
        static let migrationCompletion: TimeInterval = 1
        #else
        /// Timeout for authentication in production environment.
        static let authenticate: TimeInterval = 5

        /// Timeout for connection in production environment.
        static let connect: TimeInterval = 5

        /// Timeout for joining in production environment.
        static let join: TimeInterval = 10

        /// Timeout for migration completion in production environment.
        static let migrationCompletion: TimeInterval = 7
        #endif
    }
}
