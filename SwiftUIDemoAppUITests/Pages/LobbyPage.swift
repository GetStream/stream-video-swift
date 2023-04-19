//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

enum LobbyPage {
    
    static var cameraToggle: XCUIElement { app.buttons["cameraToggle"] }
    static var microphoneToggle: XCUIElement { app.buttons["microphoneToggle"] }
    static var closeButton: XCUIElement { app.buttons["Close"] }
    static var joinCallButton: XCUIElement { app.buttons["joinCall"] }
    static var otherParticipantsCount: XCUIElement { app.staticTexts["otherParticipantsCount"] }
    static var cameraCheckView: XCUIElement { app.otherElements["cameraCheckView"] }
    static var microphoneCheckView: XCUIElement { app.staticTexts["microphoneCheckView"] }
    static var connectionQualityIndicator: XCUIElement { app.otherElements["connectionQualityIndicator"] }
}
