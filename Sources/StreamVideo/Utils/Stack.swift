//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A stack is a collection that supports push and pop operations, following the last-in, first-out (LIFO) principle.
struct Stack<Element>: Sequence {
    /// The underlying storage for the stack's elements.
    private var elements: [Element] = []

    /// Adds an element to the top of the stack.
    ///
    /// - Parameter element: The element to be pushed onto the stack.
    mutating func push(_ element: Element) {
        elements.append(element)
    }

    /// Removes and returns the element at the top of the stack.
    ///
    /// - Returns: The element at the top of the stack, or `nil` if the stack is empty.
    @discardableResult
    mutating func pop() -> Element? {
        elements.popLast()
    }

    /// Returns the element at the top of the stack without removing it.
    ///
    /// - Returns: The element at the top of the stack, or `nil` if the stack is empty.
    func peek() -> Element? {
        elements.last
    }

    /// Checks if the stack is empty.
    ///
    /// - Returns: `true` if the stack is empty; otherwise, `false`.
    func isEmpty() -> Bool {
        elements.isEmpty
    }

    /// Returns the number of elements in the stack.
    ///
    /// - Returns: The number of elements in the stack.
    func count() -> Int {
        elements.count
    }

    /// An iterator for the stack.
    struct Iterator: IteratorProtocol {
        /// The elements to iterate over.
        private var currentElements: [Element]

        /// Creates an iterator for the given elements.
        ///
        /// - Parameter elements: The elements to iterate over.
        init(_ elements: [Element]) {
            currentElements = elements
        }

        /// Advances to the next element and returns it.
        ///
        /// - Returns: The next element in the iteration, or `nil` if no more elements are available.
        mutating func next() -> Element? {
            currentElements.popLast()
        }
    }

    /// Creates an iterator that iterates over the elements of the stack.
    ///
    /// - Returns: An iterator that iterates over the elements of the stack.
    func makeIterator() -> Iterator { .init(elements) }
}
