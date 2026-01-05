//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideoSwiftUI
import XCTest

final class ReusePoolTests: XCTestCase, @unchecked Sendable {

    // Define a sample reusable object for testing
    private final class TestObject: Hashable {

        let id: Int
        init(id: Int) { self.id = id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
        static func == (lhs: ReusePoolTests.TestObject, rhs: ReusePoolTests.TestObject) -> Bool { lhs === rhs }
    }

    private var subject: ReusePool<TestObject>! = .init(initialCapacity: 3) { TestObject(id: .random(in: 0...10)) }

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - Acquire & Release

    func test_acquireAndRelease() {
        // Acquire objects from the pool and then release them
        let object1 = subject.acquire()
        let object2 = subject.acquire()

        XCTAssertNotNil(object1)
        XCTAssertNotNil(object2)
        XCTAssertNotEqual(object1, object2)

        subject.release(object2)
        subject.release(object1)

        // After releasing, these objects should be available for reuse
        let object3 = subject.acquire()
        let object4 = subject.acquire()

        XCTAssertNotNil(object3)
        XCTAssertNotNil(object4)
        XCTAssertTrue(object1 === object3) // Reused object
        XCTAssertTrue(object2 === object4) // Reused object

        // Now, the pool should be at initial capacity
        let object5 = subject.acquire()
        XCTAssertNotNil(object5)

        // Try to acquire more than the initial capacity
        let object6 = subject.acquire()
        XCTAssertNotNil(object6)

        // Release all objects
        subject.releaseAll()

        // After releasing all, all objects should be back in the pool
        let object7 = subject.acquire()
        XCTAssertNotNil(object7)
    }

    func test_acquireAndReleaseWithReplace() {
        // Acquire objects from the pool and then release them
        let object1 = subject.acquire()
        let object2 = subject.acquire()

        XCTAssertNotNil(object1)
        XCTAssertNotNil(object2)
        XCTAssertNotEqual(object1, object2)

        subject.release(object2)
        subject.release(object1)

        // After releasing, these objects should be available for reuse
        let object3 = subject.acquire()
        let object4 = subject.acquire()

        XCTAssertNotNil(object3)
        XCTAssertNotNil(object4)
        XCTAssertTrue(object1 === object3) // Reused object
        XCTAssertTrue(object2 === object4) // Reused object

        // Now, the pool should be at initial capacity
        let object5 = subject.acquire()
        XCTAssertNotNil(object5)

        // Try to acquire more than the initial capacity
        let object6 = subject.acquire()
        XCTAssertNotNil(object6)

        // Release all objects
        subject.releaseAll()

        // After releasing all, all objects should be back in the pool
        let object7 = subject.acquire()
        XCTAssertNotNil(object7)
    }

    func test_exceedCapacity() {
        // Acquire objects up to the initial capacity
        let objects = (0..<3).map { _ in subject.acquire() }
        XCTAssertEqual(objects.count, 3)

        // Try to acquire more than the initial capacity
        let object4 = subject.acquire()
        XCTAssertNotNil(object4)

        // Release objects
        objects.forEach { subject.release($0) }

        // After releasing, the pool should be at initial capacity again
        let object5 = subject.acquire()
        XCTAssertNotNil(object5)
    }

    func test_releaseNonExistent() {
        // Acquire an object and then try to release a different one
        let object1 = subject.acquire()
        let object2 = TestObject(id: 100)

        subject.release(object1)
        subject.release(object2) // should not affect the pool

        let object3 = subject.acquire()
        XCTAssertNotNil(object3)
        XCTAssertEqual(object1, object3) // object1 should be reused
    }

    func test_releaseAll() {
        let objects = (0..<5).map { _ in subject.acquire() }
        XCTAssertEqual(objects.count, 5)

        subject.releaseAll()

        let object = subject.acquire()
        XCTAssertNotNil(object)
    }
}
