//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

final class LobbyTests: StreamTestCase {
    
    func testLobbyWithTwoParticipants() throws {
        linkToScenario(withId: 1785)
        
        throw XCTSkip("https://github.com/GetStream/ios-issues-tracking/issues/379")
        
        let participants = 2
        
        GIVEN("participant is on call") {
            userRobot
                .login()
                .startCall(callId)
            
            participantRobot
                .setUserCount(participants)
                .joinCall(callId)
            
            userRobot
                .assertParticipantJoinCall()
                .endCall()
        }
        WHEN("user enters lobby") {
            userRobot.enterLobby()
        }
        THEN("all required elements are on the screen") {
            userRobot.assertLobby()
        }
        AND("user observes the number of participants on call") {
            userRobot.assertOtherParticipantsCountInLobby(participants)
        }
        WHEN("user enables microphone") {
            userRobot.microphone(.disable)
        }
        AND("user joins the call") {
            userRobot.joinCallFromLobby()
        }
        THEN("there are \(participants) participants on the call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: participants)
        }
        AND("user's microphone is turned off") {
            userRobot.assertUserMicrophoneIsDisabled()
        }
    }
    
    func testLobbyWithZeroParticipants() {
        linkToScenario(withId: 1786)
        
        WHEN("user enters lobby") {
            userRobot.enterLobby(callId)
        }
        THEN("all required elements are on the screen") {
            userRobot.assertLobby()
        }
        AND("there are no participants on call") {
            userRobot.assertOtherParticipantsCountInLobby(0)
        }
        WHEN("user disables microphone") {
            userRobot.microphone(.disable)
        }
        AND("user joins the call") {
            userRobot.joinCallFromLobby()
        }
        THEN("there are no participants on the call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: 0)
        }
        AND("user's microphone is turned off") {
            userRobot.assertUserMicrophoneIsDisabled()
        }
    }
}
