//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

final class ParticipantActionsTests: StreamTestCase {
    
    func testParticipantEnablesMicrophone() {
        linkToScenario(withId: 1536)

        GIVEN("user starts a call") {
            userRobot
                .login()
                .startCall(callId)
                .microphone(.disable)
        }
        AND("participant joins the call and turns on mic") {
            participantRobot.joinCall(callId, options: [.withMicrophone])
        }
        for view in allViews {
            WHEN("user turns on \(view.rawValue) view") {
                userRobot.setView(mode: view)
            }
            THEN("user observes that participant's microphone is enabled") {
                userRobot.assertParticipantMicrophoneIsEnabled()
            }
        }
    }

    func testParticipantDisablesMicrophone() {
        linkToScenario(withId: 1537)

        GIVEN("user starts a call") {
            userRobot
                .login()
                .startCall(callId)
                .microphone(.disable)
        }
        AND("participant joins the call and turns off mic") {
            participantRobot.joinCall(callId, options: [.withCamera])
        }
        for view in allViews {
            WHEN("user turns on \(view.rawValue) view") {
                userRobot.setView(mode: view)
            }
            THEN("user observes that participant's microphone is disabled") {
                userRobot.assertParticipantMicrophoneIsDisabled()
            }
        }
    }

    func testParticipantEnablesCamera() {
        linkToScenario(withId: 1538)

        GIVEN("user starts a call") {
            userRobot
                .login()
                .startCall(callId)
                .microphone(.disable)
        }
        AND("participant joins the call and turns camera on") {
            participantRobot.joinCall(callId, options: [.withCamera, .withMicrophone])
        }
        for view in allViews {
            WHEN("user turns on \(view.rawValue) view") {
                userRobot.setView(mode: view)
            }
            THEN("user observes that participant's camera is enabled") {
                userRobot.assertParticipantCameraIsEnabled()
            }
        }
    }

    func testParticipantDisablesCamera() {
        linkToScenario(withId: 1539)

        GIVEN("user starts a call") {
            userRobot
                .login()
                .startCall(callId)
                .microphone(.disable)
        }
        AND("participant joins the call and turns camera off") {
            participantRobot.joinCall(callId, options: [.withMicrophone])
        }
        for view in allViews {
            WHEN("user turns on \(view.rawValue) view") {
                userRobot.setView(mode: view)
            }
            THEN("user observes that participant's camera is disabled") {
                userRobot.assertParticipantCameraIsDisabled()
            }
        }
    }
    
    func testParticipantConnectionQualityIndicator() {
        linkToScenario(withId: 1540)

        GIVEN("user starts a call") {
            userRobot
                .login()
                .startCall(callId)
                .microphone(.disable)
        }
        AND("participant joins the call") {
            participantRobot.joinCall(callId, options: [.withCamera])
        }
        for view in allViews {
            WHEN("user turns on \(view.rawValue) view") {
                userRobot.setView(mode: view)
            }
            THEN("user observers participant's connection indicator icon") {
                userRobot.assertConnectionQualityIndicator()
            }
        }
    }
    
    func testParticipantRecordsCall() throws {
        linkToScenario(withId: 1769)
        
        throw XCTSkip("Recording the call is broken on the backend")
                
        GIVEN("user starts a call") {
            userRobot.login().startCall(callId)
        }
        AND("participant joins the call and starts recording the call for 3 seconds") {
            participantRobot
                .setCallRecordingDuration(35)
                .joinCall(callId, actions: [.recordCall])
        }
        for view in allViews {
            WHEN("user turns on \(view.rawValue) view") {
                userRobot.setView(mode: view)
            }
            THEN("user observes that participant started recording the screen") {
                userRobot.assertParticipantStartRecordingCall()
            }
        }
        for view in allViews {
            WHEN("user turns on \(view.rawValue) view") {
                userRobot
                    .waitForAppearanceOfParticipantEventLabel()
                    .waitForDisappearanceOfParticipantEventLabel()
                    .setView(mode: view)
            }
            THEN("user observes that participant stopped recording the screen") {
                userRobot.assertParticipantStopRecordingCall()
            }
        }
    }
    
    func testParticipantSharesScreen() {
        linkToScenario(withId: 1773)
        
        let participants = 1

        GIVEN("user starts a call") {
            userRobot.login().startCall(callId)
        }
        WHEN("participant joins the call and shares the screen for 3 seconds") {
            participantRobot
                .setScreenSharingDuration(10)
                .joinCall(callId, actions: [.shareScreen])
        }
        THEN("user observers participant's screen") {
            userRobot
                .assertParticipantStartSharingScreen()
                .assertUserCountWhenScreenSharing(participants + 1)
        }
        AND("participant stops sharing screen") {
            userRobot.assertParticipantStopSharingScreen()
        }
    }
}
