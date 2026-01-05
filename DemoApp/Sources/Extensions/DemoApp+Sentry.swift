//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import Sentry
import StreamVideo

func configureSentry() {
    if AppEnvironment.configuration.isRelease {
        // We're tracking Crash Reports / Issues from the Demo App to keep improving the SDK
        SentrySDK.start { options in
            options.dsn = "https://855ff07b9c1841e38842682d5a87d7b4@o389650.ingest.sentry.io/4505447573356544"
            options.debug = true
            options.tracesSampleRate = 1.0
            options.enableAppHangTracking = true
            options.failedRequestStatusCodes = [
                HttpStatusCodeRange(min: 400, max: 400),
                HttpStatusCodeRange(min: 404, max: 599)
            ]
        }

        LogConfig.destinationTypes = [
            SentryLogDestination.self,
            MemoryLogDestination.self,
            OSLogDestination.self
        ]
    } else {
        LogConfig.level = .debug
        LogConfig.webRTCLogsEnabled = true
        LogConfig.destinationTypes = [
            MemoryLogDestination.self,
            OSLogDestination.self
        ]
    }
}

private final class SentryLogDestination: LogDestination, @unchecked Sendable {
    func write(message: String) {
        // TODO: remove me once this function is gone from the protocol
    }
    
    var identifier: String
    var level: LogLevel
    var subsystems: LogSubsystem
    
    var dateFormatter: DateFormatter
    var formatters: [LogFormatter]
    
    var showDate: Bool
    var showLevel: Bool
    var showIdentifier: Bool
    var showThreadName: Bool
    var showFileName: Bool
    var showLineNumber: Bool
    var showFunctionName: Bool
    
    /// Initialize the log destination with given parameters.
    ///
    /// - Parameters:
    ///   - identifier: Identifier for this destination. Will be shown on the logs if `showIdentifier` is `true`
    ///   - level: Output level for this destination. Messages will only be shown if their output level is higher than this.
    ///   - showDate: Toggle for showing date in logs
    ///   - dateFormatter: DateFormatter instance for formatting the date in logs. Defaults to ISO8601 formatter.
    ///   - formatters: Log formatters to be applied in order before logs are outputted. Defaults to empty (no formatters).
    ///                 Please see `LogFormatter` for more info.
    ///   - showLevel: Toggle for showing log level in logs
    ///   - showIdentifier: Toggle for showing identifier in logs
    ///   - showThreadName: Toggle for showing thread name in logs
    ///   - showFileName: Toggle for showing file name in logs
    ///   - showLineNumber: Toggle for showing line number in logs
    ///   - showFunctionName: Toggle for showing function name in logs
    required init(
        identifier: String,
        level: LogLevel,
        subsystems: LogSubsystem,
        showDate: Bool,
        dateFormatter: DateFormatter,
        formatters: [LogFormatter],
        showLevel: Bool,
        showIdentifier: Bool,
        showThreadName: Bool,
        showFileName: Bool,
        showLineNumber: Bool,
        showFunctionName: Bool
    ) {
        self.identifier = identifier
        self.level = level
        self.subsystems = subsystems
        self.showIdentifier = showIdentifier
        self.showThreadName = showThreadName
        self.showDate = showDate
        self.dateFormatter = dateFormatter
        self.formatters = formatters
        self.showLevel = showLevel
        self.showFileName = showFileName
        self.showLineNumber = showLineNumber
        self.showFunctionName = showFunctionName
    }
    
    func isEnabled(level: LogLevel) -> Bool {
        assertionFailure("`isEnabled(level:)` is deprecated, please use `isEnabled(level:subsystem:)`")
        return true
    }
    
    /// Checks if this destination is enabled for the given level and subsystems.
    /// - Parameter level: Log level to be checked
    /// - Parameter subsystems: Log subsystems to be checked
    /// - Returns: `true` if destination is enabled for the given level, else `false`
    func isEnabled(level: LogLevel, subsystems: LogSubsystem) -> Bool {
        level.rawValue >= self.level.rawValue && self.subsystems.contains(subsystems)
    }
    
    /// Process the log details before outputting the log.
    /// - Parameter logDetails: Log details to be processed.
    func process(logDetails: LogDetails) {
        
        guard logDetails.level == .error || logDetails.level == .warning else {
            // Sentry does only gets warnings and errors.
            return
        }
        
        let scope = Scope()
        
        if showLevel {
            switch logDetails.level {
            case .debug:
                scope.setLevel(.debug)
            case .info:
                scope.setLevel(.info)
            case .warning:
                scope.setLevel(.warning)
            case .error:
                scope.setLevel(.error)
            }
        }
        
        if showIdentifier {
            scope.setExtra(value: "\(logDetails.loggerIdentifier)-\(identifier)", key: "identifier")
        }
        
        if showThreadName {
            scope.setExtra(value: logDetails.threadName, key: "threadName")
        }
        
        if showFileName {
            let fileName = (String(describing: logDetails.fileName) as NSString).lastPathComponent
            scope.setExtra(value: "\(fileName)\(showLineNumber ? ":\(logDetails.lineNumber)" : "")", key: "filename")
        } else if showLineNumber {
            scope.setExtra(value: "\(logDetails.lineNumber)", key: "linenumber")
        }
        
        if showFunctionName {
            scope.setExtra(value: "\(logDetails.functionName)", key: "functionName")
        }
        
        let message = logDetails.message
        
        if let error = logDetails.error {
            scope.setExtra(value: message, key: "message")
            SentrySDK.capture(error: error, scope: scope)
        } else {
            let formattedMessage = applyFormatters(logDetails: logDetails, message: message)
            SentrySDK.capture(message: formattedMessage, scope: scope)
        }
    }
    
    /// Apply formatters to the log message to be outputted
    /// Be aware that formatters are order dependent.
    /// - Parameters:
    ///   - logDetails: Log details to be passed on to formatters.
    ///   - message: Log message to be formatted
    /// - Returns: Formatted log message, formatted by all formatters in order.
    func applyFormatters(logDetails: LogDetails, message: String) -> String {
        formatters.reduce(message) { $1.format(logDetails: logDetails, message: $0) }
    }
}
