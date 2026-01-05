//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A policy implementation where CallKit availability depends on the region.
///
/// This policy disables CallKit in specific regions, identified by their region
/// codes, to comply with regional regulations or restrictions. It utilizes the
/// injected `StreamLocaleProvider` to retrieve the current locale information.
struct CallKitRegionBasedAvailabilityPolicy: CallKitAvailabilityPolicyProtocol {

    /// A provider for locale information.
    @Injected(\.localeProvider) private var localeProvider

    /// A set of region identifiers where CallKit is unavailable.
    ///
    /// This includes both two-letter and three-letter region codes.
    private var unavailableRegions: Set<String> = [
        "CN", // China (two-letter code)
        "CHN" // China (three-letter code)
    ]

    /// Determines if CallKit is available based on the current region.
    ///
    /// - Returns: `true` if CallKit is available; otherwise, `false`.
    /// - Note: If the region cannot be determined, CallKit is considered unavailable.
    var isAvailable: Bool {
        // Retrieve the current region identifier from the locale provider.
        guard let identifier = localeProvider.identifier else {
            return false
        }

        // CallKit is unavailable if the region is part of the restricted set.
        return !unavailableRegions.contains(identifier)
    }
}
