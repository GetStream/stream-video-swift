//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class CallKitRegionBasedAvailabilityPolicy_Tests: XCTestCase, @unchecked Sendable {

    private lazy var mockLocaleProvider: MockLocaleProvider! = .init()
    private lazy var subject: CallKitRegionBasedAvailabilityPolicy! = .init()

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        InjectedValues[\.localeProvider] = mockLocaleProvider
    }

    override func tearDown() {
        mockLocaleProvider = nil
        subject = nil
        // Ensure no lingering dependency overrides.
        InjectedValues[\.localeProvider] = StreamLocaleProvider()
        super.tearDown()
    }

    // MARK: - isAvailable

    func test_isAvailable_whenRegionIsUnavailable_returnsFalse() {
        // Given
        mockLocaleProvider.stubIdentifier = "CN"

        // When
        let result = subject.isAvailable

        // Then
        XCTAssertFalse(result, "CallKit should not be available in CN.")
    }

    func test_isAvailable_whenRegionIsAvailable_returnsTrue() {
        // Given
        mockLocaleProvider.stubIdentifier = "US"

        // When
        let result = subject.isAvailable

        // Then
        XCTAssertTrue(result, "CallKit should be available in US.")
    }

    func test_isAvailable_whenRegionIsNil_returnsFalse() {
        // Given
        mockLocaleProvider.stubIdentifier = nil

        // When
        let result = subject.isAvailable

        // Then
        XCTAssertFalse(result, "CallKit should not be available when the region is nil.")
    }

    func test_isAvailable_whenRegionIsThreeLetterUnavailable_returnsFalse() {
        // Given
        mockLocaleProvider.stubIdentifier = "CHN"

        // When
        let result = subject.isAvailable

        // Then
        XCTAssertFalse(result, "CallKit should not be available in CHN.")
    }

    func test_isAvailable_whenRegionIsThreeLetterAvailable_returnsTrue() {
        // Given
        mockLocaleProvider.stubIdentifier = "GBR"

        // When
        let result = subject.isAvailable

        // Then
        XCTAssertTrue(result, "CallKit should be available in GBR.")
    }
}

final class MockLocaleProvider: LocaleProviding {
    var stubIdentifier: String?

    var identifier: String? { stubIdentifier }
}
