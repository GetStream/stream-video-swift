//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import XCTest

extension Call_IntegrationTests {
    final class CallFlow<Result: Sendable>: Sendable {
        let call: Call
        let client: StreamVideo
        let value: Result

        convenience init(
            client: StreamVideo,
            call: Call
        ) where Result == Void {
            self.init(
                client: client,
                call: call,
                value: ()
            )
        }

        init(
            client: StreamVideo,
            call: Call,
            value: Result
        ) {
            self.call = call
            self.value = value
            self.client = client
        }

        /// Generic step: output becomes next flow payload.
        @discardableResult
        func perform<Next: Sendable>(
            _ operation: @Sendable (_ flow: CallFlow<Result>) async throws -> Next
        ) async throws -> CallFlow<Next> {
            let nextValue = try await operation(self)
            return .init(
                client: client,
                call: call,
                value: nextValue
            )
        }
        
        @discardableResult
        func performWithoutValueOverride(
            _ operation: @Sendable (_ flow: Self) async throws -> Void
        ) async throws -> Self {
            try await operation(self)
            return self
        }

        @discardableResult
        func performWithErrorExpectation<Value: Sendable>(
            file: StaticString = #fileID,
            line: UInt = #line,
            _ operation: @Sendable (_ flow: CallFlow<Result>) async throws -> Value
        ) async throws -> CallFlow<Error> {
            do {
                _ = try await operation(self)
            } catch {
                return .init(
                    client: client,
                    call: call,
                    value: error
                )
            }
            throw ClientError("Flow is expected to fail", file, line)
        }

        @discardableResult
        func assert(
            file: StaticString = #filePath,
            line: UInt = #line,
            _ message: @autoclosure () -> String = "",
            _ condition: @Sendable (_ flow: CallFlow<Result>) async throws -> Bool
        ) async throws -> Self {
            try await Assertions.assert(file: file, line: line, message()) {
                try await condition(self)
            }
            return self
        }

        @discardableResult
        func assertInMainActor(
            file: StaticString = #filePath,
            line: UInt = #line,
            _ condition: @MainActor @Sendable (_ flow: CallFlow<Result>) async throws -> Bool,
            _ message: @autoclosure () -> String = ""
        ) async throws -> Self {
            try await Assertions.assert(file: file, line: line, message()) {
                try await condition(self)
            }
            return self
        }

        @discardableResult
        func assertEventually(
            timeout: TimeInterval = defaultTimeout,
            file: StaticString = #filePath,
            line: UInt = #line,
            _ condition: @Sendable (_ flow: CallFlow<Result>) async throws -> Bool
        ) async throws -> Self {
            try await Assertions.assertEventually(timeout: timeout, file: file, line: line) {
                try await condition(self)
            }
            return self
        }

        @discardableResult
        func assertEventuallyInMainActor(
            timeout: TimeInterval = defaultTimeout,
            file: StaticString = #filePath,
            line: UInt = #line,
            _ condition: @MainActor @Sendable (_ flow: CallFlow<Result>) async throws -> Bool
        ) async throws -> Self {
            try await Assertions.assertEventually(timeout: timeout, file: file, line: line) {
                try await condition(self)
            }
            return self
        }

        @discardableResult
        func assertEventually<Element: Sendable>(
            timeout: TimeInterval = defaultTimeout,
            interval: TimeInterval = 0.1,
            _ condition: @Sendable @escaping (_ element: Element) async throws -> Bool
        ) async throws -> Self where Result == AsyncStream<Element> {
            try await Assertions.assertFromAsyncStream(
                timeout: timeout,
                interval: interval,
                stream: value
            ) { try await condition($0) }
            return self
        }

        @discardableResult
        func assertEventually<Output: Sendable, Failure>(
            timeout: TimeInterval = defaultTimeout,
            interval: TimeInterval = 0.1,
            _ condition: @Sendable @escaping (_ element: Output) async throws -> Bool
        ) async throws -> Self where Result == AnyPublisher<Output, Failure> {
            try await Assertions.assertFromPublisher(
                timeout: timeout,
                interval: interval,
                publisher: value
            ) { try await condition($0) }
            return self
        }

        // MARK: - Timing

        @discardableResult
        func delay(
            _ interval: TimeInterval
        ) async throws -> Self {
            let clampedInterval = max(0, interval)
            guard clampedInterval > 0 else {
                return self
            }

            try await Task.sleep(
                nanoseconds: UInt64(clampedInterval * 1_000_000_000)
            )
            return self
        }

        // MARK: - Subscription

        @discardableResult
        func subscribe<WSEvent: Event>(for event: WSEvent.Type) -> CallFlow<AsyncStream<WSEvent>> {
            let value = client.subscribe(for: event)
            return .init(client: client, call: call, value: value)
        }

        // MARK: - Map

        @discardableResult
        func tryMap<Next: Sendable>(
            _ message: @autoclosure () -> String = "Flow value was nil",
            _ transformation: @Sendable (_ flow: CallFlow<Result>) async throws -> Next?
        ) async throws -> CallFlow<Next> {
            guard let nextValue = try await transformation(self) else {
                throw ClientError(message())
            }
            return .init(
                client: client,
                call: call,
                value: nextValue
            )
        }

        @discardableResult
        func map<Next: Sendable>(
            _ transformation: @Sendable (_ flow: CallFlow<Result>) async throws -> Next
        ) async throws -> CallFlow<Next> {
            let mappedValue = try await transformation(self)
            return .init(
                client: client,
                call: call,
                value: mappedValue
            )
        }
    }
}
