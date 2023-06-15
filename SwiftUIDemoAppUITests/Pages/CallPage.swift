//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

enum CallPage {
    
    static var cameraToggle: XCUIElement { app.buttons["cameraToggle"] }
    static var microphoneToggle: XCUIElement { app.buttons["microphoneToggle"] }
    static var cameraPositionToggle: XCUIElement { app.buttons["cameraPositionToggle"] }
    static var hangUpButton: XCUIElement { app.buttons["hangUp"] }
    
    static var minimizeCallViewButton: XCUIElement { app.buttons["minimizeCallViewButton"] }
    static var recordingLabel: XCUIElement { app.staticTexts["recordingLabel"] }
    static var participantMenu: XCUIElement { app.buttons["participantMenu"] }
    static var cornerDragableView: XCUIElement { app.otherElements["cornerDragableView"].otherElements.firstMatch }
    static var minimizedCallView: XCUIElement { participantView.firstMatch }
    static var viewMenu: XCUIElement { app.buttons["viewMenu"] }
    static var connectionQualityIndicator: XCUIElement { app.otherElements["connectionQualityIndicator"] }
    
    enum ViewMenu {
        static var fullscreen: XCUIElement {
            app.collectionViews.buttons.matching(NSPredicate(format: "label LIKE 'Full Screen'")).firstMatch
        }
        
        static var spotlight: XCUIElement {
            app.collectionViews.buttons.matching(NSPredicate(format: "label LIKE 'Spotlight'")).firstMatch
        }
    
        static var grid: XCUIElement {
            app.collectionViews.buttons.matching(NSPredicate(format: "label LIKE 'Grid'")).firstMatch
        }
    }
    
    enum ParticipantMenu {
        static var participantCount: XCUIElement { app.scrollViews["participantsScrollView"] }
        static var closeButton: XCUIElement { app.buttons["closeButton"] }
    }
    
    enum ConnectingView {
        static var callConnectingView: XCUIElement { app.staticTexts["callConnectingView"] }
        static var callingIndicator: XCUIElement { app.otherElements["callingIndicator"] }
        static var callConnectingParticipantView: XCUIElement { app.otherElements["callConnectingParticipantView"] }
        static var callConnectingGroupView: XCUIElementQuery { app.otherElements["callConnectingGroupView"].images }
    }
    
    static var participantEvent: XCUIElement { app.staticTexts["participantEventLabel"] }
    
    static var participantName: XCUIElementQuery {
        app.staticTexts.matching(NSPredicate(format: "identifier LIKE 'participantName'"))
    }
    
    static var participantMicIcon: XCUIElementQuery {
        app.images.matching(NSPredicate(format: "identifier LIKE 'participantMic'"))
    }
    
    static var participantView: XCUIElementQuery {
        app.otherElements.matching(NSPredicate(format: "identifier LIKE 'callParticipantView'"))
    }
    
    static var spotlightParticipantView: XCUIElementQuery {
        app.otherElements.matching(NSPredicate(format: "identifier LIKE 'spotlightParticipantView' AND value != nil"))
    }
    
    static var screenSharingLabel: XCUIElement { app.staticTexts["participantPresentingLabel"] }
    static var screenSharingView: XCUIElement { app.otherElements["screenSharingView"] }
    static var screenSharingParticipantView: XCUIElementQuery {
        app.otherElements.matching(NSPredicate(format: "identifier LIKE 'screenSharingParticipantView' AND value != nil"))
    }
    static var screenSharingParticipantList: XCUIElement { app.scrollViews["screenSharingParticipantList"] }
    static var screenSharingParticipantListDetails: XCUIElement {
        screenSharingParticipantList.otherElements.matching(NSPredicate(format: "label CONTAINS 'Horizontal scroll bar'")).firstMatch
    }
    static var gridViewParticipantList: XCUIElement { app.scrollViews["gridScrollView"] }
    static var gridViewParticipantListDetails: XCUIElement {
        gridViewParticipantList.otherElements.matching(NSPredicate(format: "label CONTAINS 'Vertical scroll bar'")).firstMatch
    }
    static var spotlightViewParticipantList: XCUIElement { app.scrollViews["spotlightScrollView"] }
    static var spotlightViewParticipantListDetails: XCUIElement {
        spotlightViewParticipantList.otherElements.matching(NSPredicate(format: "label CONTAINS 'Horizontal scroll bar'")).firstMatch
    }
    static var reconnectingMessage: XCUIElement { app.staticTexts["reconnectingMessage"] }
}
