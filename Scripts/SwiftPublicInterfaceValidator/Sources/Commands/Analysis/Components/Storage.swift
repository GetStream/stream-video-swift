//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

final class Storage: Decodable {

    private let queue: UnfairQueue = .init()
    private var keys: [URL] = []
    private var storage: [URL: [PublicInterfaceEntry]] = [:]

    init() {}

    convenience init(from decoder: any Decoder) throws { self.init() }

    // MARK: - Accessor

    func set(_ items: [PublicInterfaceEntry], for key: URL) {
        queue.sync {
            keys.append(key)
            storage[key] = items
        }
    }

    func get(for key: URL) -> [PublicInterfaceEntry]? {
        queue.sync {
            storage[key]
        }
    }

    func remove(_ key: URL) {
        queue.sync {
            keys.removeAll { $0 == key }
            storage.removeValue(forKey: key)
        }
    }
}

extension Storage: Collection {

    // MARK: - Collection Conformance

    typealias Element = (key: URL, value: [PublicInterfaceEntry])
    typealias Index = Int

    var startIndex: Index {
        queue.sync { keys.startIndex }
    }

    var endIndex: Index {
        queue.sync { keys.endIndex }
    }

    func index(after i: Index) -> Index {
        queue.sync { keys.index(after: i) }
    }

    subscript(position: Index) -> Element {
        queue.sync {
            let key = keys[position]
            let value = storage[key] ?? []
            return (key: key, value: value)
        }
    }
}

extension Storage {

    // MARK: - Sorting

    func sorted(ascending: Bool = true) -> [Element] {
        queue.sync {
            keys
                .sorted {
                    ascending
                        ? $0.absoluteString < $1.absoluteString
                        : $0.absoluteString > $1.absoluteString
                }
                .map {
                    let value = storage[$0] ?? []
                    return (key: $0, value: value)
                }
        }
    }
}
