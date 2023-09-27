//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import StreamVideo

final class MemoryLeakDetectorTests: XCTestCase {

    // Test tracking memory leaks for a single object
    func testTrackMemoryLeak() async throws {
        MemoryLeakDetector.track(TestObject(), maxExpectedCount: 1)

        // Simulate the deallocation of the object
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate some delay

        // Check if the object has been deallocated
        XCTAssertRefCount(for: TestObject.self)
    }

    // Test tracking memory leaks for multiple objects
    func testTrackMultipleMemoryLeaks() async throws {
        MemoryLeakDetector.track(TestObject(), maxExpectedCount: 1)
        MemoryLeakDetector.track(AnotherTestObject(), maxExpectedCount: 1)

        // Simulate the deallocation of the objects
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate some delay

        // Check if the objects have been deallocated
        XCTAssertRefCount(for: TestObject.self)
        XCTAssertRefCount(for: AnotherTestObject.self)
    }

    // Test tracking memory leaks with a custom expected count
    func testTrackWithCustomExpectedCount() async throws {
        MemoryLeakDetector.track(TestObject(), maxExpectedCount: 2)

        // Simulate the deallocation of the object
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate some delay

        // Check if the object has been deallocated
        XCTAssertRefCount(for: TestObject.self)
    }

    // Test tracking memory leaks with no deallocation
    func testNoMemoryLeakTracking() async throws {
        let testObject = TestObject()
        MemoryLeakDetector.track(testObject, maxExpectedCount: 1)

        // No deallocation simulation

        // Check if the object hasn't been deallocated
        XCTAssertRefCount(for: TestObject.self, expectedCount: 1)
    }

    private func XCTAssertRefCount(
        for objectType: Any,
        expectedCount: Int = 0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let typeName = String(describing: objectType)
        let waitExpectation = expectation(description: "Wait for memoryLeak entry fetch")
        Task {
            let entry = await MemoryLeakDetector.default.entries[typeName]
            XCTAssertEqual(entry?.count, expectedCount, file: file, line: line)
            waitExpectation.fulfill()
        }

        wait(for: [waitExpectation], timeout: defaultTimeout)
    }
}

// Sample objects for testing
private final class TestObject: Sendable {}
private final class AnotherTestObject {}

