//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

final class CallLifecycleTests: StreamTestCase {
    
    func testUserLeavesTheCallOnConnection() throws {
        linkToScenario(withId: 1808)
                
        GIVEN("user starts a call") {
            userRobot.login().startCall(callId, waitForCompletion: false)
        }
        WHEN("user leaves the call as soon as possible") {
            userRobot.endCall()
        }
        THEN("call is ended for the user") {
            sleep(3) // there was a bug where it would appear after a second or two
            userRobot.assertThereAreNoCallControls()
        }
    }
    
    func testUserLeavesTheCallAfterConnection() {
        linkToScenario(withId: 1778)
        
        GIVEN("user starts a call") {
            userRobot.login().startCall(callId)
        }
        WHEN("participant joins the call") {
            participantRobot.joinCall(callId)
        }
        AND("user leaves the call") {
            userRobot
                .assertParticipantJoinCall()
                .endCall()
        }
        THEN("call is ended for the user") {
            userRobot
                .assertThereAreNoCallControls()
                .assertParticipantsAreVisible(count: 0)
        }
    }
    
    func testParticipantReentersTheCall() throws {
        linkToScenario(withId: 1779)
        
        throw XCTSkip("https://github.com/GetStream/ios-issues-tracking/issues/378")
        
        GIVEN("user starts a call") {
            userRobot.login().startCall(callId)
        }
        AND("participant joins the call") {
            participantRobot
                .setCallDuration(10)
                .joinCall(callId)
        }
        THEN("user observers the alert that participant joined") {
            userRobot.assertParticipantJoinCall()
        }
        AND("there is one participant on the call") {
            userRobot.assertParticipantsAreVisible(count: 1)
        }
        WHEN("participant leaves the call") {}
        THEN("user observers the alert that participant left") {
            userRobot
                .waitForDisappearanceOfParticipantEventLabel()
                .assertParticipantLeaveCall()
        }
        AND("there are no participants on the call") {
            userRobot.assertParticipantsAreVisible(count: 0)
        }
        WHEN("participant re-enters the call") {
            participantRobot.joinCall(callId)
        }
        THEN("user observers the participant") {
            userRobot
                .assertParticipantJoinCall()
                .assertParticipantsAreVisible(count: 1)
        }
    }
    
    func testUserReentersTheCall() {
        linkToScenario(withId: 1780)
        
        GIVEN("user starts a call") {
            userRobot.login().startCall(callId)
        }
        AND("participant joins the call") {
            participantRobot.joinCall(callId)
        }
        WHEN("user re-enters the call as the same user") {
            userRobot
                .assertParticipantJoinCall()
                .endCall()
                .tapOnStartCallButton(withDelay: true)
        }
        THEN("there is one participant on the call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: 1)
        }
    }
    
    func testUserReentersTheCallAsTheSameUserAfterLoggingOut() {
        linkToScenario(withId: 1781)
        
        GIVEN("user starts a call") {
            userRobot
                .logout()
                .login(userIndex: 0, waitForLoginPage: true)
                .startCall(callId)
        }
        AND("participant joins the call") {
            participantRobot.joinCall(callId)
        }
        WHEN("user re-enters the call as the same user") {
            userRobot
                .assertParticipantJoinCall()
                .endCall()
                .logout()
                .login(userIndex: 0, waitForLoginPage: true)
                .startCall(callId, clearTextField: true)
        }
        THEN("there is one participant on the call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: 1)
        }
    }
    
    func testUserReentersTheCallAsAnotherUser() {
        linkToScenario(withId: 1782)
        
        GIVEN("user starts a call") {
            userRobot
                .logout()
                .login(userIndex: 0, waitForLoginPage: true)
                .startCall(callId)
        }
        AND("participant joins the call") {
            participantRobot.joinCall(callId)
        }
        WHEN("user re-enters the call as another user") {
            userRobot
                .waitForParticipantsToJoin(1)
                .endCall()
                .logout()
                .login(userIndex: 1, waitForLoginPage: true)
                .startCall(callId, clearTextField: true)
        }
        THEN("there is one participant on the call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: 1)
        }
    }
    
    func testUserJoinsExistedCall() {
        linkToScenario(withId: 1783)
        
        GIVEN("participant starts a call") {
            participantRobot.joinCall(callId)
        }
        AND("user joins the call") {
            sleep(15) // to be sure that participant has joined
            userRobot.login().joinCall(callId)
        }
        THEN("there is one participant on the call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: 1)
        }
    }
    
    func testUserSwichesCalls() {
        linkToScenario(withId: 1784)
        
        let anotherCallId = StreamTestCase.randomCallId
        let participantCountOnFirstCall = 1
        let participantCountOnSecondCall = 2

        GIVEN("there is a call with \(participantCountOnSecondCall) participants") {
            participantRobot.setUserCount(participantCountOnSecondCall).joinCall(anotherCallId)
        }
        AND("user starts a new call") {
            userRobot.login().startCall(callId)
        }
        AND("participant joins the call with the user") {
            participantRobot.setUserCount(participantCountOnFirstCall).joinCall(callId)
        }
        WHEN("user leaves the call") {
            userRobot
                .assertParticipantJoinCall()
                .endCall()
        }
        AND("user joins another call") {
            userRobot.joinCall(anotherCallId, clearTextField: true)
        }
        THEN("there are \(participantCountOnSecondCall) participants on the call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: participantCountOnSecondCall)
        }
    }
}
