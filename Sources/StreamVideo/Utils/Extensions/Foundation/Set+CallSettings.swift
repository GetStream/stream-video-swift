//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Set where Element == OwnCapability {
    /// Returns whether the capability set allows the given `CallSettings`.
    ///
    /// The check is intentionally strict:
    /// - `audioOn == true` requires `.sendAudio`
    /// - `videoOn == true` requires `.sendVideo`
    ///
    /// This helper is used as a guardrail before applying local call-settings
    /// updates so UI and transport state cannot drift into an unauthorized
    /// state.
    ///
    /// - Parameter callSettings: The candidate call settings to validate.
    /// - Returns: `true` when all required capabilities are present.
    func allows(callSettings: CallSettings) -> Bool {
        if callSettings.audioOn, !contains(.sendAudio) {
            return false
        } else if callSettings.videoOn, !contains(.sendVideo) {
            return false
        }

        return true
    }
}
