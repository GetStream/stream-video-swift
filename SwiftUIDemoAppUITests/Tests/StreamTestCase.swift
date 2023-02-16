//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

let app = XCUIApplication()

class StreamTestCase: XCTestCase {
    
    let deviceRobot = DeviceRobot(app)
    var userRobot = UserRobot()
    var participantRobot = ParticipantRobot()
    var terminalRobot = TerminalRobot()
    var recordVideo = false

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        alertHandler()
        startVideo()
        app.launch()
    }

    override func tearDownWithError() throws {
        attachElementTree()
        stopVideo()
        app.terminate()

        try super.tearDownWithError()
        app.launchArguments.removeAll()
        app.launchEnvironment.removeAll()
    }
}

extension StreamTestCase {
    
    func randomCallId() -> String {
        let uuid = UUID().uuidString.split(separator: "-")
        if let first = uuid.first { return String(first) } else { return "Test" }
    }
}

extension StreamTestCase {

    private func attachElementTree() {
        let attachment = XCTAttachment(string: app.debugDescription)
        attachment.lifetime = .deleteOnSuccess
        add(attachment)
    }

    private func alertHandler() {
        let title = "Push Notification Alert"
        _ = addUIInterruptionMonitor(withDescription: title) { (alert: XCUIElement) -> Bool in
            let allowButton = alert.buttons["Allow"]
            if allowButton.exists {
                allowButton.tap()
                return true
            }
            return false
        }
    }

    private func startVideo() {
        if recordVideo {
            terminalRobot.recordVideo(name: testName)
        }
    }

    private func stopVideo() {
        if recordVideo {
            terminalRobot.recordVideo(name: testName, delete: !isTestFailed(), stop: true)
        }
    }

    private func isTestFailed() -> Bool {
        if let testRun = testRun {
            let failureCount = testRun.failureCount + testRun.unexpectedExceptionCount
            return failureCount > 0
        }
        return false
    }

    private var testName: String {
        String(name.split(separator: " ")[1].dropLast())
    }
}
