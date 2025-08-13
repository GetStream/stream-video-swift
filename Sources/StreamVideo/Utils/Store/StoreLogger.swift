//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

class StoreLogger<Namespace: StoreNamespace> {

    let logSubsystem: LogSubsystem

    init(logSubsystem: LogSubsystem = .other) {
        self.logSubsystem = logSubsystem
    }

    func didComplete(
        identifier: String,
        action: Namespace.Action,
        state: Namespace.State,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        log.debug(
            "Store identifier:\(identifier) completed action:\(action) state:\(state).",
            subsystems: logSubsystem,
            functionName: function,
            fileName: file,
            lineNumber: line
        )
    }

    func didFail(
        identifier: String,
        action: Namespace.Action,
        error: Error,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        log.error(
            "Store identifier:\(identifier) failed to apply action:\(action).",
            subsystems: logSubsystem,
            error: error,
            functionName: function,
            fileName: file,
            lineNumber: line
        )
    }
}
