//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class StackTests: XCTestCase {

    func testPush() {
        var stack = Stack<Int>()
        stack.push(1)
        XCTAssertEqual(stack.peek(), 1, "Pushed element should be on top of the stack")
        XCTAssertEqual(stack.count(), 1, "Stack count should be 1 after one push")
    }

    func testPop() {
        var stack = Stack<Int>()
        stack.push(1)
        stack.push(2)
        let poppedElement = stack.pop()
        XCTAssertEqual(poppedElement, 2, "Popped element should be the last pushed element")
        XCTAssertEqual(stack.count(), 1, "Stack count should be 1 after one pop")
        XCTAssertEqual(stack.peek(), 1, "The remaining element should be 1")
    }

    func testPeek() {
        var stack = Stack<Int>()
        stack.push(1)
        stack.push(2)
        XCTAssertEqual(stack.peek(), 2, "Peek should return the top element without removing it")
        XCTAssertEqual(stack.count(), 2, "Stack count should remain the same after peeking")
    }

    func testIsEmpty() {
        var stack = Stack<Int>()
        XCTAssertTrue(stack.isEmpty(), "Stack should be empty initially")
        stack.push(1)
        XCTAssertFalse(stack.isEmpty(), "Stack should not be empty after a push")
        _ = stack.pop()
        XCTAssertTrue(stack.isEmpty(), "Stack should be empty after popping all elements")
    }

    func testCount() {
        var stack = Stack<Int>()
        XCTAssertEqual(stack.count(), 0, "Stack count should be 0 initially")
        stack.push(1)
        stack.push(2)
        XCTAssertEqual(stack.count(), 2, "Stack count should be 2 after two pushes")
        _ = stack.pop()
        XCTAssertEqual(stack.count(), 1, "Stack count should be 1 after one pop")
    }

    func testIteration() {
        var stack = Stack<Int>()
        stack.push(1)
        stack.push(2)
        stack.push(3)

        var elements = [Int]()
        for element in stack {
            elements.append(element)
        }

        XCTAssertEqual(elements, [3, 2, 1], "Iteration should follow LIFO order")
    }

    func testPopEmpty() {
        var stack = Stack<Int>()
        let poppedElement = stack.pop()
        XCTAssertNil(poppedElement, "Pop should return nil when stack is empty")
    }

    func testPeekEmpty() {
        let stack = Stack<Int>()
        XCTAssertNil(stack.peek(), "Peek should return nil when stack is empty")
    }
}
