//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import OSLog

public var trace: Signposting {
    if #available(iOS 15.0, *) {
        Signposter.shared
    } else {
        DummySignposter.shared
    }
}

public protocol Signposting {
    func trace<T>(
        subsystem: LogSubsystem,
        file: StaticString,
        function: StaticString,
        line: UInt,
        block: () throws -> T
    ) rethrows -> T

    func trace<T>(
        subsystem: LogSubsystem,
        file: StaticString,
        function: StaticString,
        line: UInt,
        block: @Sendable() async throws -> T
    ) async rethrows -> T
}

final class DummySignposter: Signposting {
    fileprivate nonisolated(unsafe) static let shared = DummySignposter()

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
        block: @Sendable() async throws -> T
    ) async rethrows -> T { try await block() }
}

@available(iOS 15.0, *)
final class Signposter: Signposting {
    fileprivate nonisolated(unsafe) static let shared = Signposter()
    @Atomic private var loggers: [LogSubsystem.RawValue: OSSignposter] = [:]

    private init() {}

    func trace<T>(
        subsystem: LogSubsystem,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        block: () throws -> T
    ) rethrows -> T {
        let signposter = logger(for: subsystem)
        let signpostID = signposter.makeSignpostID()
        let state = signposter.beginInterval(function, id: signpostID, "\(file):\(line)")
        defer { signposter.endInterval(function, state) }
        return try block()
    }

    func trace<T>(
        subsystem: LogSubsystem,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        block: @Sendable() async throws -> T
    ) async rethrows -> T {
        let signposter = logger(for: subsystem)
        let signpostID = signposter.makeSignpostID()
        let state = signposter.beginInterval(function, id: signpostID, "\(file):\(line)")
        defer { signposter.endInterval(function, state) }
        return try await block()
    }

    private func logger(for key: LogSubsystem) -> OSSignposter {
        if let logger = loggers[key.rawValue] {
            return logger
        } else {
            let signposter = OSSignposter(subsystem: "io.getstream.video", category: key.description)
            loggers[key.rawValue] = signposter
            return signposter
        }
    }
}
