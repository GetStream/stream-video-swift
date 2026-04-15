//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine

private enum RelayBuffer<Output> {
    case empty
    case value(Output)
}

extension Publisher where Output: Sendable {

    /// Eagerly subscribes to the upstream publisher and replays the
    /// latest emitted value to every new downstream subscriber while
    /// the upstream publisher remains active.
    ///
    /// Unlike operators such as `.share()`, `.relay()` subscribes
    /// **synchronously** at call-time, so values emitted before a
    /// downstream subscriber attaches are available to later subscribers.
    /// Upstream completion is forwarded immediately.
    ///
    /// ```swift
    /// let source = PassthroughSubject<Int, Error>()
    /// let relay  = source.relay()
    ///
    /// source.send(42)                       // no downstream yet
    /// let value = try await relay.nextValue // returns 42
    /// ```
    func relay() -> RelayPublisher<Output, Failure> {
        RelayPublisher(upstream: self)
    }
}

/// A publisher that eagerly subscribes to its upstream and replays
/// the latest value to late subscribers while the upstream remains
/// active.
///
/// Created via the ``Publisher/relay()`` operator.
final class RelayPublisher<Output, Failure: Error>: Publisher,
    @unchecked Sendable {

    private let buffer = CurrentValueSubject<RelayBuffer<Output>, Failure>(.empty)
    private var upstreamCancellable: AnyCancellable?

    init<P: Publisher>(
        upstream: P
    ) where P.Output == Output, P.Failure == Failure {
        upstreamCancellable = upstream.sink(
            receiveCompletion: { [buffer] in
                buffer.send(completion: $0)
            },
            receiveValue: { [buffer] in buffer.send(.value($0)) }
        )
    }

    deinit {
        upstreamCancellable?.cancel()
    }

    // MARK: - Publisher

    func receive<S: Subscriber>(
        subscriber: S
    ) where S.Input == Output, S.Failure == Failure {
        buffer
            .compactMap {
                guard case let .value(value) = $0 else {
                    return nil
                }
                return value
            }
            .receive(subscriber: subscriber)
    }
}
