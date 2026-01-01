//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

enum CallDetailsPage {
    
    static var userAvatar: XCUIElement { app.buttons["userAvatar"] }
    static var startCallButton: XCUIElement { app.buttons["startCall"] }
    static var startCallTab: XCUIElement { app.buttons["Start a call"] }
    static var joinCallButton: XCUIElement { app.buttons["joinCall"] }
    static var joinCallTab: XCUIElement { app.buttons["Join a call"] }
    static var callIdInputField: XCUIElement { app.textFields["callId"] }
    static var ringEventsToggle: XCUIElement { app.buttons["Ring events"] }
    static var lobbyTab: XCUIElement { app.buttons["Lobby"] }
    static var joinImmediatelyTab: XCUIElement { app.buttons["Join immediately"] }
    static var ringEventsTab: XCUIElement { app.buttons["Ring events"] }
    static var signOutButton: XCUIElement { app.alerts.buttons["Sign out"] }
    static var participantList: XCUIElement {
        if ProcessInfo().operatingSystemVersion.majorVersion < 16 {
            return app.tables["participantList"]
        } else {
            return app.collectionViews["participantList"]
        }
    }

    static var participants: XCUIElementQuery { participantList.buttons }
    static var connectionErrorAlert: XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'failed with error'")).firstMatch
    }
}
