//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

final class ConsumableBucket<Element> {

    enum BucketType {
        case onDemand
        case observer(AnyPublisher<Element, Never>)
    }

    private let queue = UnfairQueue()

    private var items: [Element] = []
    private var cancellable: AnyCancellable?

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

    convenience init(
        _ source: AnyPublisher<Element, Never>
    ) {
        self.init(.observer(source))
    }

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

    func append(_ element: Element) {
        queue.sync { [weak self] in self?.items.append(element) }
    }

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

    func insert(_ items: [Element], at index: Int) {
        guard !items.isEmpty else {
            return
        }
        queue.sync {
            self.items.insert(contentsOf: items, at: index)
        }
    }

    // MARK: - Private Helpers

    private func process(_ newItem: Element) {
        queue.sync {
            self.items.append(newItem)
        }
    }
}
