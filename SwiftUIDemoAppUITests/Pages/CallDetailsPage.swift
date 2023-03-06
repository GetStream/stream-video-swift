//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

enum CallDetailsPage {
    
    static var userAvatar: XCUIElement { app.buttons["userAvatar"] }
    static var startCallButton: XCUIElement { app.buttons["startCall"] }
    static var joinCallButton: XCUIElement { app.buttons["joinCall"] }
    static var callIdInputField: XCUIElement { app.textFields["callId"] }
    static var ringEventsToggle: XCUIElement { app.buttons["Ring events"] }
    static var lobbyToggle: XCUIElement { app.buttons["Lobby"] }
    static var joinImmediatelyToggle: XCUIElement { app.buttons["Join immediately"] }
    
}
