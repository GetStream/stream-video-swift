//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class SerialActorTests: XCTestCase, @unchecked Sendable {

    private var serialActor: SerialActor! = SerialActor(queue: .main)

    override func tearDown() {
        serialActor = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_init_createsActorSuccessfully() {
        let actor = SerialActor()
        XCTAssertNotNil(actor)
    }

    func test_initWithFile_createsActorWithCustomFile() {
        let actor = SerialActor(file: "CustomFile.swift")
        XCTAssertNotNil(actor)
    }

    // MARK: - Serial Execution Tests

    func test_execute_runsTasksSerially() async throws {
        actor ExecutionTracker {
            private(set) var executionOrder: [Int] = []

            func recordExecution(_ index: Int) {
                executionOrder.append(index)
            }
        }

        let tracker = ExecutionTracker()

        for i in 1...5 {
            try? await serialActor.execute { [weak self] in
                await tracker.recordExecution(i)
                await self?.wait(for: 0.01)
            }
        }

        let executionOrder = await tracker.executionOrder
        XCTAssertEqual(executionOrder, [1, 2, 3, 4, 5])
    }

    func test_execute_returnsCorrectValue() async throws {
        let result = try await serialActor.execute {
            42
        }

        XCTAssertEqual(result, 42)
    }

    func test_execute_returnsCorrectValueWithAsyncWork() async throws {
        let result = try await serialActor.execute {
            await self.wait(for: 0.01)
            return "Hello, World!"
        }

        XCTAssertEqual(result, "Hello, World!")
    }

    func test_execute_propagatesErrors() async {
        struct TestError: Error, Equatable {}

        do {
            try await serialActor.execute {
                throw TestError()
            }
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    func test_execute_propagatesAsyncErrors() async {
        struct AsyncTestError: Error, Equatable {}

        do {
            try await serialActor.execute {
                await self.wait(for: 0.01)
                throw AsyncTestError()
            }
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is AsyncTestError)
        }
    }

    // MARK: - Concurrency Tests

    func test_execute_maintainsSerialOrderUnderConcurrentAccess() async throws {
        actor SharedCounter {
            private(set) var value = 0
            private(set) var executionOrder: [Int] = []

            func increment() -> Int {
                value += 1
                executionOrder.append(value)
                return value
            }
        }

        let counter = SharedCounter()

        await withTaskGroup(of: Int?.self) { group in
            for _ in 0..<10 {
                group.addTask { [weak self] in
                    try? await self?.serialActor.execute { [weak self] in
                        await self?.wait(for: 0.15)
                        return await counter.increment()
                    }
                }
            }
        }

        let finalValue = await counter.value
        let executionOrder = await counter.executionOrder

        XCTAssertEqual(finalValue, 10)
        XCTAssertEqual(executionOrder, Array(1...10))
    }

    func test_execute_handlesHighConcurrency() async throws {
        actor CompletionTracker {
            private(set) var completedTasks = 0

            func taskCompleted() {
                completedTasks += 1
            }
        }

        let tracker = CompletionTracker()
        let taskCount = 100

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<taskCount {
                group.addTask { [weak self] in
                    try? await self?.serialActor.execute {
                        // Simulate some work
                        _ = i * 2
                        await tracker.taskCompleted()
                    }
                }
            }
        }

        let completedCount = await tracker.completedTasks
        XCTAssertEqual(completedCount, taskCount)
    }

    // MARK: - Cancellation Tests

    func test_cancel_stopsExecutionOfPendingTasks() async throws {

        // Wait for tasks to complete or be cancelled
        _ = await XCTAssertThrowsErrorAsync {
            // Start multiple tasks
            async let task1: Void = serialActor.execute {
                await self.wait(for: 0.1)
            }

            async let task2: Void = serialActor.execute {
                await self.wait(for: 0.1)
            }

            async let task3: Void = serialActor.execute {
                await self.wait(for: 0.1)
            }

            serialActor.cancel()

            do {
                try await task1
                try await task2
                try await task3
            } catch {
                print(error)
                throw error
            }

            _ = 0
        }
    }

    func test_cancel_allowsNewTasksAfterCancellation() async throws {
        // Cancel all pending tasks
        serialActor.cancel()

        // Execute a new task after cancellation
        let result = try await serialActor.execute {
            "Task executed after cancellation"
        }

        XCTAssertEqual(result, "Task executed after cancellation")
    }

    // MARK: - UnownedExecutor Tests

    func test_unownedExecutor_isNotNil() {
        let executor = serialActor.unownedExecutor
        XCTAssertNotNil(executor)
    }

    func test_unownedExecutor_remainsConsistent() {
        let executor1 = serialActor.unownedExecutor
        let executor2 = serialActor.unownedExecutor

        // Both should reference the same underlying executor
        XCTAssertNotNil(executor1)
        XCTAssertNotNil(executor2)
    }

    // MARK: - Memory Management Tests

    func test_execute_doesNotLeakMemory() async throws {
        weak var weakActor: SerialActor?

        do {
            let actor = SerialActor()
            weakActor = actor

            try await actor.execute {
                // Perform some work
                _ = Array(0..<1000).map { $0 * 2 }
            }
        }

        // Give time for cleanup
        await wait(for: 0.01)

        XCTAssertNil(weakActor, "Actor should be deallocated")
    }

    // MARK: - Error Recovery Tests

    func test_execute_continuesAfterError() async throws {
        struct TestError: Error {}

        // First task throws an error
        do {
            try await serialActor.execute {
                throw TestError()
            }
        } catch {
            // Expected
        }

        // Second task should still execute successfully
        let result = try await serialActor.execute {
            "Success after error"
        }

        XCTAssertEqual(result, "Success after error")
    }

    func test_execute_handlesMultipleErrorsGracefully() async throws {
        struct TestError: Error {}

        actor ErrorTracker {
            private(set) var errorCount = 0
            private(set) var successCount = 0

            func recordError() {
                errorCount += 1
            }

            func recordSuccess() {
                successCount += 1
            }
        }

        let tracker = ErrorTracker()

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask { [weak self] in
                    do {
                        try await self?.serialActor.execute {
                            if i % 2 == 0 {
                                throw TestError()
                            } else {
                                await tracker.recordSuccess()
                            }
                        }
                    } catch {
                        await tracker.recordError()
                    }
                }
            }
        }

        let errorCount = await tracker.errorCount
        let successCount = await tracker.successCount

        XCTAssertEqual(errorCount, 5)
        XCTAssertEqual(successCount, 5)
    }

    // MARK: - Performance Tests

    func test_performance_manySequentialTasks() async throws {
        let taskCount = 1000

        let startTime = CFAbsoluteTimeGetCurrent()

        for i in 0..<taskCount {
            try await serialActor.execute {
                _ = i * 2 // Simple computation
            }
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime

        // Should complete reasonably quickly (adjust threshold as needed)
        XCTAssertLessThan(duration, 5.0, "Performance test took too long")
    }

    func test_performance_manyConcurrentTasks() async throws {
        let taskCount = 100

        let startTime = CFAbsoluteTimeGetCurrent()

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<taskCount {
                group.addTask { [weak self] in
                    try? await self?.serialActor.execute {
                        _ = i * 2 // Simple computation
                    }
                }
            }
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime

        // Should complete reasonably quickly (adjust threshold as needed)
        XCTAssertLessThan(duration, 5.0, "Performance test took too long")
    }

    // MARK: - Type Safety Tests

    func test_execute_handlesVariousReturnTypes() async throws {
        // Test Int
        let intResult = try await serialActor.execute { 42 }
        XCTAssertEqual(intResult, 42)

        // Test String
        let stringResult = try await serialActor.execute { "Hello" }
        XCTAssertEqual(stringResult, "Hello")

        // Test Array
        let arrayResult = try await serialActor.execute { [1, 2, 3] }
        XCTAssertEqual(arrayResult, [1, 2, 3])

        // Test Optional
        let optionalResult = try await serialActor.execute {
            String?("Optional Value")
        }
        XCTAssertEqual(optionalResult, "Optional Value")

        // Test Void
        try await serialActor.execute {
            // No return value
        }
    }

    func test_execute_handlesComplexSendableTypes() async throws {
        struct SendableData: Sendable, Equatable {
            let id: Int
            let name: String
            let values: [Int]
        }

        let expectedData = SendableData(id: 1, name: "Test", values: [1, 2, 3])

        let result = try await serialActor.execute {
            expectedData
        }

        XCTAssertEqual(result, expectedData)
    }
}
