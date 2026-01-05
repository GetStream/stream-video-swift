//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

struct Safari {

    private let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")

    init() {}

    @discardableResult
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
        } else {
            let firstLaunchContinueButton = safari.buttons["Continue"]
            if firstLaunchContinueButton.exists {
                firstLaunchContinueButton.tap()
            }
            // Type the deeplink and execute it
            go(to: url)
        }
        
        return self
    }
    
    // swiftformat:disable isEmpty
    @discardableResult
    func alertHandler() -> Self {
        safari.buttons["ReloadButton"].wait()
        if safari.alerts.count > 0 {
            while safari.alerts.count > 0 {
                safari.alerts.buttons["Allow"].safeTap()
                sleep(UInt32(0.5))
            }
        }
        return self
    }

    // swiftformat:enable isEmpty
    
    @discardableResult
    func tapOnDeeplinkButton(_ timeout: Double = 5) -> Self {
        safari.buttons["Open deeplink"].wait(timeout: timeout).tap()
        return self
    }

    @discardableResult
    func tapOnOpenButton(_ timeout: Double = 5) -> Self {
//        safari.buttons.matching(NSPredicate(format: "label LIKE 'Open'")).firstMatch.wait(timeout: timeout).safeTap()
        
        safari.buttons["Open"].wait(timeout: timeout).tap()
        return self
    }
}
