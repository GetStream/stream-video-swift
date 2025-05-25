//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

public final class Timers {
    private let queue = UnfairQueue()
    private var storage: [TimeInterval: AnyPublisher<Date, Never>] = [:]

    private init() {}

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

extension Timers: InjectionKey {
    nonisolated(unsafe) public static var currentValue = Timers()
}

extension InjectedValues {
    public var timers: Timers {
        get { Self[Timers.self] }
        set { Self[Timers.self] = newValue }
    }
}
