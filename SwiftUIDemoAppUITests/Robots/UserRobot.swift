//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

/// Simulates user behavior
final class UserRobot: Robot {
    
    @discardableResult
    func login() -> Self {
        if !app.buttons["userAvatar"].exists {
            app.buttons.matching(NSPredicate(format: "identifier LIKE 'userName'")).firstMatch.tap()
        }
        return self
    }
    
    @discardableResult
    func start(callId: String) -> Self {
        typeText(callId)
        app.buttons["startCall"].tap()
        return self
    }
    
    @discardableResult
    func join(callId: String) -> Self {
        typeText(callId)
        app.buttons["joinCall"].tap()
        return self
    }
    
    @discardableResult
    private func typeText(_ text: String, obtainKeyboardFocus: Bool = true) -> Self {
        let inputField = app.textFields["callId"]
        if obtainKeyboardFocus {
            inputField.obtainKeyboardFocus().typeText(text)
        } else {
            inputField.typeText(text)
        }
        return self
    }
}
