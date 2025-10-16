//
//  Logger+ThrowingExecution.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 16/10/25.
//

import Foundation

extension Logger {

    func throwing(
        _ message: @autoclosure () -> String,
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
