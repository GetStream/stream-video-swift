//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class URLSessionConfigurationTests: XCTestCase, @unchecked Sendable {

    func testToggleWaitsForConnectivityEnabled() {
        let config = URLSessionConfiguration.default

        // Ensure initial state is false
        config.waitsForConnectivity = false

        let modifiedConfig = config.toggleWaitsForConnectivity(true)

        XCTAssertTrue(modifiedConfig.waitsForConnectivity, "waitsForConnectivity should be true")
        XCTAssertTrue(config.waitsForConnectivity, "Original config should also be modified")
        XCTAssertTrue(modifiedConfig === config, "Should return the same instance")
    }

    func testToggleWaitsForConnectivityDisabled() {
        let config = URLSessionConfiguration.default

        // Ensure initial state is true
        config.waitsForConnectivity = true

        let modifiedConfig = config.toggleWaitsForConnectivity(false)

        XCTAssertFalse(modifiedConfig.waitsForConnectivity, "waitsForConnectivity should be false")
        XCTAssertFalse(config.waitsForConnectivity, "Original config should also be modified")
        XCTAssertTrue(modifiedConfig === config, "Should return the same instance")
    }

    func testToggleWaitsForConnectivityChaining() {
        let config = URLSessionConfiguration.default
            .toggleWaitsForConnectivity(true)
            .toggleWaitsForConnectivity(false)
            .toggleWaitsForConnectivity(true)

        XCTAssertTrue(config.waitsForConnectivity, "Final state should be true")
    }

    func testToggleWaitsForConnectivityWithDifferentConfigurations() {
        let defaultConfig = URLSessionConfiguration.default.toggleWaitsForConnectivity(true)
        let ephemeralConfig = URLSessionConfiguration.ephemeral.toggleWaitsForConnectivity(true)

        XCTAssertTrue(defaultConfig.waitsForConnectivity, "Default configuration should have waitsForConnectivity set to true")
        XCTAssertTrue(ephemeralConfig.waitsForConnectivity, "Ephemeral configuration should have waitsForConnectivity set to true")
    }
}
