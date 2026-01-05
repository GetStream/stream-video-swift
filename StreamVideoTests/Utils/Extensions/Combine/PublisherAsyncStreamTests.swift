//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

/// Comprehensive tests for Publisher+AsyncStream extension.
///
/// Tests cover:
/// - AsyncStream conversion
/// - firstValue functionality
/// - nextValue functionality
/// - Timeout behavior
/// - Error handling
/// - Concurrency scenarios
final class PublisherAsyncStreamTests: XCTestCase, @unchecked Sendable {

    private final class ReceivedValuesStorage<Element>: @unchecked Sendable {
        @Atomic private var values: [Element] = []

        func append(_ element: Element) {
            values.append(element)
        }

        var count: Int {
            values.count
        }

        var array: [Element] {
            values
        }
    }
    
    // MARK: - eraseAsAsyncStream Tests
    
    /// Tests basic conversion from Publisher to AsyncStream.
    func test_eraseAsAsyncStream_convertsPublisher() async {
        // Given
        let storage = ReceivedValuesStorage<Int>()
        let publisher = PassthroughSubject<Int, Never>()
        let asyncStream = publisher.eraseAsAsyncStream()
        
        // When
        let expectation = XCTestExpectation(description: "Receive values from async stream")

        Task {
            for await value in asyncStream {
                storage.append(value)
                if storage.count == 3 {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        // Then
        publisher.send(1)
        publisher.send(2)
        publisher.send(3)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(storage.array, [1, 2, 3])
    }
    
    /// Tests AsyncStream properly completes when publisher completes.
    func test_eraseAsAsyncStream_completesWithPublisher() async {
        // Given
        let storage = ReceivedValuesStorage<Int>()
        let publisher = PassthroughSubject<Int, Never>()
        let asyncStream = publisher.eraseAsAsyncStream()
        
        // When
        let expectation = XCTestExpectation(description: "Stream completes")
        
        Task {
            for await value in asyncStream {
                storage.append(value)
            }
            expectation.fulfill()
        }
        
        // Then
        publisher.send(1)
        publisher.send(2)
        publisher.send(completion: .finished)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(storage.array, [1, 2])
    }
    
    /// Tests AsyncStream cancellation properly cancels the subscription.
    func test_eraseAsAsyncStream_cancellationCancelsSubscription() async {
        // Given
        let storage = ReceivedValuesStorage<Int>()
        let publisher = PassthroughSubject<Int, Never>()
        let asyncStream = publisher.eraseAsAsyncStream()
        
        // When
        let expectation = XCTestExpectation(description: "Stream is cancelled")
        
        let task = Task {
            for await value in asyncStream {
                storage.append(value)
                if storage.count == 2 {
                    break
                }
            }
            expectation.fulfill()
        }
        
        // Then
        publisher.send(1)
        publisher.send(2)
        task.cancel()
        publisher.send(3) // Should not be received
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(storage.array, [1, 2])
    }
    
    /// Tests multiple AsyncStreams from the same publisher.
    func test_eraseAsAsyncStream_multipleStreams() async {
        // Given
        let storage1 = ReceivedValuesStorage<Int>()
        let storage2 = ReceivedValuesStorage<Int>()
        let publisher = PassthroughSubject<Int, Never>()
        
        // When
        let expectation1 = XCTestExpectation(description: "Stream 1 receives values")
        let expectation2 = XCTestExpectation(description: "Stream 2 receives values")
        
        Task {
            for await value in publisher.eraseAsAsyncStream() {
                storage1.append(value)
                if storage1.count == 3 {
                    expectation1.fulfill()
                    break
                }
            }
        }
        
        Task {
            for await value in publisher.eraseAsAsyncStream() {
                storage2.append(value)
                if storage2.count == 3 {
                    expectation2.fulfill()
                    break
                }
            }
        }
        
        // Allow tasks to start
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        publisher.send(1)
        publisher.send(2)
        publisher.send(3)
        
        await fulfillment(of: [expectation1, expectation2], timeout: 1.0)
        XCTAssertEqual(storage1.array, [1, 2, 3])
        XCTAssertEqual(storage2.array, [1, 2, 3])
    }
    
    // MARK: - firstValue Tests
    
    /// Tests firstValue returns the first emitted value.
    func test_firstValue_returnsFirstEmittedValue() async throws {
        // Given
        let publisher = PassthroughSubject<String, Never>()
        
        // When
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            publisher.send("first")
            publisher.send("second")
            publisher.send("third")
        }
        
        let result = try await publisher.firstValue()
        
        // Then
        XCTAssertEqual(result, "first")
    }
    
    /// Tests firstValue with immediate value.
    func test_firstValue_withImmediateValue() async throws {
        // Given
        let publisher = Just("immediate")
        
        // When
        let result = try await publisher.firstValue()
        
        // Then
        XCTAssertEqual(result, "immediate")
    }
    
    /// Tests firstValue throws when publisher completes without value.
    func test_firstValue_throwsWhenNoValue() async {
        // Given
        let publisher = Empty<Int, Never>()
        
        // When/Then
        do {
            _ = try await publisher.firstValue()
            XCTFail("Should throw when no value is produced")
        } catch {
            // Expected error
            XCTAssertTrue(error is ClientError)
        }
    }
    
    /// Tests firstValue with timeout succeeds within timeout.
    func test_firstValue_withTimeout_succeeds() async throws {
        // Given
        let publisher = PassthroughSubject<Int, Never>()
        
        // When
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            publisher.send(42)
        }
        
        let result = try await publisher.firstValue(timeoutInSeconds: 1.0)
        
        // Then
        XCTAssertEqual(result, 42)
    }
    
    /// Tests firstValue with timeout throws on timeout.
    func test_firstValue_withTimeout_timesOut() async {
        // Given
        let publisher = PassthroughSubject<Int, Never>()
        
        // When/Then
        do {
            _ = try await publisher.firstValue(timeoutInSeconds: 0.1)
            XCTFail("Should timeout")
        } catch {
            // Expected timeout error
            XCTAssertTrue(error is ClientError)
        }
    }
    
    // MARK: - nextValue Tests
    
    /// Tests nextValue returns the next value.
    func test_nextValue_returnsNextValue() async throws {
        // Given
        let publisher = PassthroughSubject<Int, Never>()
        
        // When
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            publisher.send(1)
        }
        
        let result = try await publisher.nextValue()
        
        // Then
        XCTAssertEqual(result, 1)
    }
    
    /// Tests nextValue with dropFirst skips values.
    func test_nextValue_withDropFirst() async throws {
        // Given
        let publisher = PassthroughSubject<Int, Never>()
        
        // When
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            publisher.send(1)
            publisher.send(2)
            publisher.send(3)
        }
        
        let result = try await publisher.nextValue(dropFirst: 2)
        
        // Then
        XCTAssertEqual(result, 3)
    }
    
    /// Tests nextValue with timeout.
    func test_nextValue_withTimeout() async throws {
        // Given
        let publisher = PassthroughSubject<String, Never>()
        
        // When
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            publisher.send("value")
        }
        
        let result = try await publisher.nextValue(timeout: 1.0)
        
        // Then
        XCTAssertEqual(result, "value")
    }
    
    /// Tests nextValue timeout failure.
    func test_nextValue_timeoutFailure() async {
        // Given
        let publisher = PassthroughSubject<Int, Never>()
        
        // When/Then
        do {
            _ = try await publisher.nextValue(timeout: 0.1)
            XCTFail("Should timeout")
        } catch {
            // Expected timeout
            XCTAssertTrue(error is ClientError)
        }
    }
    
    /// Tests nextValue with dropFirst and timeout.
    func test_nextValue_withDropFirstAndTimeout() async throws {
        // Given
        let publisher = PassthroughSubject<Int, Never>()
        
        // When
        Task {
            try? await Task.sleep(nanoseconds: 50_000_000)
            publisher.send(1)
            publisher.send(2)
            try? await Task.sleep(nanoseconds: 50_000_000)
            publisher.send(3)
        }
        
        let result = try await publisher.nextValue(dropFirst: 2, timeout: 1.0)
        
        // Then
        XCTAssertEqual(result, 3)
    }

    // MARK: - Concurrency Tests
    
    /// Tests concurrent firstValue calls.
    func test_concurrentFirstValueCalls() async throws {
        // Given
        let publisher = PassthroughSubject<Int, Never>()
        
        // When
        async let result1 = publisher.firstValue()
        async let result2 = publisher.firstValue()
        async let result3 = publisher.firstValue()
        
        // Send values after tasks are waiting
        try? await Task.sleep(nanoseconds: 100_000_000)
        publisher.send(42)
        
        // Then
        let results = try await [result1, result2, result3]
        XCTAssertTrue(results.allSatisfy { $0 == 42 })
    }
    
    // MARK: - Performance Tests
    
    /// Tests performance of AsyncStream conversion.
    func test_asyncStreamPerformance() async {
        // Given
        let iterations = 1000
        let publisher = PassthroughSubject<Int, Never>()
        let storage = ReceivedValuesStorage<Int>()
        
        // When
        let expectation = XCTestExpectation(description: "Performance test")
        
        Task {
            for await value in publisher.eraseAsAsyncStream() {
                storage.append(value)
                if storage.count == iterations {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        // Allow task to start
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        let start = CFAbsoluteTimeGetCurrent()
        for i in 0..<iterations {
            publisher.send(i)
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
        let duration = CFAbsoluteTimeGetCurrent() - start
        
        // Then
        XCTAssertEqual(storage.count, iterations)
        print("AsyncStream processed \(iterations) values in \(duration) seconds")
        XCTAssertLessThan(duration, 1.0, "Should process quickly")
    }
}

// MARK: - Helper Extensions

private extension Array where Element == Task<Int?, Error> {
    func asyncMap<T>(_ transform: (Element) async -> T) async -> [T] {
        var results: [T] = []
        for element in self {
            results.append(await transform(element))
        }
        return results
    }
}
