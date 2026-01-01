//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

/// Comprehensive tests for Task+Timeout extension.
///
/// Tests cover:
/// - Successful operations within timeout
/// - Timeout scenarios
/// - Concurrent task handling
/// - Edge cases and error handling
final class TaskTimeoutTests: XCTestCase, @unchecked Sendable {
    
    // MARK: - Basic Functionality Tests
    
    /// Tests that a task completes successfully within the timeout period.
    func test_successfulOperation_withinTimeout() async throws {
        // Given
        let expectedResult = "Success"
        let operationDuration: TimeInterval = 0.5
        let timeout: TimeInterval = 2.0
        
        // When
        let task = Task(timeoutInSeconds: timeout) {
            try await Task.sleep(nanoseconds: UInt64(operationDuration * 1_000_000_000))
            return expectedResult
        }
        
        let result = try await task.value
        
        // Then
        XCTAssertEqual(result, expectedResult, "Task should return expected result")
    }
    
    /// Tests that a task throws timeout error when exceeding the timeout period.
    func test_operation_timesOut() async throws {
        // Given
        let operationDuration: TimeInterval = 2.0
        let timeout: TimeInterval = 0.5
        
        // When/Then
        let task = Task(timeoutInSeconds: timeout) {
            try await Task.sleep(nanoseconds: UInt64(operationDuration * 1_000_000_000))
            return "This should not be reached"
        }
        
        do {
            _ = try await task.value
            XCTFail("Expected timeout error but operation succeeded")
        } catch let error as ClientError {
            XCTAssertTrue(
                error.localizedDescription.contains("timed out"),
                "Error should indicate timeout"
            )
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    /// Tests immediate return for operations that complete instantly.
    func test_immediateOperation_completes() async throws {
        // Given
        let expectedResult = 42
        let timeout: TimeInterval = 1.0
        
        // When
        let task = Task(timeoutInSeconds: timeout) {
            // No delay, immediate return
            expectedResult
        }
        
        let result = try await task.value
        
        // Then
        XCTAssertEqual(result, expectedResult, "Immediate operation should complete")
    }
    
    // MARK: - Concurrent Task Tests
    
    /// Tests multiple concurrent tasks with different timeouts.
    func test_concurrentTasks_differentTimeouts() async throws {
        // Given
        let results = await withTaskGroup(of: Result<String, Error>.self) { group in
            // Task that completes successfully
            group.addTask {
                do {
                    return .success(try await Task(timeoutInSeconds: 2.0) {
                        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        return "Task 1"
                    }.value)
                } catch {
                    return .failure(ClientError("Task 1"))
                }
            }
            
            // Task that times out
            group.addTask {
                do {
                    return .success(try await Task(timeoutInSeconds: 0.5) {
                        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                        return "Task 2"
                    }.value)
                } catch {
                    return .failure(ClientError("Task 2"))
                }
            }
            
            // Task that completes quickly
            group.addTask {
                do {
                    return .success(try await Task(timeoutInSeconds: 1.0) {
                        return "Task 3"
                    }.value)
                } catch {
                    return .failure(ClientError("Task 3"))
                }
            }
            
            var collectedResults: [Result<String, Error>] = []
            for await result in group {
                collectedResults.append(result)
            }
            return collectedResults
        }
        
        // Then
        XCTAssertEqual(results.count, 3, "Should have 3 results")

        for result in results {
            switch result {
            case let .success(value):
                switch value {
                case "Task 1":
                    break
                case "Task 2":
                    XCTFail("Task 2 should have timed out")
                case "Task 3":
                    break
                default:
                    XCTFail("Unknown task")
                }

            case let .failure(error):
                guard
                    let value = (error as? ClientError)?.localizedDescription
                else {
                    XCTFail()
                    return
                }
                switch value {
                case "Task 1":
                    XCTFail("Task 1 should have succeeded.")
                case "Task 2":
                    break
                case "Task 3":
                    XCTFail("Task 3 should have succeeded.")
                default:
                    XCTFail("Unknown task")
                }
            }
        }
    }
    
    // MARK: - Cancellation Tests
    
    /// Tests that cancelling a timeout task prevents completion.
    func test_taskCancellation_preventsCompletion() async throws {
        // Given
        let task = Task(timeoutInSeconds: 2.0) {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            return "Should not complete"
        }
        
        // When
        task.cancel()
        
        // Then
        do {
            _ = try await task.value
            XCTFail("Cancelled task should not complete successfully")
        } catch {
            return
        }
    }
    
    /// Tests that timeout respects task cancellation.
    func test_timeout_respectsCancellation() async throws {
        // Given
        nonisolated(unsafe) var operationStarted = false
        let task = Task(timeoutInSeconds: 5.0) {
            operationStarted = true
            try Task.checkCancellation()
            try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
            return "Should not complete"
        }
        
        // When
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        task.cancel()
        
        // Then
        do {
            _ = try await task.value
            XCTFail("Task should have been cancelled")
        } catch {
            XCTAssertTrue(operationStarted, "Operation should have started")
        }
    }

    // MARK: - Edge Cases
    
    /// Tests zero timeout behavior.
    func test_zeroTimeout_immediatelyTimesOut() async throws {
        // Given
        let task = Task(timeoutInSeconds: 0) {
            "Should timeout immediately"
        }
        
        // When/Then
        do {
            _ = try await task.value
            XCTFail("Zero timeout should fail immediately")
        } catch {
            // Expected timeout
        }
    }
    
    /// Tests negative timeout behavior.
    func test_negativeTimeout_immediatelyTimesOut() async throws {
        // Given
        let task = Task(timeoutInSeconds: -1.0) {
            "Should timeout immediately"
        }
        
        // When/Then
        do {
            _ = try await task.value
            XCTFail("Negative timeout should fail immediately")
        } catch {
            // Expected timeout or immediate completion
        }
    }

    // MARK: - Error Propagation Tests
    
    /// Tests that errors from the operation are properly propagated.
    func test_operationError_isPropagated() async throws {
        // Given
        struct TestError: Error, Equatable {
            let message: String
        }
        
        let expectedError = TestError(message: "Operation failed")
        
        // When
        let task = Task(timeoutInSeconds: 2.0) {
            throw expectedError
        }
        
        // Then
        do {
            _ = try await task.value
            XCTFail("Should have thrown error")
        } catch let error as TestError {
            XCTAssertEqual(error, expectedError, "Original error should be propagated")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Stress Tests
    
    /// Tests many concurrent timeout tasks.
    func test_manyConcurrentTimeoutTasks() async throws {
        // Given
        let taskCount = 100
        
        // When
        let results = await withTaskGroup(of: Int?.self) { group in
            for i in 0..<taskCount {
                group.addTask {
                    try? await Task(timeoutInSeconds: Double.random(in: 0.1...1.0)) {
                        try await Task.sleep(
                            nanoseconds: UInt64.random(in: 10_000_000...500_000_000)
                        )
                        return i
                    }.value
                }
            }
            
            var completed = 0
            for await result in group {
                if result != nil {
                    completed += 1
                }
            }
            return completed
        }
        
        // Then
        XCTAssertGreaterThan(results, 0, "Some tasks should complete")
        XCTAssertLessThanOrEqual(results, taskCount, "Cannot complete more than started")
    }
}
