//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

struct Safari {

    private let application = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")

    init() {}

    private func go(to url: URL) -> Self {
        application.textFields["Address"].tap()
        application.typeText(url.absoluteString)
        let goButton = application.buttons["Go"]
        if goButton.waitForExistence(timeout: 5) {
            application.tapKeyboardKey("Go")
        }

        return self
    }

    @discardableResult
    func open(_ url: URL) -> Self {
        application.launch()

        _ = application.wait(for: .runningForeground, timeout: 5)

        // Type the deeplink and execute it
        let firstLaunchContinueButton = application.buttons["Continue"]
        if firstLaunchContinueButton.exists {
            firstLaunchContinueButton.tap()
        }

        return go(to: url)
    }

    @discardableResult
    func tapButton(_ label: String, _ timeout: TimeInterval = 5) -> Self {
        application
            .buttons[label]
            .wait(timeout: timeout)
            .tap()

        return self
    }
}
