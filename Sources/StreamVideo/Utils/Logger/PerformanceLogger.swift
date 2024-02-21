//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import os.signpost

public final class StreamPerformanceLogger {

    static let `default` = StreamPerformanceLogger()
    private init() {}

    private let performanceLog = OSLog(
        subsystem: "io.getstream.performance.logger",
        category: "PerformanceMetrics"
    )

    public func begin(_ name: StaticString) {
        #if DEBUG
        os_signpost(.begin, log: performanceLog, name: name)
        #endif
    }

    public func end(_ name: StaticString) {
        #if DEBUG
        os_signpost(.end, log: performanceLog, name: name)
        #endif
    }

    public func measureExecution<T>(
        name: StaticString,
        _ handler: () -> T
    ) -> T {
        #if DEBUG
        os_signpost(.begin, log: performanceLog, name: name)
        defer { os_signpost(.end, log: performanceLog, name: name) }
        return handler()
        #else
        return handler()
        #endif
    }

    public func measureExecution<T>(
        name: StaticString,
        _ handler: () throws -> T
    ) rethrows -> T {
        #if DEBUG
        os_signpost(.begin, log: performanceLog, name: name)
        defer { os_signpost(.end, log: performanceLog, name: name) }
        return try handler()
        #else
        return try handler()
        #endif
    }

    public func measureExecution<T>(
        name: StaticString,
        _ handler: () async -> T
    ) async -> T {
        #if DEBUG
        os_signpost(.begin, log: performanceLog, name: name)
        defer { os_signpost(.end, log: performanceLog, name: name) }
        return await handler()
        #else
        return await handler()
        #endif
    }

    public func measureExecution<T>(
        name: StaticString,
        _ handler: () async throws -> T
    ) async rethrows -> T {
        #if DEBUG
        os_signpost(.begin, log: performanceLog, name: name)
        defer { os_signpost(.end, log: performanceLog, name: name) }
        return try await handler()
        #else
        return try await handler()
        #endif
    }
}

/// Provides the default value of the `StreamPerformanceLogger` class.
public struct StreamPerformanceLoggerKey: InjectionKey {
    public static var currentValue: StreamPerformanceLogger = .default
}

extension InjectedValues {
    /// Provides access to the `StreamPerformanceLogger` class to the views and view models.
    public var performanceLogger: StreamPerformanceLogger {
        get {
            Self[StreamPerformanceLoggerKey.self]
        }
        set {
            _ = newValue
        }
    }
}
