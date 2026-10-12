//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

/// A generic pool for reusing instances of elements that conform to AnyObject and Hashable protocols.
/// The pool will align stretch and/or tight its capacity depending on how its objects are being used.
///
/// - Important: Callers are responsible for informing the reusePool when an object is to be released.
final class ReusePool<Element: AnyObject & Hashable> {
    /// The initial capacity of the pool.
    private let initialCapacity: Int
    /// The factory closure used to create new instances of elements.
    private let factory: () -> Element
    /// Queue for thread-safe operations.
    private let queue = UnfairQueue()
    /// Array to store available elements for reuse.
    private var available: [Element] = []
    /// Set to track elements currently in use.
    private var inUse: Set<Element> = []

    /// Initializes the pool with a specified initial capacity and a factory closure to create elements.
    ///
    /// - Parameters:
    ///   - initialCapacity: The initial capacity of the pool (default is 10).
    ///   - factory: A closure that returns a new instance of an element.
    init(initialCapacity: Int = 10, factory: @escaping () -> Element) {
        self.initialCapacity = initialCapacity
        self.factory = factory

        // Initialize the pool with a set number of elements
        for _ in 0..<initialCapacity {
            let element = factory()
            available.append(element)
        }
    }

    /// Acquires an element from the pool for use.
    ///
    /// - Returns: An element from the pool.
    func acquire() -> Element {
        var element: Element!

        queue.sync {
            if let available = available.popLast() {
                element = available
                inUse.insert(available)
                log.debug("Pool object reused. objectId=\(ObjectIdentifier(available))")
            } else {
                element = factory()
                inUse.insert(element)
                log.debug("Pool object created. objectId=\(ObjectIdentifier(element))")
            }
        }

        return element
    }

    /// Releases an element back to the pool for reuse.
    ///
    /// - Parameters:
    ///   - element: The element to release.
    ///   available, it will throw it away and instead place a newly created element in `available` storage.
    ///   Defaults to `false`.
    func release(_ element: Element) {
        queue.sync {
            if inUse.contains(element), available.endIndex < initialCapacity {
                inUse.remove(element)
                available.append(element)
                log.debug("Pool object returned. objectId=\(ObjectIdentifier(element)) retained=true")
            } else {
                inUse.remove(element)
                log.debug("Pool object returned. objectId=\(ObjectIdentifier(element)) retained=false")
            }
        }
    }

    /// Releases all elements currently in use back to the pool for reuse.
    func releaseAll() {
        queue.sync {
            let inUseCount = inUse.count
            defer {
                if inUseCount > 0 {
                    log.debug(
                        "Pool release completed. previousInUseCount=\(inUseCount)"
                            + " inUseCount=\(inUse.count) availableCount=\(available.count)"
                    )
                }
            }
            for element in inUse {
                guard available.endIndex < initialCapacity else {
                    return
                }
                inUse.remove(element)
                available.append(element)
            }
            if !inUse.isEmpty {
                inUse.removeAll()
            }
        }
    }
}
