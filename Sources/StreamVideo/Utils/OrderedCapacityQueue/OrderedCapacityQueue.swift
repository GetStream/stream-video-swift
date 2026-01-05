//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A thread-safe queue that maintains a fixed capacity and removes elements after
/// a specified time interval.
final class OrderedCapacityQueue<Element> {

    private let queue = UnfairQueue()

    /// The maximum number of elements the queue can hold.
    var capacity: Int {
        didSet { didUpdate(capacity: capacity) }
    }

    /// The time interval after which elements are removed from the queue.
    var removalTime: TimeInterval {
        didSet { didUpdate(removalTime: removalTime) }
    }

    /// The elements currently in the queue.
    private var elements: [Element] = [] {
        didSet {
            toggleRemovalObservation(!elements.isEmpty)
            subject.send(elements)
        }
    }

    /// The times at which elements were inserted into the queue.
    private var insertionTimes: [Date] = []

    /// A cancellable object for the removal timer.
    private var removalTimerCancellable: AnyCancellable?

    /// A subject that publishes changes to the elements in the queue.
    private let subject = PassthroughSubject<[Element], Never>()

    /// A publisher that emits the elements in the queue.
    var publisher: AnyPublisher<[Element], Never> { subject.eraseToAnyPublisher() }

    /// Initializes a new queue with the specified capacity and removal time.
    ///
    /// - Parameters:
    ///   - capacity: The maximum number of elements the queue can hold.
    ///   - removalTime: The time interval after which elements are removed.
    init(capacity: Int, removalTime: TimeInterval) {
        self.capacity = capacity
        self.removalTime = removalTime
        removalTimerCancellable = DefaultTimer
            .publish(every: ScreenPropertiesAdapter.currentValue.refreshRate)
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [weak self] _ in self?.removeItemsIfRequired() }
    }
    
    // MARK: - Public Methods
    
    /// Adds an element to the queue.
    ///
    /// - Parameter element: The element to add to the queue.
    /// - Note: Adding a new element may cause the oldest elements to be removed if the capacity is
    /// exceeded.
    func append(_ element: Element) {
        queue.sync {
            elements.append(element)
            insertionTimes.append(Date())

            if elements.count > capacity {
                elements.removeFirst(elements.endIndex - capacity)
                insertionTimes.removeFirst(insertionTimes.endIndex - capacity)
            }
        }
    }

    func toArray() -> [Element] {
        elements
    }

    // MARK: - Private Helpers

    /// Toggles the observation of the removal timer based on the queue's state.
    ///
    /// - Parameter isEnabled: A Boolean value indicating whether the observation
    ///   should be enabled.
    private func toggleRemovalObservation(_ isEnabled: Bool) {
        if isEnabled, removalTimerCancellable == nil {
            removalTimerCancellable = DefaultTimer
                .publish(every: ScreenPropertiesAdapter.currentValue.refreshRate)
                .sink { [weak self] _ in self?.removeItemsIfRequired() }
        } else if !isEnabled, removalTimerCancellable != nil {
            removalTimerCancellable?.cancel()
            removalTimerCancellable = nil
        } else {
            /* No-op */
        }
    }

    /// Updates the capacity of the queue and removes excess elements if necessary.
    ///
    /// - Parameter newCapacity: The new capacity of the queue.
    private func didUpdate(capacity newCapacity: Int) {
        queue.sync {
            capacity = newCapacity
            if elements.count > capacity {
                elements.removeFirst(elements.endIndex - capacity)
                insertionTimes.removeFirst(insertionTimes.endIndex - capacity)
            }
        }
    }

    /// Updates the removal time of the queue and resets the removal timer.
    ///
    /// - Parameter newRemovalTime: The new removal time of the queue.
    private func didUpdate(removalTime newRemovalTime: TimeInterval) {
        removalTime = newRemovalTime
    }

    /// Removes elements from the queue if they have exceeded the removal time.
    private func removeItemsIfRequired() {
        queue.sync {
            let currentTime = Date()
            var indicesToRemove: [Int] = []

            // Find indices of items that have exceeded the removal time
            for (index, insertionTime) in insertionTimes.enumerated() {
                if currentTime.timeIntervalSince(insertionTime) >= self.removalTime {
                    indicesToRemove.append(index)
                }
            }

            // Remove items in reverse order to avoid index shifting issues
            for index in indicesToRemove.reversed() {
                elements.remove(at: index)
                insertionTimes.remove(at: index)
            }
        }
    }
}

extension OrderedCapacityQueue: Sequence {

    // MARK: - Sequence Conformance

    func makeIterator() -> AnyIterator<Element> {
        AnyIterator(elements.makeIterator())
    }
}

extension OrderedCapacityQueue: RandomAccessCollection {
    // MARK: - RandomAccessCollection Conformance

    /// The starting index of the collection.
    var startIndex: Int {
        elements.startIndex
    }

    /// The index one past the end of the collection.
    var endIndex: Int {
        elements.endIndex
    }

    /// Accesses the element at the specified position.
    subscript(position: Int) -> Element {
        elements[position]
    }

    /// Returns the next index after the given index.
    func index(after i: Int) -> Int {
        elements.index(after: i)
    }

    /// Returns the index before the given index (required for BidirectionalCollection).
    func index(before i: Int) -> Int {
        elements.index(before: i)
    }

    /// Returns the number of elements in the queue.
    var count: Int {
        elements.endIndex
    }
}

extension OrderedCapacityQueue: Equatable where Element: Equatable {
    static func == (
        lhs: OrderedCapacityQueue<Element>,
        rhs: OrderedCapacityQueue<Element>
    ) -> Bool {
        lhs.elements == rhs.elements
            && lhs.insertionTimes == rhs.insertionTimes
            && lhs.capacity == rhs.capacity
            && lhs.removalTime == rhs.removalTime
    }
}
