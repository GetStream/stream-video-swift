//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A `Publisher` that wraps an `AsyncStream` and publishes its elements.
///
/// `AsyncStreamPublisher` conforms to the `Publisher` protocol and allows
/// bridging between Combine and Swift's `AsyncStream`. It publishes elements
/// from the `AsyncStream` to its subscribers.
///
/// - Note: The `Failure` type is constrained to `Never` as `AsyncStream`
///   doesn't support error propagation.
///
/// - Parameters:
///   - Element: The type of elements published by this publisher.
///
/// - Example:
/// ```swift
/// let asyncStream = AsyncStream<Int> { continuation in
///     continuation.yield(1)
///     continuation.yield(2)
///     continuation.finish()
/// }
/// let publisher = AsyncStreamPublisher(asyncStream)
/// ```
///
/// - SeeAlso: `AsyncStream`, `Publisher`
struct AsyncStreamPublisher<Element>: Publisher {
    typealias Output = Element
    typealias Failure = Never

    private let asyncStream: AsyncStream<Element>

    init(_ asyncStream: AsyncStream<Element>) {
        self.asyncStream = asyncStream
    }

    func receive<S>(
        subscriber: S
    ) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = AsyncStreamSubscription(
            subscriber: subscriber,
            asyncStream: asyncStream
        )
        subscriber.receive(subscription: subscription)
    }
}

private final class AsyncStreamSubscription<S: Subscriber, Element>: Subscription, @unchecked Sendable where S.Input == Element,
    S.Failure == Never {
    private var subscriber: S?
    private let asyncStream: AsyncStream<Element>
    private var task: Task<Void, Never>?

    init(subscriber: S, asyncStream: AsyncStream<Element>) {
        self.subscriber = subscriber
        self.asyncStream = asyncStream
        startStreaming()
    }

    private func startStreaming() {
        task = Task {
            for await value in asyncStream {
                _ = subscriber?.receive(value)
            }
            subscriber?.receive(completion: .finished)
        }
    }

    func request(_ demand: Subscribers.Demand) {
        // No-op: AsyncStream doesn't support backpressure
    }

    func cancel() {
        task?.cancel()
        subscriber = nil
    }
}
