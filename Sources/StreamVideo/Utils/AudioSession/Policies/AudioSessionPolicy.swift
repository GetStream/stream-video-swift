//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Defines a policy for configuring the audio session.
public protocol AudioSessionPolicy: Sendable {

    /// Returns the audio session configuration for the given call settings
    /// and own capabilities.
    ///
    /// - Parameters:
    ///   - callSettings: The current call settings.
    ///   - ownCapabilities: The set of the user's own audio capabilities.
    /// - Returns: The audio session configuration.
    func configuration(
        for callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>
    ) -> AudioSessionConfiguration
}
