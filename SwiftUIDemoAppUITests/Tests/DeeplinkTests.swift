//
//  DeeplinkTests.swift
//  SwiftUIDemoAppUITests
//
//  Created by Ilias Pavlidakis on 25/9/23.
//

import XCTest

final class DeeplinkTests: StreamTestCase {

    static override func setUp() {
        super.setUp()

        // We are launching and terminating the app to ensure the executable
        // has been installed.
        app.launch()
        app.terminate()
    }

    override func setUpWithError() throws {
        launchApp = false
        try super.setUpWithError()
    }

    private enum MockDeeplink {
        static let production: URL = .init(string: "https://getstream.io/video/demos?id=test-call")!
        static let customScheme: URL = .init(string: "streamvideo://video/demos?id=test-call")!
    }

    func test_universalLink_production_joinsExpectedCall() {
        WHEN("") {
            Safari.openUniversalLinkFromSmartBanner(MockDeeplink.production)
        }
        THEN("user joins the the specified call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: 1)
        }
    }

    func test_customSchemeURL_joinsExpectedCall() {
        GIVEN("") {
            app.terminate()
        }
        WHEN("User opens a URL that contains a custom scheme") {
            Safari.openApp(MockDeeplink.customScheme)
        }
        THEN("user joins the the specified call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: 1)
        }
    }
}

extension XCUIDevice {

    fileprivate func open(_ url: URL) {
        DispatchQueue.main.async {
            // Need to async this because XCUIDevice.shared.system.open
            // synchronously waits for a button to be pressed the first time.
            self.system.open(url)
        }
    }
}

enum Safari {

    private static let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")

    fileprivate static func go(to url: URL) {
        safari.textFields["Address"].tap()
        safari.typeText(url.absoluteString)
        let goButton = safari.buttons["Go"]
        if goButton.waitForExistence(timeout: 5) {
            safari.tapKeyboardKey("Go")
        }
    }

    fileprivate static func open(_ url: URL) {
        safari.launch()

        _ = safari.wait(for: .runningForeground, timeout: 5)

        // Type the deeplink and execute it
        let firstLaunchContinueButton = safari.buttons["Continue"]
        if firstLaunchContinueButton.exists {
            firstLaunchContinueButton.tap()
        }

        go(to: url)
    }

    fileprivate static func openApp(_ url: URL) {
        open(url)

        let openButton = safari.buttons["Open"]
        if openButton.waitForExistence(timeout: 5) {
            openButton.tap()
        }
    }

    fileprivate static func openUniversalLinkFromSmartBanner(_ url: URL) {
        open(url)

        let allowButton1 = safari.alerts.buttons["Allow"]
        if allowButton1.waitForExistence(timeout: 5) {
            allowButton1.tap()
            let allowButton2 = safari.alerts.buttons["Allow"]
            if allowButton2.waitForExistence(timeout: 5) {
                allowButton2.tap()
            }
        }

        let openButton = safari.buttons["OPEN"]
        if openButton.waitForExistence(timeout: 5) {
            openButton.tap()
        }
    }
}

extension XCUIApplication {
    /// Taps the specified keyboard key while handling the
    /// keyboard onboarding interruption, if it exists.
    /// - Parameter key: The keyboard key to tap.
    fileprivate func tapKeyboardKey(_ key: String) {
        let key = self.keyboards.buttons[key]

        if key.isHittable == false {
            // Attempt to find and tap the Continue button
            // of the keyboard onboarding screen.
            self.buttons["Continue"].tap()
        }

        key.tap()
    }
}
