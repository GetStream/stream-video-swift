//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

final class CallLifecycleTests: StreamTestCase {
    
    func testUserLeavesTheCallOnConnection() throws {
        linkToScenario(withId: 1808)
                
        GIVEN("user starts a call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId, waitForCompletion: false)
        }
        WHEN("user leaves the call as soon as possible") {
            userRobot.endCall()
        }
        THEN("call is ended for the user") {
            sleep(3) // there was a bug where it would appear after a second or two
            userRobot.assertThereAreNoCallControls()
        }
    }
    
    func testUserLeavesTheCallAfterConnection() throws {
        linkToScenario(withId: 1778)
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")
        
        GIVEN("user starts a call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
        }
        WHEN("participant joins the call") {
            participantRobot.joinCall(callId)
            userRobot.waitForParticipantsToJoin(1)
        }
        AND("user leaves the call") {
            userRobot.endCall()
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
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
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
    
    func testUserReentersTheCall() throws {
        linkToScenario(withId: 1780)
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")
        
        let participants = 1
        
        GIVEN("user starts a call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
        }
        AND("participant joins the call") {
            participantRobot.joinCall(callId)
            userRobot.waitForParticipantsToJoin(participants)
        }
        WHEN("user re-enters the call as the same user") {
            userRobot
                .endCall()
                .startCall(callId)
        }
        THEN("there is one participant on the call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: participants)
        }
    }
    
    func testUserReentersTheCallAsTheSameUserAfterLoggingOut() throws {
        linkToScenario(withId: 1781)
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")
        
        let participants = 1
        
        GIVEN("user starts a call") {
            userRobot
                .waitForAutoLogin()
                .logout()
                .login(userIndex: 0, waitForLoginPage: true)
                .startCall(callId)
        }
        AND("participant joins the call") {
            participantRobot.joinCall(callId)
            userRobot.waitForParticipantsToJoin(participants)
        }
        WHEN("user re-enters the call as the same user") {
            userRobot
                .endCall()
                .logout()
                .login(userIndex: 0, waitForLoginPage: true)
                .startCall(callId, clearTextField: true)
        }
        THEN("there is one participant on the call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: participants)
        }
    }
    
    func testUserReentersTheCallAsAnotherUser() throws {
        linkToScenario(withId: 1782)
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")
        
        let participants = 1
        
        GIVEN("user starts a call") {
            userRobot
                .waitForAutoLogin()
                .logout()
                .login(userIndex: 0, waitForLoginPage: true)
                .startCall(callId)
        }
        AND("participant joins the call") {
            participantRobot.joinCall(callId)
            userRobot.waitForParticipantsToJoin(participants)
        }
        WHEN("user re-enters the call as another user") {
            userRobot
                .endCall()
                .logout()
                .login(userIndex: 1, waitForLoginPage: true)
                .startCall(callId, clearTextField: true)
        }
        THEN("there is one participant on the call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: participants)
        }
    }
    
    func testUserJoinsExistedCall() throws {
        linkToScenario(withId: 1783)
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")
        
        GIVEN("participant starts a call") {
            participantRobot.joinCall(callId)
        }
        AND("user joins the call") {
            sleep(15) // to be sure that participant has joined
            userRobot.joinCall(callId)
        }
        THEN("there is one participant on the call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: 1)
        }
    }
    
    func testUserSwitchesCalls() throws {
        linkToScenario(withId: 1784)
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")
        
        let anotherCallId = StreamTestCase.randomCallId
        let participantCountOnFirstCall = 1
        let participantCountOnSecondCall = 2

        GIVEN("there is a call with \(participantCountOnSecondCall) participants") {
            participantRobot.setUserCount(participantCountOnSecondCall).joinCall(anotherCallId)
        }
        AND("user starts a new call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
        }
        AND("participant joins the call with the user") {
            participantRobot.setUserCount(participantCountOnFirstCall).joinCall(callId)
            userRobot.waitForParticipantsToJoin(participantCountOnFirstCall)
        }
        WHEN("user leaves the call") {
            userRobot.endCall()
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
