//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

enum CallPage {
    
    static var cameraToggle: XCUIElement { app.buttons["cameraToggle"] }
    static var microphoneToggle: XCUIElement { app.buttons["microphoneToggle"] }
    static var cameraPositionToggle: XCUIElement { app.buttons["cameraPositionToggle"] }
    static var hangUpButton: XCUIElement { app.buttons["hangUp"] }
    
    static var participantEvent: XCUIElement { app.staticTexts["participantEventLabel"] }
    static var minimizeCallViewButton: XCUIElement { app.buttons["minimizeCallView"] }
    static var participantMenu: XCUIElement { app.buttons["participantMenu"] }
    
    
    static var participantName: XCUIElementQuery {
        app.staticTexts.matching(NSPredicate(format: "identifier LIKE 'participantName'"))
    }
    
    static var participantMicEnabledImage: XCUIElementQuery {
        app.images.matching(NSPredicate(format: "identifier LIKE 'participantMicIsOn'"))
    }
    
    static var participantMicDisabledImage: XCUIElementQuery {
        app.images.matching(NSPredicate(format: "identifier LIKE 'participantMicIsOff'"))
    }
    
    static var participantVideoView: XCUIElementQuery {
        app.otherElements.matching(NSPredicate(format: "identifier LIKE 'CallParticipantVideoView'")).otherElements
    }
    
    static var participantImageView: XCUIElementQuery {
        app.otherElements.matching(NSPredicate(format: "identifier LIKE 'CallParticipantImageView'")).otherElements
    }
    
    static var screenSharingLabel: XCUIElement { app.staticTexts["participantPresentingLabel"] }
    static var screenSharingView: XCUIElement { app.otherElements["screenSharingView"] }
    static var screenSharingParticipantView: XCUIElementQuery {
        app.otherElements.matching(NSPredicate(format: "identifier LIKE 'screenSharingParticipantView'"))
    }
    
}
