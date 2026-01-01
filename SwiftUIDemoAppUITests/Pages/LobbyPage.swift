//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

enum LobbyPage {
    
    static var cameraToggle: XCUIElement { app.buttons["cameraToggle"] }
    static var microphoneToggle: XCUIElement { app.buttons["microphoneToggle"] }
    static var closeButton: XCUIElement { app.buttons["Close"] }
    static var joinCallButton: XCUIElement { app.buttons["joinCall"] }
    static var callParticipantsCount: XCUIElement { app.staticTexts["callParticipantsCount"] }
    static var microphoneCheckView: XCUIElement { app.staticTexts["microphoneCheckView"] }
    static var connectionQualityIndicator: XCUIElement { app.otherElements["connectionQualityIndicator"] }
    static var cameraCheckView: XCUIElement {
        if ProcessInfo().operatingSystemVersion.majorVersion < 16 {
            return app.scrollViews["participantsScrollView"]
        } else {
            return app.otherElements["cameraCheckView"]
        }
    }
}
