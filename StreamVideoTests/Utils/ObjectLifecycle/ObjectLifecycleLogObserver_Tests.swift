//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class ObjectLifecycleLogObserver_Tests: XCTestCase, @unchecked Sendable {

    private var previousLogger: Logger!
    private var destination: CapturingDestination!
    private var subject: ObjectLifecycle.LogObserver!

    override func setUp() {
        super.setUp()

        previousLogger = LogConfig.logger
        destination = .init()
        LogConfig.logger = Logger(identifier: "test", destinations: [destination])

        subject = .init(subsystem: .other)
    }

    override func tearDown() {
        subject = nil

        LogConfig.logger = previousLogger
        previousLogger = nil
        destination = nil

        super.tearDown()
    }

    func test_record_whenCalled_writesLifecycleMessage() {
        let expectation = expectation(description: "Log event")
        destination.expectation = expectation

        subject.record(
            .init(
                transition: .initialized,
                typeName: "TypeA",
                instanceId: "id-1",
                timestamp: .distantPast,
                metadata: ["b": "2", "a": "1"]
            )
        )

        wait(for: [expectation], timeout: 2)

        let message = destination.messages.last
        XCTAssertTrue(message?.contains("[Lifecycle] TypeA initialized") == true)
        XCTAssertTrue(message?.contains("id:id-1") == true)
        XCTAssertTrue(message?.contains("metadata:a=1,b=2") == true)
    }
}

private final class CapturingDestination: BaseLogDestination, @unchecked Sendable {
    private let lock = NSLock()
    private(set) var messages: [String] = []
    var expectation: XCTestExpectation?

    init() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        super.init(
            identifier: "capture",
            level: .debug,
            subsystems: .all,
            showDate: false,
            dateFormatter: formatter,
            formatters: [],
            showLevel: false,
            showIdentifier: false,
            showThreadName: false,
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
        fatalError(
            "init(identifier:level:subsystems:showDate:dateFormatter:"
                + "formatters:showLevel:showIdentifier:showThreadName:"
                + "showFileName:showLineNumber:showFunctionName:) "
                + "is unavailable"
        )
    }

    override func write(message: String) {
        lock.lock()
        messages.append(message)
        let expectation = self.expectation
        lock.unlock()

        expectation?.fulfill()
    }
}
