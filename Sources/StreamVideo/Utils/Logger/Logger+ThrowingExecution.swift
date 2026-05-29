//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Logger {

    /// Executes a throwing operation and routes any failures to the logging
    /// backend using the supplied metadata.
    func throwing(
        _ message: @autoclosure () -> String = "",
        subsystems: LogSubsystem,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        _ operation: () throws -> Void
    ) {
        do {
            try operation()
        } catch {
            self.error(
                message(),
                subsystems: subsystems,
                error: error,
                functionName: function,
                fileName: file,
                lineNumber: line
            )
        }
    }

    /// Executes an async throwing operation and logs failures with call-site
    /// metadata.
    ///
    /// This is useful for fire-and-forget bridge work such as best-effort
    /// CallKit reporting. The caller wants failures to appear in logs with the
    /// original file, function, and line, but it should not fail the surrounding
    /// Combine or state-observation pipeline.
    func throwing(
        _ message: @autoclosure () -> String = "",
        subsystems: LogSubsystem,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        _ operation: @Sendable () async throws -> Void
    ) async {
        do {
            try await operation()
        } catch {
            self.error(
                message(),
                subsystems: subsystems,
                error: error,
                functionName: function,
                fileName: file,
                lineNumber: line
            )
        }
    }
}
