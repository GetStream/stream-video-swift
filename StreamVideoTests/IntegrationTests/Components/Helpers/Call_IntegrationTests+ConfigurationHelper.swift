//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

extension Call_IntegrationTests.Helpers {
    /// Applies the timeouts the integration scenarios need and restores the
    /// previous ones once a scenario finishes.
    ///
    /// Integration tests hit real endpoints, so they run with the production
    /// timeouts instead of the shorter testing ones. Both
    /// ``WebRTCConfiguration/timeout`` and ``CallConfiguration/timeout`` are
    /// process-wide, so the overrides are applied when a scenario starts and
    /// reverted when it is dismantled. Leaving them applied would make every
    /// suite running later in the same process wait for production timeouts,
    /// which outlive the shorter expectations those suites rely on.
    struct ConfigurationHelper: Sendable {

        /// Timeouts replaced by ``activate()``, restored by ``dismantle()``.
        ///
        /// Stored statically because the values they restore are process-wide,
        /// while `Helpers` is a value type that scenarios copy around.
        private nonisolated(unsafe) static var previousWebRTCTimeout: WebRTCConfiguration.Timeout?

        private nonisolated(unsafe) static var previousCallTimeout: CallConfiguration.Timeout?

        private let webRTCConfiguration: WebRTCConfiguration.Timeout
        private let callConfiguration: CallConfiguration.Timeout

        init(
            webRTCConfiguration: WebRTCConfiguration.Timeout = .production,
            callConfiguration: CallConfiguration.Timeout = .production
        ) {
            self.webRTCConfiguration = webRTCConfiguration
            self.callConfiguration = callConfiguration
        }

        /// Overrides the shared timeouts, keeping the values active before it.
        ///
        /// Calling this while the overrides are already applied does nothing,
        /// so scenarios building more than one flow still restore the
        /// timeouts they started with.
        func activate() {
            guard Self.previousWebRTCTimeout == nil else { return }
            Self.previousWebRTCTimeout = WebRTCConfiguration.timeout
            Self.previousCallTimeout = CallConfiguration.timeout
            WebRTCConfiguration.timeout = webRTCConfiguration
            CallConfiguration.timeout = callConfiguration
        }

        /// Restores the timeouts captured by ``activate()``.
        func dismantle() {
            if let previousWebRTCTimeout = Self.previousWebRTCTimeout {
                WebRTCConfiguration.timeout = previousWebRTCTimeout
            }
            if let previousCallTimeout = Self.previousCallTimeout {
                CallConfiguration.timeout = previousCallTimeout
            }
            Self.previousWebRTCTimeout = nil
            Self.previousCallTimeout = nil
        }
    }
}
