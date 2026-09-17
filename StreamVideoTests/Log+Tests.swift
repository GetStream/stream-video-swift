//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import XCTest

/// Configures SDK logging for tests.
///
/// Xcode's test console shows `OSLogDestination`. `xcodebuild` / Fastlane /
/// CI do not stream simulator stdout, so logs are buffered per test id and
/// attached on failure as `{Class}.{method}.log`.
open class LogTestCase: XCTestCase, @unchecked Sendable {

    open override func setUp() {
        FileLogDestination.begin(testLogID)
        LogConfig.level = .debug
        if #available(iOS 14.0, *) {
            LogConfig.destinationTypes = [
                OSLogDestination.self,
                FileLogDestination.self
            ]
        } else {
            LogConfig.destinationTypes = [FileLogDestination.self]
        }
        super.setUp()
    }

    open override func tearDown() {
        attachSDKLogsIfNeeded()
        FileLogDestination.end(testLogID)
        super.tearDown()
    }

    private func attachSDKLogsIfNeeded() {
        guard testRun?.totalFailureCount ?? 0 > 0 else { return }
        let data = FileLogDestination.data(for: testLogID)
        guard !data.isEmpty else { return }
        let attachment = XCTAttachment(
            data: data,
            uniformTypeIdentifier: "public.log"
        )
        attachment.name = "\(testLogID).log"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// `Call_IntegrationTests.test_accept_whenUserAcceptsTheCall_...`
    var testLogID: String {
        let className = String(describing: type(of: self))
            .split(separator: ".")
            .last
            .map(String.init) ?? "XCTestCase"
        let methodName: String = {
            let raw = name
            guard let space = raw.lastIndex(of: " ") else {
                return raw
            }
            return String(raw[raw.index(after: space)...])
                .trimmingCharacters(in: CharacterSet(charactersIn: "]"))
        }()
        return Self.safeFilename("\(className).\(methodName)")
    }

    private static func safeFilename(_ raw: String) -> String {
        String(raw.map { character in
            if character.isLetter
                || character.isNumber
                || character == "_"
                || character == "-"
                || character == "." {
                return character
            }
            return "_"
        })
    }
}

/// In-process buffers keyed by test id. Clones are separate processes.
final class FileLogDestination: BaseLogDestination, @unchecked Sendable {
    private static let lock = UnfairQueue()
    nonisolated(unsafe) private static var buffers: [String: Data] = [:]
    nonisolated(unsafe) private static var activeTestID = ""

    /// Captured at init so loggerQueue writes stay on this test's buffer.
    private let testID: String

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
        testID = Self.activeTestID
        super.init(
            identifier: identifier,
            level: level,
            subsystems: subsystems,
            showDate: showDate,
            dateFormatter: dateFormatter,
            formatters: formatters,
            showLevel: showLevel,
            showIdentifier: showIdentifier,
            showThreadName: showThreadName,
            showFileName: showFileName,
            showLineNumber: showLineNumber,
            showFunctionName: showFunctionName
        )
    }

    static func begin(_ id: String) {
        lock.sync {
            activeTestID = id
            buffers[id] = Data()
        }
    }

    static func data(for id: String) -> Data {
        lock.sync {
            return buffers[id] ?? Data()
        }
    }

    static func end(_ id: String) {
        lock.sync {
            buffers.removeValue(forKey: id)
            if activeTestID == id {
                activeTestID = ""
            }
        }
    }

    override func write(message: String) {
        guard let chunk = (message + "\n").data(using: .utf8) else {
            return
        }
        Self.lock.sync {
            Self.buffers[testID, default: Data()].append(chunk)
        }
    }
}
