//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

final class VideoTests: StreamTestCase {
    
    func testParticipantJoinCallLabel() {
        linkToScenario(withId: 1536)
        
        GIVEN("user starts a call") {
            userRobot.login().startCall(callId)
        }
        WHEN("participant joins the call") {
            participantRobot.joinCall(callId)
        }
        THEN("user observers the alert that participant joined") {
            userRobot.assertParticipantJoinCall()
        }
        
    }
    
    func testParticipantLeaveCallLabel() {
        linkToScenario(withId: 1537)

        GIVEN("user starts a call") {
            userRobot.login().startCall(callId)
        }
        WHEN("participant leaves the call") {
            participantRobot
                .setCallDuration(0.1)
                .joinCall(callId)
        }
        THEN("user observers the alert that participant left") {
            userRobot.assertParticipantLeaveCall()
        }
    }

    func testParticipantDisableMicrophone() {
        linkToScenario(withId: 1538)

        GIVEN("user starts a call") {
            userRobot.login().startCall(callId)
        }
        WHEN("participant joins the call and turns off mic") {
            participantRobot.joinCall(callId)
        }
        THEN("user observers muted microphone icon") {
            userRobot.assertParticipantIsMuted()
        }
    }

    func testParticipantEnableMicrophone() {
        linkToScenario(withId: 1539)

        GIVEN("user starts a call") {
            userRobot.login().startCall(callId)
        }
        WHEN("participant joins the call and turns on mic") {
            participantRobot.joinCall(callId, options: [.withMicrophone])
        }
        THEN("user observers unmuted microphone icon") {
            userRobot.assertParticipantIsNotMuted()
        }
    }

    func testParticipantEnableCamera() {
        linkToScenario(withId: 1540)

        GIVEN("user starts a call") {
            userRobot.login().startCall(callId)
        }
        WHEN("participant joins the call and turns on camera") {
            participantRobot.joinCall(callId, options: [.withCamera])
        }
        THEN("user observes participant by video") {
            userRobot.assertParticipantIsVisible()
        }
    }

    func testParticipantDisableCamera() {
        linkToScenario(withId: 1541)

        GIVEN("user starts a call") {
            userRobot.login().startCall(callId)
        }
        WHEN("participant joins the call and turns on camera") {
            participantRobot.joinCall(callId)
        }
        THEN("user observes participant's image instead of video") {
            userRobot.assertParticipantIsNotVisible()
        }
    }

    func testParticipantShareScreen() {
        linkToScenario(withId: 1542)

        GIVEN("user starts a call") {
            userRobot.login().startCall(callId)
        }
        WHEN("participant joins the call and shares the screen for 3 seconds") {
            participantRobot
                .setCallDuration(3)
                .joinCall(callId, actions: [.shareScreen])
        }
        THEN("user observers participant's screen") {
            userRobot.assertParticipantStartSharingScreen()
        }
        AND("participant stops sharing screen") {
            userRobot.assertParticipantStopSharingScreen()
        }
    }
}
