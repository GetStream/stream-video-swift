//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

enum LogQueue {
    static let queue: Queue<LogDetails> = .init(maxCount: 1000)

    static func insert(_ element: LogDetails) { queue.insert(element) }

    static var maxCount: Int {
        get { queue.maxCount }
        set { queue.maxCount = newValue }
    }
}

final class Queue<T>: ObservableObject {

    @Published private(set) var elements: [T] = []
    var maxCount: Int { didSet { resizeIfNeeded() } }
    private let queue: DispatchQueue

    init(maxCount: Int) {
        self.maxCount = maxCount
        queue = .init(label: "io.getstream.queue")
    }

    func insert(_ element: T) {
        elements.insert(element, at: 0)
        resizeIfNeeded()
    }

    private func resizeIfNeeded() {
        queue.sync {
            guard elements.endIndex > maxCount else {
                return
            }
            elements = Array(elements[0...maxCount])
        }
    }
}
