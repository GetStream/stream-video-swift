//
//  Array+Log.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 6/8/24.
//

import Foundation

extension Array {
    public func log(
        _ level: LogLevel,
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line,
        messageBuilder: ((Self) -> String)? = nil
    ) -> Self {
        LogConfig
            .logger
            .log(
            level,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: messageBuilder?(self) ?? "\(self)",
            subsystems: subsystems,
            error: nil
        )
        return self
    }
}
