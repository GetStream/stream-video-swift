//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest

final class ParticipantActionsTests: StreamTestCase {
    
    func testParticipantEnablesMicrophone() throws {
        linkToScenario(withId: 1536)
        
        // try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")

        GIVEN("user starts a call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
                .microphone(.disable)
        }
        AND("participant joins the call and turns on mic") {
            participantRobot.joinCall(callId, options: [.withMicrophone])
            userRobot.waitForParticipantsToJoin()
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

    func testParticipantDisablesMicrophone() throws {
        linkToScenario(withId: 1537)
        
        // try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")

        GIVEN("user starts a call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
                .microphone(.disable)
        }
        AND("participant joins the call and turns off mic") {
            participantRobot.joinCall(callId, options: [.withCamera])
            userRobot.waitForParticipantsToJoin()
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

    func testParticipantEnablesCamera() throws {
        linkToScenario(withId: 1538)
        
        // try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")

        GIVEN("user starts a call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
                .microphone(.disable)
                .camera(.enable)
        }
        AND("participant joins the call and turns camera on") {
            participantRobot.joinCall(callId, options: [.withCamera, .withMicrophone])
            userRobot.waitForParticipantsToJoin()
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

    func testParticipantDisablesCamera() throws {
        linkToScenario(withId: 1539)
        
        // try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")

        GIVEN("user starts a call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
                .microphone(.disable)
                .camera(.disable)
        }
        AND("participant joins the call and turns camera off") {
            participantRobot.joinCall(callId, options: [.withMicrophone])
            userRobot.waitForParticipantsToJoin()
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
    
    func testParticipantConnectionQualityIndicator() throws {
        linkToScenario(withId: 1540)
        
        // try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")

        GIVEN("user starts a call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
                .microphone(.disable)
        }
        AND("participant joins the call") {
            participantRobot.joinCall(callId, options: [.withCamera])
            userRobot.waitForParticipantsToJoin()
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
        
        // try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")
                
        GIVEN("user starts a call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
        }
        AND("participant joins the call and starts recording the call for 10 seconds") {
            participantRobot
                .setCallRecordingDuration(10)
                .joinCall(callId, actions: [.recordCall])
        }

        THEN("wait participants to join") {
            userRobot.waitForParticipantsToJoin()
        }

        WHEN("user observes that participant started recording the screen") {
            userRobot.assertParticipantStartRecordingCall()
        }

        for view in allViews {
            THEN("user turns on \(view.rawValue) view and recordingView is visible.") {
                userRobot.setView(mode: view)
                XCTAssertTrue(CallPage.recordingView.exists)
            }
        }

        WHEN("user observes that participant stopped recording the screen") {
            userRobot.assertParticipantStopRecordingCall()
        }

        for view in allViews {
            AND("user turns on \(view.rawValue) view and recordingView isn't visible.") {
                userRobot.setView(mode: view)
                XCTAssertTrue(CallPage.callDurationView.exists)
            }
        }
    }
    
    func testParticipantSharesScreen() throws {
        linkToScenario(withId: 1773)
        
        // try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")
        
        let participants = 1

        GIVEN("user starts a call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
        }
        WHEN("participant joins the call and shares the screen for 3 seconds") {
            participantRobot
                .setScreenSharingDuration(10)
                .joinCall(callId, actions: [.shareScreen])
            userRobot.waitForParticipantsToJoin(participants)
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
