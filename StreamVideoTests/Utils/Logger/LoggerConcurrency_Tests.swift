//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class LoggerConcurrency_Tests: XCTestCase, @unchecked Sendable {

    func test_webRTCLogsEnabled_updatesWebRTCMode() {
        let originalMode = Logger.WebRTC.mode
        defer { Logger.WebRTC.mode = originalMode }

        LogConfig.webRTCLogsEnabled = false

        XCTAssertFalse(LogConfig.webRTCLogsEnabled)
        guard case .none = Logger.WebRTC.mode else {
            return XCTFail("Expected WebRTC logging to be disabled.")
        }

        LogConfig.webRTCLogsEnabled = true

        XCTAssertTrue(LogConfig.webRTCLogsEnabled)
        guard case .all = Logger.WebRTC.mode else {
            return XCTFail("Expected WebRTC logging to be enabled.")
        }
    }

    func test_concurrentLoggingProcessesAllMessages() {
        let iterations = 200
        let expectation = expectation(description: "All log messages are processed")
        expectation.expectedFulfillmentCount = iterations

        let destination = CapturingDestination(expectation: expectation)
        let logger = Logger(identifier: "test", destinations: [destination])

        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            logger.debug("message_\(index)")
        }

        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(destination.processedCount, iterations)
        XCTAssertFalse(destination.recordedThreadNames.contains(where: { $0.contains("LoggerQueue") }))
    }

    func test_nativeLogging_levelChanges_preserveSeverityAndCaptureThreshold()
        async {
        let originalLevel = LogConfig.level
        let originalMode = Logger.WebRTC.mode
        let originalDestinations = LogConfig.destinations
        defer {
            LogConfig.level = originalLevel
            Logger.WebRTC.mode = originalMode
            LogConfig.destinations = originalDestinations
        }

        LogConfig.level = .debug
        Logger.WebRTC.mode = .all
        let cases: [(LogLevel, [LogLevel])] = [
            (.debug, [.debug, .info, .warning, .error]),
            (.info, [.info, .warning, .error]),
            (.warning, [.warning, .error]),
            (.error, [.error]),
            (.debug, [.debug, .info, .warning, .error])
        ]
        for (level, expectedLevels) in cases {
            LogConfig.level = level
            let destination = CapturingDestination()
            // Keep destination filtering below the native threshold.
            LogConfig.destinations = [destination]
            await assertNativeLogs(destination, expectedLevels: expectedLevels)
        }
    }

    func test_nativeLogging_validFilesOnly_retainsWarningsAndErrors()
        async {
        let originalLevel = LogConfig.level
        let originalMode = Logger.WebRTC.mode
        let originalDestinations = LogConfig.destinations
        defer {
            LogConfig.level = originalLevel
            Logger.WebRTC.mode = originalMode
            LogConfig.destinations = originalDestinations
        }

        LogConfig.level = .debug
        Logger.WebRTC.mode = .validFilesOnly
        let destination = CapturingDestination()
        LogConfig.destinations = [destination]
        await assertNativeLogs(
            destination,
            expectedLevels: [.warning, .error],
            filename: "unselected_file.mm"
        )
        await assertNativeLogs(
            destination,
            expectedLevels: [.debug, .info, .warning, .error],
            filename: "audio_engine_device.mm"
        )

        Logger.WebRTC.mode = .none
        await assertNativeLogs(destination, expectedLevels: [])
        Logger.WebRTC.mode = .all
        await assertNativeLogs(
            destination,
            expectedLevels: [.debug, .info, .warning, .error]
        )
    }

    private func assertNativeLogs(
        _ destination: CapturingDestination,
        expectedLevels: [LogLevel],
        filename: String = "unselected_file.mm",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(2)
        var observedLevels: [LogLevel] = []
        repeat {
            let probe = UUID().uuidString
            let marker = "end-\(probe)"
            for severity: RTCLoggingSeverity in [
                .verbose, .info, .warning, .error
            ] {
                RTCLogEx(severity, "\(filename) \(probe)")
            }
            // Native forwarding is synchronous; this marker drains delivery.
            log.error(marker, subsystems: .webRTC)
            await fulfillment(of: [destination.markerExpectation(marker)], timeout: 2)
            observedLevels = destination.recordedDetails
                .filter { $0.message.contains(probe) && $0.message != marker }
                .map(\.level)
            if observedLevels == expectedLevels {
                return
            }
            await Task.yield()
        } while Date() < deadline

        XCTAssertEqual(observedLevels, expectedLevels, file: file, line: line)
    }
}

private final class CapturingDestination: BaseLogDestination, @unchecked Sendable {
    private let expectation: XCTestExpectation?
    private var logDetails: [LogDetails] = []
    private let lock = NSLock()
    private var markers: [String: XCTestExpectation] = [:]

    init(expectation: XCTestExpectation? = nil) {
        self.expectation = expectation
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        super.init(
            identifier: UUID().uuidString,
            level: .debug,
            subsystems: .all,
            showDate: false,
            dateFormatter: formatter,
            formatters: [],
            showLevel: false,
            showIdentifier: false,
            showThreadName: true,
            showFileName: false,
            showLineNumber: false,
            showFunctionName: false
        )
    }

    @available(*, unavailable)
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
        expectation = nil
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
        fatalError(
            "init(identifier:level:subsystems:showDate:dateFormatter:formatters:showLevel:showIdentifier:showThreadName:showFileName:showLineNumber:showFunctionName:) is unavailable"
        )
    }

    override func process(logDetails: LogDetails) {
        lock.lock()
        self.logDetails.append(logDetails)
        let marker = markers.removeValue(forKey: logDetails.message)
        lock.unlock()

        expectation?.fulfill()
        marker?.fulfill()
    }

    override func write(message: String) {
        // Intentionally blank. Tests should not print to stdout.
    }

    var processedCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return logDetails.count
    }

    var recordedThreadNames: [String] {
        lock.lock()
        defer { lock.unlock() }
        return logDetails.map(\.threadName)
    }

    var recordedDetails: [LogDetails] {
        lock.lock()
        defer { lock.unlock() }
        return logDetails
    }

    func markerExpectation(_ message: String) -> XCTestExpectation {
        let expectation = XCTestExpectation(description: message)
        lock.lock()
        let alreadyProcessed = logDetails.contains { $0.message == message }
        if !alreadyProcessed {
            markers[message] = expectation
        }
        lock.unlock()
        if alreadyProcessed {
            expectation.fulfill()
        }
        return expectation
    }
}
