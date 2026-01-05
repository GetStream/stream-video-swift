//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Configuration settings for call operations.
///
/// This enum provides timeout values and other configuration settings
/// for various call operations such as joining, accepting, and rejecting calls.
enum CallConfiguration {

    /// Timeout settings for different call operations.
    struct Timeout {
        /// Timeout duration for joining a call in seconds.
        var join: TimeInterval
        
        /// Timeout duration for accepting a call in seconds.
        var accept: TimeInterval
        
        /// Timeout duration for rejecting a call in seconds.
        var reject: TimeInterval

        /// Timeout values for authentication in production environment.
        ///
        /// These values are used when the app is running in production mode.
        static let production = Timeout(
            join: 30,
            accept: 10,
            reject: 10
        )

        #if STREAM_TESTS
        /// Timeout values for authentication in test environment.
        ///
        /// These values are used when the app is running in test mode.
        /// They are shorter than production values to speed up testing.
        static let testing = Timeout(
            join: 10,
            accept: 10,
            reject: 10
        )
        #endif
    }

    /// Timeout values for various Call operations.
    ///
    /// This property returns the appropriate timeout values based on the
    /// current build configuration (test or production).
    nonisolated(unsafe) static var timeout: Timeout = {
        #if STREAM_TESTS
        return .testing
        #else
        return .production
        #endif
    }()
}
