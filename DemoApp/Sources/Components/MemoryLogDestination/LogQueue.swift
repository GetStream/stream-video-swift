//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

enum LogQueue {
    #if DEBUG
    private static let queueCapaity = 10000
    #else
    private static let queueCapaity = 1000
    #endif
    static let queue: Queue<LogDetails> = .init(maxCount: queueCapaity)

    static func insert(_ element: LogDetails) { queue.insert(element) }

    static var maxCount: Int {
        get { queue.maxCount }
        set { queue.maxCount = newValue }
    }

    static func createLogFile() throws -> URL {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let fileName = "stream_video_logs_\(Date().timeIntervalSince1970).txt"
        let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)

        // Delete any existing temporary file first
        deleteTemporaryLogFile(at: fileURL)

        // Add all logs to the content
        let logs = LogQueue.queue.elements
        let logContent = """
        Stream Video Logs - Generated: \(Date())
        \(logs.reversed().map { "\($0.level) - [\($0.fileName):\($0.lineNumber):\($0.functionName)] \($0.message)" }
            .joined(separator: "\n")
        )
        """

        try logContent.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    static func deleteTemporaryLogFile(at path: URL) {
        do {
            try FileManager.default.removeItem(at: path)
            print("Temporary log file deleted successfully")
        } catch {
            print("Error deleting temporary log file: \(error)")
        }
    }
}

final class Queue<T>: ObservableObject {

    @Published private(set) var elements: [T] = []
    var maxCount: Int { didSet { resizeIfNeeded() } }
    private let queue: DispatchQueue

    init(maxCount: Int) {
        self.maxCount = maxCount
        queue = .init(label: "io.getstream.queue")
    }

    func insert(_ element: T) {
        elements.insert(element, at: 0)
        resizeIfNeeded()
    }

    private func resizeIfNeeded() {
        queue.sync {
            guard elements.endIndex > maxCount else {
                return
            }
            elements = Array(elements[0...maxCount])
        }
    }
}
