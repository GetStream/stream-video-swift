//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import UIKit

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

// All mutable ring state is protected by the lock.
final class Queue<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [T?]
    private var nextIndex = 0
    private var count = 0

    var elements: [T] {
        lock.lock()
        defer { lock.unlock() }
        return (0..<count).compactMap {
            storage[(nextIndex - 1 - $0 + storage.count) % storage.count]
        }
    }

    init(maxCount: Int) {
        precondition(maxCount >= 0)
        storage = Array(repeating: nil, count: maxCount)
    }

    func insert(_ element: T) {
        lock.lock()
        defer { lock.unlock() }
        guard !storage.isEmpty else { return }
        storage[nextIndex] = element
        nextIndex = (nextIndex + 1) % storage.count
        count = min(count + 1, storage.count)
    }
}

// Writer state is confined to writerQueue; exports own their read handles.
final class SessionLogFile: @unchecked Sendable {
    private let writerQueue = DispatchQueue(
        label: "io.getstream.demo.logs",
        qos: .utility
    )
    private let directory: URL
    private let handle: FileHandle
    private let timer: DispatchSourceTimer
    private var backgroundObserver: NSObjectProtocol?
    private var buffer = Data()
    private var failure: Error?
    private let batchSize = 64 * 1024

    init(directory: URL) throws {
        self.directory = directory
        let manager = FileManager.default
        try manager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        var resourceURL = directory
        var resources = URLResourceValues()
        resources.isExcludedFromBackup = true
        try resourceURL.setResourceValues(resources)

        let current = directory.appendingPathComponent("current.txt")
        let previous = directory.appendingPathComponent("previous.txt")
        if manager.fileExists(atPath: current.path) {
            if manager.fileExists(atPath: previous.path) {
                try manager.removeItem(at: previous)
            }
            try manager.moveItem(at: current, to: previous)
        }
        let header = "Stream Video Logs - Session: \(Date())\n"
        try Data(header.utf8).write(to: current)
        handle = try FileHandle(forWritingTo: current)
        try handle.seekToEnd()
        timer = DispatchSource.makeTimerSource(queue: writerQueue)
        timer.schedule(
            deadline: .now() + 1,
            repeating: 1,
            leeway: .milliseconds(250)
        )
        timer.setEventHandler { [weak self] in
            try? self?.flush()
        }
        timer.resume()
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.writerQueue.async { [weak self] in
                try? self?.flush()
            }
        }
    }

    deinit {
        timer.cancel()
        if let backgroundObserver {
            NotificationCenter.default.removeObserver(backgroundObserver)
        }
        try? handle.close()
    }

    func append(_ entry: String) {
        writerQueue.sync {
            guard failure == nil else { return }
            buffer.append(contentsOf: entry.utf8)
            if buffer.count >= batchSize {
                try? flush()
            }
        }
    }

    func export() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            writerQueue.async { [self] in
                var sources: [(FileHandle, UInt64)] = []
                do {
                    try flush()
                    for name in ["previous.txt", "current.txt"] {
                        let url = directory.appendingPathComponent(name)
                        guard FileManager.default.fileExists(
                            atPath: url.path
                        ) else { continue }
                        let input = try FileHandle(forReadingFrom: url)
                        do {
                            let length = try input.seekToEnd()
                            try input.seek(toOffset: 0)
                            sources.append((input, length))
                        } catch {
                            try? input.close()
                            throw error
                        }
                    }
                    let inputs = sources
                    DispatchQueue.global(qos: .utility).async { [self] in
                        defer { inputs.forEach { try? $0.0.close() } }
                        continuation.resume(with: Result {
                            try copyLogs(from: inputs)
                        })
                    }
                } catch {
                    sources.forEach { try? $0.0.close() }
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func copyLogs(from sources: [(FileHandle, UInt64)]) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("stream_video_logs_\(UUID()).txt")
        do {
            try Data().write(to: url)
            let output = try FileHandle(forWritingTo: url)
            defer { try? output.close() }
            for (input, length) in sources {
                var remaining = length
                while remaining > 0 {
                    guard let chunk = try input.read(
                        upToCount: Int(min(UInt64(batchSize), remaining))
                    ), !chunk.isEmpty else {
                        throw CocoaError(.fileReadCorruptFile)
                    }
                    try output.write(contentsOf: chunk)
                    remaining -= UInt64(chunk.count)
                }
            }
            return url
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw error
        }
    }

    private func flush() throws {
        if let failure { throw failure }
        guard !buffer.isEmpty else { return }
        do {
            try handle.write(contentsOf: buffer)
            buffer.removeAll(keepingCapacity: true)
        } catch {
            failure = error
            print("Unable to persist logs: \(error)")
            throw error
        }
    }
}
