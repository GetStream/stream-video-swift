//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

final class CallFlow_PerformanceTests: StreamTestCase {

    private let callDuration: TimeInterval = 1 * 60
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        launchApp = false
        try super.setUpWithError()
    }

    @MainActor
    func test_performance_with4Participants() throws {
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://linear.app/stream/issue/IOS-1220/automate-call-performance-testing")
        // Reduce noise: fewer iterations for deterministic flows
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        options.invocationOptions = [.manuallyStart, .manuallyStop]

        measure(
            metrics: [
                XCTMemoryMetric(application: app)
            ],
            options: options
        ) {
            app.launch()
            app.activate()

            startMeasuring()
            WHEN("user starts a new call") {
                userRobot
                    .waitForAutoLogin()
                    .startCall(callId, waitForCompletion: false)
            }

            // ensure AUT is foreground
            app.activate()
            idle(for: callDuration)

            stopMeasuring()
            app.terminate()
        }
    }
}

extension XCTestCase {
    /// Non-blocking idle that won't freeze the app under test.
    func idle(for seconds: TimeInterval, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Idle \(seconds)s")
        // Intentionally never fulfill. We expect a timeout.
        let result = XCTWaiter.wait(for: [exp], timeout: seconds)
        XCTAssertEqual(result, .timedOut, "Idle wait was interrupted", file: file, line: line)
    }
}
