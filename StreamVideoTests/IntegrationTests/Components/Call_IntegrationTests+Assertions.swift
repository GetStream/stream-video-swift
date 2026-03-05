//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

extension Call_IntegrationTests {
    enum Assertions {

        static func assert(
            file: StaticString = #filePath,
            line: UInt = #line,
            _ message: @autoclosure () -> String = "",
            _ condition: @Sendable () async throws -> Bool
        ) async throws {
            let result = try await condition()
            XCTAssertTrue(result, message(), file: file, line: line)
        }

        static func assertEventually(
            timeout: TimeInterval = defaultTimeout,
            interval: TimeInterval = 0.1,
            file: StaticString = #filePath,
            line: UInt = #line,
            _ message: @autoclosure () -> String = "",
            _ condition: @Sendable () async throws -> Bool
        ) async throws {
            do {
                try await Retry.waitUntil(
                    timeout: timeout,
                    interval: interval,
                    operation: condition
                )
            } catch let FlowError.timeout(timeoutMessage) {
                XCTAssertTrue(
                    false,
                    message().isEmpty ? timeoutMessage : message(),
                    file: file,
                    line: line
                )
            } catch {
                throw error
            }
        }

        static func assertFromAsyncStream<Element: Sendable>(
            timeout: TimeInterval = defaultTimeout,
            interval: TimeInterval = 0.1,
            fileID: StaticString = #fileID,
            filePath: StaticString = #filePath,
            line: UInt = #line,
            message: @autoclosure () -> String = "",
            stream: AsyncStream<Element>,
            operation: @Sendable @escaping (Element) async throws -> Bool
        ) async throws {
            let timeout = max(0, timeout)
            let result = try await Task(
                timeoutInSeconds: timeout,
                file: fileID,
                line: line
            ) {
                for await element in stream {
                    if try await operation(element) {
                        return true
                    }
                }
                return false
            }.value

            guard !result else {
                return
            }

            XCTAssertTrue(
                false,
                message(),
                file: filePath,
                line: line
            )
        }

        static func assertFromAsyncStream<Element: Sendable>(
            timeout: TimeInterval = defaultTimeout,
            interval: TimeInterval = 0.1,
            fileID: StaticString = #fileID,
            filePath: StaticString = #filePath,
            line: UInt = #line,
            message: @autoclosure () -> String = "",
            stream: AsyncThrowingStream<Element, Error>,
            operation: @Sendable @escaping (Element) async throws -> Bool
        ) async throws {
            let timeout = max(0, timeout)
            let result = try await Task(
                timeoutInSeconds: timeout,
                file: fileID,
                line: line
            ) {
                for try await element in stream {
                    if try await operation(element) {
                        return true
                    }
                }
                return false
            }.value

            guard !result else {
                return
            }

            XCTAssertTrue(
                false,
                message(),
                file: filePath,
                line: line
            )
        }

        static func assertFromPublisher<Output: Sendable, Failure: Error>(
            timeout: TimeInterval = defaultTimeout,
            interval: TimeInterval = 0.1,
            fileID: StaticString = #fileID,
            filePath: StaticString = #filePath,
            line: UInt = #line,
            message: @autoclosure () -> String = "",
            publisher: AnyPublisher<Output, Failure>,
            operation: @Sendable @escaping (Output) async throws -> Bool
        ) async throws {
            try await Self.assertFromAsyncStream(
                timeout: timeout,
                interval: interval,
                fileID: fileID,
                filePath: filePath,
                line: line,
                message: message(),
                stream: publisher.eraseAsAsyncThrowingStream(),
                operation: operation
            )
        }
    }
}

extension Call_IntegrationTests.Assertions {

    fileprivate enum FlowError: Error {
        case assertionFailed(String)
        case timeout(String)
    }

    fileprivate enum Retry {
        static func waitUntil(
            timeout: TimeInterval = defaultTimeout,
            interval: TimeInterval = 0.1,
            operation: @Sendable () async throws -> Bool
        ) async throws {
            let deadline = Date().timeIntervalSince1970 + timeout
            while true {
                if try await operation() { return }
                if Date().timeIntervalSince1970 >= deadline {
                    throw FlowError.timeout("Condition not satisfied within \(timeout)s")
                }
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }
}

private extension Publisher where Output: Sendable {

    func eraseAsAsyncThrowingStream() -> AsyncThrowingStream<Output, Error> {
        AsyncThrowingStream { continuation in
            let cancellable = sink(
                receiveCompletion: {
                    switch $0 {
                    case .finished:
                        continuation.finish()
                    case let .failure(error):
                        continuation.finish(throwing: error)
                    }
                },
                receiveValue: {
                    continuation.yield($0)
                }
            )

            continuation.onTermination = { @Sendable _ in
                cancellable.cancel()
            }
        }
    }
}
