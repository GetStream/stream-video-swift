//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
}
