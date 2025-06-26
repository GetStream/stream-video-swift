//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class Publisher_NextValue_Tests: XCTestCase, @unchecked Sendable {

    func test_nextValue_success() async throws {
        // Given
        let publisher = Just(1).eraseToAnyPublisher()

        // When
        let value = try await publisher.nextValue()

        // Then
        XCTAssertEqual(value, 1)
    }

    func test_nextValue_withTimeout() async throws {
        // Given
        let publisher = PassthroughSubject<Int, Never>()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            publisher.send(1)
        }

        // When
        let value = try await publisher.nextValue(timeout: 0.2)

        // Then
        XCTAssertEqual(value, 1)
    }

    func test_nextValue_timeout() async throws {
        // Given
        let publisher = PassthroughSubject<Int, Never>()

        // When
        do {
            _ = try await publisher.nextValue(timeout: 0.1)
            XCTFail("Should have thrown an error")
        } catch {
            // Then
            XCTAssertTrue(error is ClientError)
        }
    }

    func test_nextValue_dropFirst() async throws {
        // Given
        let publisher = [1, 2, 3].publisher

        // When
        let value = try await publisher.nextValue(dropFirst: 1)

        // Then
        XCTAssertEqual(value, 2)
    }
}
