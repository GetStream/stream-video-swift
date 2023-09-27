//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

actor MemoryLeakDetector {

    struct Entry {
        var typeName: String
        var count: Int
        var maxExpectedCount: Int
        var file: StaticString
        var function: StaticString
        var line: UInt
    }

    static let `default` = MemoryLeakDetector()

    private(set) var entries: [String: Entry] = [:]

    private init() {}

    public static func track(
        _ object: @autoclosure @escaping @Sendable () -> Any,
        maxExpectedCount: Int = 1,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        Task {
            let typeName = String(describing: type(of: object()))
            let entry = await MemoryLeakDetector.default.entries[typeName] ?? .init(
                typeName: typeName,
                count: 0,
                maxExpectedCount: maxExpectedCount,
                file: file,
                function: function,
                line: line
            )

            await MemoryLeakDetector.default.increaseRefCount(for: entry)
            DeallocTracker(of: object()) { Task { await MemoryLeakDetector.default.decreaseRefCount(for: typeName) } }
        }
    }

    private func increaseRefCount(for entry: Entry) {
        var entry = entry
        entry.count += 1
        entries[entry.typeName] = entry
        if entry.count > entry.maxExpectedCount {
            log.warning(
                """
                [POTENTIAL LEAK 💦]\(entry.typeName)
                → RefCount: \(entry.count)/\(entry.maxExpectedCount)
                """,
                subsystems: .memoryLeaks
            )
        } else {
            log.debug(
                "\(entry.typeName) refCount increased to \(entry.count)/\(entry.maxExpectedCount)",
                subsystems: .memoryLeaks
            )
        }
    }

    private func decreaseRefCount(for typeName: String) {
        guard let entry = entries[typeName] else {
            log.debug("Unable to decrease refCount for deallocated \(typeName)")
            return
        }

        decreaseRefCount(for: entry)
    }

    private func decreaseRefCount(for entry: Entry) {
        var entry = entry
        entry.count = max(entry.count - 1, 0)
        entries[entry.typeName] = entry
        if entry.count == 0 {
            log.debug(
                "\(entry.typeName) freed ✅",
                subsystems: .memoryLeaks
            )
        } else {
            log.debug(
                "\(entry.typeName) refCount decreases to \(entry.count)/\(entry.maxExpectedCount)",
                subsystems: .memoryLeaks
            )
        }
    }
}

public final class MemorySnapshot: ObservableObject {

    @Published public private(set) var items: [Entry] = []

    public struct Entry {
        public var typeName: String
        public var refCount: Int
        public var maxCount: Int
    }

    @MainActor
    public init(
        includeDeallocatedObjects: Bool,
        includeNotLeaked: Bool
    ) {
        Task {
            var memoryEntries = await MemoryLeakDetector.default.entries
            if !includeDeallocatedObjects {
                memoryEntries = memoryEntries.filter { $0.value.count > 0 }
            }
            if !includeNotLeaked {
                memoryEntries = memoryEntries.filter { $0.value.count > $0.value.maxExpectedCount }
            }

            items = memoryEntries
                .map { Entry(typeName: $0.key, refCount: $0.value.count, maxCount: $0.value.maxExpectedCount) }
                .sorted { $0.typeName >= $1.typeName }
        }
    }
}

fileprivate final class DeallocTracker {
    let onDealloc: () -> Void

    @discardableResult
    init(of owner: Any, onDealloc: @escaping () -> Void) {
        self.onDealloc = onDealloc

        var mutableSelf = self
        objc_setAssociatedObject(owner, &mutableSelf, self, .OBJC_ASSOCIATION_RETAIN)
    }

    deinit {
        onDealloc()
    }
}
