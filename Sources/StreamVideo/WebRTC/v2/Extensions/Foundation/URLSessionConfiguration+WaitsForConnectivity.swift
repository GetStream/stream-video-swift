//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension URLSessionConfiguration {
    /// Toggles the `waitsForConnectivity` property and returns the modified configuration.
    ///
    /// This method provides a convenient way to enable or disable the `waitsForConnectivity`
    /// property of a `URLSessionConfiguration` instance. When enabled, URLSession will wait
    /// for connectivity to become available rather than failing immediately when a device
    /// has no network connection.
    ///
    /// - Parameter enabled: A boolean value that determines whether to enable or disable
    ///   the `waitsForConnectivity` property.
    ///
    /// - Returns: The modified `URLSessionConfiguration` instance, allowing for method chaining.
    ///
    /// - Note: This method modifies the current instance and returns it, which is useful
    ///   for method chaining or fluent interface design patterns.
    ///
    /// - Example:
    ///   ```swift
    ///   let config = URLSessionConfiguration.default
    ///       .toggleWaitsForConnectivity(true)
    ///   ```
    func toggleWaitsForConnectivity(
        _ enabled: Bool
    ) -> URLSessionConfiguration {
        waitsForConnectivity = enabled
        return self
    }
}
