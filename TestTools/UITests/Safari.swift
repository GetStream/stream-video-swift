//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

enum Safari {

    private static let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")

    static func go(to url: URL) {
        safari.textFields["Address"].tap()
        safari.typeText(url.absoluteString)
        let goButton = safari.buttons["Go"]
        if goButton.waitForExistence(timeout: 5) {
            safari.tapKeyboardKey("Go")
        }
    }

    static func open(_ url: URL) {
        safari.launch()

        _ = safari.wait(for: .runningForeground, timeout: 5)

        // Type the deeplink and execute it
        let firstLaunchContinueButton = safari.buttons["Continue"]
        if firstLaunchContinueButton.exists {
            firstLaunchContinueButton.tap()
        }

        go(to: url)
    }

    static func openApp(_ url: URL) {
        open(url)

        safari
            .buttons["Open"]
            .wait(timeout: 5)
            .tap()
    }

    static func openUniversalLinkFromSmartBanner(_ url: URL) {
        open(url)

        let allowButton = safari.alerts.buttons["Allow"]
        allowButton.wait(timeout: 5).tap()
        allowButton.wait(timeout: 5).tap()

        safari
            .buttons["OPEN"]
            .wait(timeout: 5)
            .tap()
    }
}
