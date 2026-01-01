//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

enum CallPage {
    
    static var cameraToggle: XCUIElement { app.buttons["cameraToggle"] }
    static var microphoneToggle: XCUIElement { app.buttons["microphoneToggle"] }
    static var cameraPositionToggle: XCUIElement { app.buttons["cameraPositionToggle"] }
    static var hangUpButton: XCUIElement { app.buttons["hangUp"] }
    static var participantMenu: XCUIElement { app.buttons["participantMenu"] }
    static var cornerDraggableView: XCUIElement { app.otherElements["cornerDraggableView"].otherElements.firstMatch }
    static var minimizedCallView: XCUIElement { participantView.firstMatch }
    static var viewMenu: XCUIElement { app.buttons["viewMenu"] }
    static var connectionQualityIndicator: XCUIElement { app.otherElements["connectionQualityIndicator"] }
    static var recordingView: XCUIElement { app.staticTexts["recordingView"] }
    static var callDurationView: XCUIElement { app.staticTexts["callDurationView"] }
    static var liveMeetingLabel: XCUIElement { app.staticTexts["Your Meeting is live!"] }

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
        static var closeButton: XCUIElement { app.buttons["Close"] }
    }
    
    enum ConnectingView {
        static var callConnectingView: XCUIElement { app.staticTexts["callConnectingView"] }
        static var callingIndicator: XCUIElement { app.otherElements["callingIndicator"] }
        static var callConnectingParticipantView: XCUIElement { app.staticTexts["callConnectingParticipantView"] }
        static var participantsBubblesWithImages: XCUIElementQuery {
            app.staticTexts["callConnectingGroupView"].images
        }

        static var participantsBubblesWithoutImages: XCUIElementQuery {
            app.staticTexts["callConnectingGroupView"].staticTexts
        }
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
        app.otherElements.matching(NSPredicate(format: "identifier LIKE 'horizontalParticipantsListParticipant' AND value != nil"))
    }
    
    static var screenSharingLabel: XCUIElement { app.staticTexts["participantPresentingLabel"] }
    static var screenSharingView: XCUIElement { app.otherElements["screenSharingView"] }
    static var screenSharingParticipantView: XCUIElementQuery {
        spotlightParticipantView
    }

    static var screenSharingParticipantList: XCUIElement {
        spotlightViewParticipantList
    }

    static var gridViewParticipantList: XCUIElement { app.scrollViews["gridScrollView"] }
    static var gridViewParticipantListDetails: XCUIElement {
        gridViewParticipantList.otherElements.matching(NSPredicate(format: "label CONTAINS 'Vertical scroll bar'")).firstMatch
    }

    static var spotlightViewParticipantList: XCUIElement { app.scrollViews["horizontalParticipantsList"] }
    static var reconnectingMessage: XCUIElement { app.staticTexts["reconnectingMessage"] }
}
