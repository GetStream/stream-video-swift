//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

final class ParticipantActionsTests: StreamTestCase {
    
    func testParticipantEnablesMicrophone() throws {
        linkToScenario(withId: 1536)
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")

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
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")

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
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")

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
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")

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
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")

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
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")
                
        GIVEN("user starts a call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
        }
        AND("participant joins the call and starts recording the call for 10 seconds") {
            participantRobot
                .setCallRecordingDuration(15)
                .joinCall(callId, actions: [.recordCall])
        }

        WHEN("participants join the call and one of them starts recording") {
            userRobot.waitForParticipantsToJoin()
        }

        for view in allViews {
            THEN("user turns on \(view.rawValue) view and observes the recording icon appeared") {
                userRobot
                    .setView(mode: view)
                    .assertRecordingIcon(isVisible: true)
                    .assertCallDurationView(isVisible: false)
            }
        }

        WHEN("participant stops recording") {}

        for view in allViews {
            THEN("user turns on \(view.rawValue) view and observes the recording icon disappeared") {
                userRobot
                    .setView(mode: view)
                    .assertRecordingIcon(isVisible: false)
                    .assertCallDurationView(isVisible: true)
            }
        }
    }
    
    func testParticipantSharesScreen() throws {
        linkToScenario(withId: 1773)
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")
        
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
