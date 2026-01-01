//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class Publisher_NextTests: XCTestCase, @unchecked Sendable {

    func testNextValueWithoutSkipping() async throws {
        let expectedValue = 42
        let publisher = Just(expectedValue)

        do {
            let value = try await publisher.nextValue()
            XCTAssertEqual(value, expectedValue, "Received value should match the expected value")
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }

    func testNextValueWithSkipping() async throws {
        let values = [10, 20, 30, 40, 50]
        let expectedValue = 40
        let publisher = values.publisher

        do {
            let value = try await publisher.nextValue(dropFirst: 3)
            XCTAssertEqual(value, expectedValue, "Received value should match the expected value after skipping")
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }

    func testNextValueThrowsErrorOnFailure() async {
        enum TestError: Error {
            case test
        }

        let publisher = Fail<Int, Error>(error: TestError.test)

        do {
            _ = try await publisher.nextValue()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TestError, "Error should be of type TestError")
        }
    }
}
