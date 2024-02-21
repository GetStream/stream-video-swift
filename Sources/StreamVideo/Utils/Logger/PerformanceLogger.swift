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

    public func measureExecution(
        name: StaticString,
        _ handler: @escaping () -> Void
    ) {
        #if DEBUG
        os_signpost(.begin, log: performanceLog, name: name)
        defer { os_signpost(.end, log: performanceLog, name: name) }
        handler()
        #else
        handler()
        #endif
    }

    public func measureExecution(
        name: StaticString,
        _ handler: @escaping () throws -> Void
    ) rethrows {
        #if DEBUG
        os_signpost(.begin, log: performanceLog, name: name)
        defer { os_signpost(.end, log: performanceLog, name: name) }
        try handler()
        #else
        try handler()
        #endif
    }

    public func measureExecution(
        name: StaticString,
        _ handler: @escaping () async -> Void
    ) async {
        #if DEBUG
        os_signpost(.begin, log: performanceLog, name: name)
        defer { os_signpost(.end, log: performanceLog, name: name) }
        await handler()
        #else
        await handler()
        #endif
    }

    public func measureExecution(
        name: StaticString,
        _ handler: @escaping () async throws -> Void
    ) async rethrows {
        #if DEBUG
        os_signpost(.begin, log: performanceLog, name: name)
        defer { os_signpost(.end, log: performanceLog, name: name) }
        try await handler()
        #else
        try await handler()
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
