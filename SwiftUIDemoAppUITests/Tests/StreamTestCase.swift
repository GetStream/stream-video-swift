//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

let app = XCUIApplication()
var userRobot = UserRobot()

class StreamTestCase: XCTestCase {

    let deviceRobot = DeviceRobot(app)
    var participantRobot = ParticipantRobot()
    var sinatra = Sinatra()
    var recordVideo = false
    var launchApp = true
    let callId = randomCallId
    let allViews: [UserRobot.View] = [.grid, .fullscreen, .spotlight]

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        alertHandler()
        ipadSetup()
        startVideo()
        if launchApp {
            app.launch()
        }
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

    static var randomCallId: String {
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

    private func ipadSetup() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            app.landscape()
        }
    }

    private func startVideo() {
        if recordVideo {
            sinatra.recordVideo(name: testName)
        }
    }

    private func stopVideo() {
        if recordVideo {
            sinatra.recordVideo(name: testName, delete: !isTestFailed(), stop: true)
        }
    }

    func openURL(_ url: URL) {
        sinatra.openURL(url)
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
