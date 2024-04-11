//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

final class ReusePool<Element: AnyObject & Hashable> {
    private let initialCapacity: Int
    private let factory: () -> Element
    private let queue = UnfairQueue()
    private var available: [Element] = []
    private var inUse: Set<Element> = []

    init(initialCapacity: Int = 10, factory: @escaping () -> Element) {
        self.initialCapacity = initialCapacity
        self.factory = factory

        // Initialize the pool with a set number of elements
        for _ in 0..<initialCapacity {
            let element = factory()
            available.append(element)
        }
    }

    func acquire() -> Element {
        var element: Element!

        queue.sync {
            if let available = available.popLast() {
                element = available
                inUse.insert(available)
                log.debug("Reusing \(type(of: element)):\(String(describing: element)).")
            } else {
                element = factory()
                inUse.insert(element)
                log.debug("Created new \(type(of: element)):\(String(describing: element)).")
            }
        }

        return element
    }

    func release(_ element: Element) {
        queue.sync {
            if inUse.contains(element), available.endIndex < initialCapacity {
                inUse.remove(element)
                available.append(element)
                log.debug("Will make available \(type(of: element)):\(String(describing: element)).")
            } else {
                inUse.remove(element)
                log.debug("Will release \(type(of: element)):\(String(describing: element)).")
            }
        }
    }

    func releaseAll() {
        queue.sync {
            for element in inUse {
                guard available.endIndex < initialCapacity else {
                    return
                }
                inUse.remove(element)
                available.append(element)
                log.debug("Will make available \(type(of: element)):\(String(describing: element)).")
            }
            if !inUse.isEmpty {
                log.debug("Will release \(inUse.count) \(String(describing: type(of: Element.self))) instances.")
                inUse.removeAll()
            }
        }
    }
}
