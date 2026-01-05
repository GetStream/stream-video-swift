//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol that defines the requirements for a locale provider.
///
/// This protocol abstracts the retrieval of a region identifier, allowing
/// flexibility and testability in components that depend on locale information.
protocol LocaleProviding {

    /// The region identifier of the current locale.
    ///
    /// - Returns: A string representing the region identifier (e.g., "US" or "GB"),
    ///            or `nil` if the region cannot be determined.
    var identifier: String? { get }
}

/// A provider for accessing the current locale's region identifier.
///
/// This class abstracts locale information, offering compatibility for different
/// iOS versions.
final class StreamLocaleProvider: LocaleProviding {

    /// Retrieves the region identifier for the current locale.
    ///
    /// - For iOS 16 and later, it uses the `region` property.
    /// - For earlier versions, it falls back to `regionCode`.
    ///
    /// - Returns: A string representing the region identifier, or `nil` if unavailable.
    var identifier: String? {
        if #available(iOS 16, *) {
            // Retrieve the region identifier for iOS 16 and later.
            return NSLocale.current.region?.identifier
        } else {
            // Retrieve the region code for earlier iOS versions.
            return NSLocale.current.regionCode
        }
    }
}

enum LocaleProvidingKey: InjectionKey {
    /// The current value of the `StreamLocaleProvider` used for dependency injection.
    nonisolated(unsafe) static var currentValue: LocaleProviding = StreamLocaleProvider()
}

/// Extension of `InjectedValues` to provide access to the `StreamLocaleProvider`.
extension InjectedValues {

    /// The locale provider, used to access region information within the app.
    ///
    /// This value can be overridden for testing or specific use cases.
    var localeProvider: LocaleProviding {
        get { Self[LocaleProvidingKey.self] }
        set { Self[LocaleProvidingKey.self] = newValue }
    }
}
