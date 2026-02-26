//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import OSLog
import StreamVideo

@available(iOS 14.0, *)
final class OSLogDestination: BaseLogDestination, @unchecked Sendable {
    private struct LogMessage {
        var message: String
        var expandedMessage: String?

        init(
            _ source: String,
            maxOSLogMessageBytes: Int = 850
        ) {
            if source.utf8.count > maxOSLogMessageBytes {
                message = "\(source.prefix(100)) ---- (truncated)"
                expandedMessage = """
                ---- [Expanded Message - Begin] ----
                \(source)
                ---- [Expanded Message - End  ] ----
                """
            } else {
                message = source
                expandedMessage = nil
            }
        }
    }

    private let loggers: [String: os.Logger] = LogSubsystem
        .allCases
        .reduce(into: [String: os.Logger]()) {
            partialResult,
                subsystem in
            partialResult[subsystem.description] = .init(
                subsystem: subsystem.description,
                category: "Video"
            )
        }

    override func process(logDetails: LogDetails) {
        guard let logger = loggers[logDetails.subsystem.description] else {
            return
        }
        var extendedDetails: String = ""

        if showIdentifier {
            extendedDetails += "[\(logDetails.loggerIdentifier)-\(identifier)] "
        }

        if showFileName {
            let fileName = (String(describing: logDetails.fileName) as NSString).lastPathComponent
            extendedDetails += "[\(fileName)\(showLineNumber ? ":\(logDetails.lineNumber)" : "")] "
        } else if showLineNumber {
            extendedDetails += "[\(logDetails.lineNumber)] "
        }

        if showFunctionName {
            extendedDetails += "[\(logDetails.functionName)] "
        }

        if showThreadName {
            extendedDetails += logDetails.threadName
        }

        var extendedMessage = "\(extendedDetails)> \(logDetails.message)"
        if let error = logDetails.error {
            extendedMessage += "[Error: \(error)]"
        }
        let formattedMessage = LogMessage(
            LogConfig
                .formatters
                .reduce(extendedMessage) { $1.format(logDetails: logDetails, message: $0) }
        )

        log(formattedMessage.message, level: logDetails.level, logger: logger)
        if let expandedMessage = formattedMessage.expandedMessage {
            print(expandedMessage)
        }
    }

    private func log(_ message: String, level: LogLevel, logger: os.Logger) {
        switch level {
        case .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.notice("\(message, privacy: .public)")
        case .warning:
            logger.warning("\(message, privacy: .public)")
        case .error:
            logger.critical("\(message, privacy: .public)")
        }
    }
}
