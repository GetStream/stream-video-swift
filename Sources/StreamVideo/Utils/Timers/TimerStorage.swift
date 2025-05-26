//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

public protocol TimerStorage {
    func timer(for interval: TimeInterval) -> AnyPublisher<Date, Never>
}

final class StreamTimerStorage: TimerStorage {
    private let queue = UnfairQueue()
    private var storage: [TimeInterval: AnyPublisher<Date, Never>] = [:]

    fileprivate init() {}

    public func timer(for interval: TimeInterval) -> AnyPublisher<Date, Never> {
        queue.sync {
            if let publisher = storage[interval] {
                return publisher
            } else {
                let publisher = Foundation
                    .Timer
                    .publish(every: interval, tolerance: interval, on: .main, in: .common)
                    .autoconnect()
                    .eraseToAnyPublisher()
                storage[interval] = publisher
                return publisher
            }
        }
    }
}

enum TimerStorageKey: InjectionKey {
    nonisolated(unsafe) public static var currentValue: TimerStorage = StreamTimerStorage()
}

extension InjectedValues {
    public var timers: TimerStorage {
        get { Self[TimerStorageKey.self] }
        set { Self[TimerStorageKey.self] = newValue }
    }
}
