//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import OSLog

public protocol Signposting {
    /// Measures the execution time of a synchronous block using signposts.
    ///
    /// - Parameters:
    ///   - subsystem: The log subsystem used for categorizing the trace.
    ///   - file: The file where the trace is initiated.
    ///   - function: The function where the trace is initiated.
    ///   - line: The line number where the trace is initiated.
    ///   - block: A closure whose execution will be measured.
    /// - Returns: The result of the closure.
    func trace<T>(
        subsystem: LogSubsystem,
        file: StaticString,
        function: StaticString,
        line: UInt,
        block: () throws -> T
    ) rethrows -> T

    /// Measures the execution time of an asynchronous block using signposts.
    ///
    /// - Parameters:
    ///   - subsystem: The log subsystem used for categorizing the trace.
    ///   - file: The file where the trace is initiated.
    ///   - function: The function where the trace is initiated.
    ///   - line: The line number where the trace is initiated.
    ///   - block: An async closure whose execution will be measured.
    /// - Returns: The result of the async closure.
    func trace<T>(
        subsystem: LogSubsystem,
        file: StaticString,
        function: StaticString,
        line: UInt,
        block: @Sendable () async throws -> T
    ) async rethrows -> T
}

public var trace: Signposting {
    if #available(iOS 15.0, *) {
        Signposter.shared
    } else {
        NoopSignposter.shared
    }
}

final class NoopSignposter: Signposting {
    fileprivate nonisolated(unsafe) static let shared = NoopSignposter()

    func trace<T>(
        subsystem: LogSubsystem,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        block: () throws -> T
    ) rethrows -> T { try block() }

    func trace<T>(
        subsystem: LogSubsystem,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        block: @Sendable () async throws -> T
    ) async rethrows -> T { try await block() }
}

@available(iOS 15.0, *)
final class Signposter: Signposting {
    fileprivate nonisolated(unsafe) static let shared = Signposter()
    @Atomic private var storage: [LogSubsystem.RawValue: OSSignposter] = [:]

    private init() {}

    func trace<T>(
        subsystem: LogSubsystem,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        block: () throws -> T
    ) rethrows -> T {
        let signposter = signposter(for: subsystem)
        let signpostID = signposter.makeSignpostID()
        let file = URL(fileURLWithPath: "\(file)").lastPathComponent.split(separator: ".")[0]
        let state = signposter.beginInterval(function, id: signpostID, "\(file):\(line)")
        defer { signposter.endInterval(function, state) }
        return try block()
    }

    func trace<T>(
        subsystem: LogSubsystem,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        block: @Sendable () async throws -> T
    ) async rethrows -> T {
        let signposter = signposter(for: subsystem)
        let signpostID = signposter.makeSignpostID()
        let file = URL(fileURLWithPath: "\(file)").lastPathComponent.split(separator: ".")[0]
        let state = signposter.beginInterval(function, id: signpostID, "\(file):\(line)")
        defer { signposter.endInterval(function, state) }
        return try await block()
    }

    private func signposter(for key: LogSubsystem) -> OSSignposter {
        if let result = storage[key.rawValue] {
            return result
        } else {
            let result = OSSignposter(subsystem: "io.getstream.video", category: key.description)
            storage[key.rawValue] = result
            return result
        }
    }
}
