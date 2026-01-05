//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A thread-safe buffer that collects items for later consumption.
///
/// Supports on-demand appending or reactive observation from a
/// publisher source. Items can be consumed in batch, with optional
/// flushing of the internal buffer.
final class ConsumableBucket<Element>: @unchecked Sendable {

    /// Represents the type of bucket: on-demand or publisher-driven.
    enum BucketType {
        /// A manually managed bucket where items are appended directly.
        case onDemand
        /// A bucket that observes and collects items from a publisher.
        case observer(AnyPublisher<Element, Never>)
    }

    private let queue = UnfairQueue()

    private var items: [Element] = []
    private var cancellable: AnyCancellable?

    /// Initializes the bucket with a transformed publisher source.
    ///
    /// - Parameters:
    ///   - source: A publisher of source values.
    ///   - transformer: A transformer to map source to bucket elements.
    convenience init<Source, Transformer: ConsumableBucketItemTransformer>(
        _ source: AnyPublisher<Source, Never>,
        transformer: Transformer
    ) where Transformer.Input == Source, Transformer.Output == Element {
        self.init(
            .observer(
                source
                    .compactMap { transformer.transform($0) }
                    .eraseToAnyPublisher()
            )
        )
    }

    /// Initializes the bucket with a transformed publisher source and
    /// optionally removes duplicates.
    ///
    /// - Parameters:
    ///   - source: A publisher of equatable source values.
    ///   - transformer: A transformer to map source to bucket elements.
    ///   - removeDuplicates: Whether to remove duplicate values.
    convenience init<Source: Equatable, Transformer: ConsumableBucketItemTransformer>(
        _ source: AnyPublisher<Source, Never>,
        transformer: Transformer,
        removeDuplicates: Bool
    ) where Transformer.Input == Source, Transformer.Output == Element {
        if removeDuplicates {
            self.init(
                .observer(
                    source
                        .removeDuplicates()
                        .compactMap { transformer.transform($0) }
                        .eraseToAnyPublisher()
                )
            )
        } else {
            self.init(source, transformer: transformer)
        }
    }

    /// Initializes the bucket with a publisher of bucket elements.
    ///
    /// - Parameter source: The publisher emitting elements to store.
    convenience init(
        _ source: AnyPublisher<Element, Never>
    ) {
        self.init(.observer(source))
    }

    /// Initializes the bucket for manual on-demand use.
    convenience init() {
        self.init(.onDemand)
    }

    private init(
        _ bucketType: BucketType
    ) {
        switch bucketType {
        case .onDemand:
            break
        case let .observer(publisher):
            cancellable = publisher.sink { [weak self] in self?.process($0) }
        }
    }

    /// Appends a single element to the bucket.
    ///
    /// - Parameter element: The item to be appended.
    func append(_ element: Element) {
        queue.sync { [weak self] in self?.items.append(element) }
    }

    /// Returns the items in the bucket.
    ///
    /// - Parameter flush: Whether to clear the buffer after returning.
    /// - Returns: An array of stored elements.
    func consume(flush: Bool = false) -> [Element] {
        if flush {
            return queue.sync {
                let result = items
                items = []
                return result
            }
        } else {
            return queue.sync { items }
        }
    }

    /// Inserts elements at a specific position in the buffer.
    ///
    /// - Parameters:
    ///   - items: The elements to insert.
    ///   - index: The position at which to insert them.
    func insert(_ items: [Element], at index: Int) {
        guard !items.isEmpty else {
            return
        }
        queue.sync {
            self.items.insert(contentsOf: items, at: index)
        }
    }

    // MARK: - Private Helpers

    /// Processes an incoming item from the observed publisher.
    ///
    /// - Parameter newItem: The new item to append.
    private func process(_ newItem: Element) {
        queue.sync {
            self.items.append(newItem)
        }
    }
}
