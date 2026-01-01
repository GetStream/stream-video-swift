//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class LoggerConcurrency_Tests: XCTestCase, @unchecked Sendable {

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
}

private final class CapturingDestination: BaseLogDestination, @unchecked Sendable {
    private let expectation: XCTestExpectation
    private var logDetails: [LogDetails] = []
    private let lock = NSLock()

    init(expectation: XCTestExpectation) {
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
        expectation = XCTestExpectation(description: "Unsupported initializer")
        expectation.isInverted = true
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
        lock.unlock()

        expectation.fulfill()
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
}
