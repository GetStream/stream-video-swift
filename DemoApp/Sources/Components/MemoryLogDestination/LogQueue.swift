//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

enum LogQueue {
    #if DEBUG
    private static let queueCapacity = 10000
    #else
    private static let queueCapacity = 1000
    #endif
    static let queue = Queue<LogDetails>(maxCount: queueCapacity)
    private static let file: Result<SessionLogFile, Error> = Result {
        do {
            let directory = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("StreamVideoLogs", isDirectory: true)
            return try SessionLogFile(directory: directory)
        } catch {
            print("Unable to persist logs: \(error)")
            throw error
        }
    }

    static func insert(_ element: LogDetails) {
        queue.insert(element)
        if case let .success(file) = file {
            let location = "\(element.fileName):\(element.lineNumber)"
            let metadata = "\(element.loggerIdentifier) \(element.subsystem)"
            let error = element.error.map { " Error: \($0)" } ?? ""
            file.append(
                "\(element.date.timeIntervalSince1970) \(element.level) "
                    + "[\(metadata)] [\(element.threadName)] "
                    + "[\(location):\(element.functionName)] "
                    + "\(element.message)\(error)\n"
            )
        }
    }

    static func createLogFile() async throws -> URL {
        try Task.checkCancellation()
        return try await file.get().export()
    }

    static func deleteTemporaryLogFile(at path: URL) {
        do {
            try FileManager.default.removeItem(at: path)
        } catch {
            print("Error deleting temporary log file: \(error)")
        }
    }
}
