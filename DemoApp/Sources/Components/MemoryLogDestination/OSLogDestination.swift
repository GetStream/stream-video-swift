//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import OSLog
import StreamVideo

final class OSLogDestination: BaseLogDestination, @unchecked Sendable {

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
        let formattedMessage = LogConfig
            .formatters
            .reduce(extendedMessage) { $1.format(logDetails: logDetails, message: $0) }

        switch logDetails.level {
        case .debug:
            logger.debug("\(formattedMessage, privacy: .public)")
        case .info:
            logger.notice("\(formattedMessage, privacy: .public)")
        case .warning:
            logger.warning("\(formattedMessage, privacy: .public)")
        case .error:
            logger.critical("\(formattedMessage, privacy: .public)")
        }
    }
}
