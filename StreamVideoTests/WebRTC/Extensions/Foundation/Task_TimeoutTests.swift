//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class TaskTimeoutTests: XCTestCase {

    func testSuccessfulOperationWithinTimeout() async throws {
        let expectation = XCTestExpectation(description: "Operation completed successfully")

        let task = Task(timeout: 2) {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            expectation.fulfill()
            return "Success"
        }

        let result = try await task.value
        XCTAssertEqual(result, "Success")

        await fulfillment(of: [expectation], timeout: 3)
    }

    func testOperationTimesOut() async throws {
        let task = Task(timeout: 1) {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            return "This should not be reached"
        }

        do {
            _ = try await task.value
            XCTFail("Expected timeout error")
        } catch let error as Task<String, Error>.TimeoutError {
            XCTAssertEqual(error, .timedOut)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testConcurrentTasks() async throws {
        let expectation1 = XCTestExpectation(description: "Task 1 completed")
        let expectation2 = XCTestExpectation(description: "Task 2 completed")

        async let task1 = Task(timeout: 2) {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            expectation1.fulfill()
            return "Task 1"
        }.value

        async let task2 = Task(timeout: 2) {
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            expectation2.fulfill()
            return "Task 2"
        }.value

        let (result1, result2) = try await(task1, task2)

        XCTAssertEqual(result1, "Task 1")
        XCTAssertEqual(result2, "Task 2")

        await fulfillment(of: [expectation1, expectation2], timeout: 3)
    }
}
