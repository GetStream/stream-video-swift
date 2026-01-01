//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class IncomingVideoQualitySettings_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - contains

    func test_contains_givenGroupIsAll_whenSessionIdProvided_thenReturnsTrue() {
        // Given
        let group: IncomingVideoQualitySettings.Group = .all
        let sessionId = "12345"

        // When
        let result = group.contains(sessionId)

        // Then
        XCTAssertTrue(result, "Expected .all group to contain any session ID")
    }

    func test_contains_givenGroupIsCustom_whenSessionIdInSet_thenReturnsTrue() {
        // Given
        let group: IncomingVideoQualitySettings.Group = .custom(sessionIds: ["12345", "67890"])
        let sessionId = "12345"

        // When
        let result = group.contains(sessionId)

        // Then
        XCTAssertTrue(result, "Expected custom group to contain the session ID")
    }

    func test_contains_givenGroupIsCustom_whenSessionIdNotInSet_thenReturnsFalse() {
        // Given
        let group: IncomingVideoQualitySettings.Group = .custom(sessionIds: ["12345", "67890"])
        let sessionId = "54321"

        // When
        let result = group.contains(sessionId)

        // Then
        XCTAssertFalse(result, "Expected custom group to not contain the session ID")
    }

    func test_contains_givenCaseIsNone_whenSessionIdProvided_thenReturnsFalse() {
        // Given
        let settings: IncomingVideoQualitySettings = .none
        let sessionId = "12345"

        // When
        let result = settings.contains(sessionId)

        // Then
        XCTAssertFalse(result, "Expected .none to not contain any session ID")
    }

    func test_contains_givenManualCase_whenSessionIdInGroup_thenReturnsTrue() {
        // Given
        let group: IncomingVideoQualitySettings.Group = .custom(sessionIds: ["12345", "67890"])
        let settings: IncomingVideoQualitySettings = .manual(group: group, targetSize: CGSize(width: 1920, height: 1080))
        let sessionId = "12345"

        // When
        let result = settings.contains(sessionId)

        // Then
        XCTAssertTrue(result, "Expected manual setting to contain the session ID")
    }

    func test_contains_givenManualCase_whenSessionIdNotInGroup_thenReturnsFalse() {
        // Given
        let group: IncomingVideoQualitySettings.Group = .custom(sessionIds: ["12345", "67890"])
        let settings: IncomingVideoQualitySettings = .manual(group: group, targetSize: CGSize(width: 1920, height: 1080))
        let sessionId = "54321"

        // When
        let result = settings.contains(sessionId)

        // Then
        XCTAssertFalse(result, "Expected manual setting to not contain the session ID")
    }

    // MARK: - isVideoDisabled

    func test_isVideoDisabled_givenDisabledCase_whenSessionIdInGroup_thenReturnsTrue() {
        // Given
        let group: IncomingVideoQualitySettings.Group = .custom(sessionIds: ["12345", "67890"])
        let settings: IncomingVideoQualitySettings = .disabled(group: group)
        let sessionId = "12345"

        // When
        let result = settings.isVideoDisabled(for: sessionId)

        // Then
        XCTAssertTrue(result, "Expected video to be disabled for the session ID")
    }

    func test_isVideoDisabled_givenDisabledCase_whenSessionIdNotInGroup_thenReturnsFalse() {
        // Given
        let group: IncomingVideoQualitySettings.Group = .custom(sessionIds: ["12345", "67890"])
        let settings: IncomingVideoQualitySettings = .disabled(group: group)
        let sessionId = "54321"

        // When
        let result = settings.isVideoDisabled(for: sessionId)

        // Then
        XCTAssertFalse(result, "Expected video to not be disabled for the session ID")
    }
}
