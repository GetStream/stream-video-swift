//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

struct Safari {

    private let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")

    init() {}

    private func go(to url: URL) -> Self {
        safari.textFields["Address"].tap()
        safari.typeText(url.absoluteString)
        let goButton = safari.buttons["Go"]
        if goButton.waitForExistence(timeout: 5) {
            safari.tapKeyboardKey("Go")
        }

        return self
    }

    @discardableResult
    func open(_ url: URL) -> Self {
        safari.launch()
        _ = safari.wait(for: .runningForeground, timeout: 5)
        if #available(iOS 16.4, *) {
            safari.open(url)
            return self
        } else {
            // Type the deeplink and execute it
            let firstLaunchContinueButton = safari.buttons["Continue"]
            if firstLaunchContinueButton.exists {
                firstLaunchContinueButton.tap()
            }

            return go(to: url)
        }
    }
    
    @discardableResult
    func alertHandler() -> Self {
        safari.buttons["ReloadButton"].wait()
        if safari.alerts.count > 0 {
            while safari.alerts.count > 0 {
                safari.alerts.buttons["Allow"].safeTap()
            }
        }
        return self
    }

    @discardableResult
    func tapOnOpenButton(_ timeout: TimeInterval = 5) -> Self {
        safari
            .buttons
            .matching(NSPredicate(format: "label LIKE 'OPEN' OR label LIKE 'Open'"))
            .firstMatch
            .wait(timeout: timeout)
            .tap()

        return self
    }
}
