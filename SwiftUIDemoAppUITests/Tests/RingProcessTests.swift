//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

final class RingProcessTests: StreamTestCase {
    
    func testRingProcessWithZeroParticipants() {
        linkToScenario(withId: 1787)
        
        let participants = 0
        let user = 1

        WHEN("user opens connecting screen") {
            userRobot
                .login()
                .enterRingEvents(callId)
        }
        THEN("all required elements are on the screen") {
            userRobot
                .assertConnectingView(with: participants + user)
                .assertCallControls()
        }
    }
    
    func testRingProcessWithOneParticipant() {
        linkToScenario(withId: 1788)
        
        let participants = 1
        let user = 1
        
        WHEN("user calls to participant") {
            userRobot
                .login()
                .selectParticipants(count: participants)
                .enterRingEvents(callId)
        }
        THEN("all required elements are on the screen") {
            userRobot
                .assertConnectingView(with: participants + user)
                .assertCallControls()
        }
    }
    
    func testRingProcessWithTwoParticipants() {
        linkToScenario(withId: 1789)
        
        let participants = 2
        let user = 1
        
        WHEN("user calls to participant") {
            userRobot
                .login()
                .selectParticipants(count: participants)
                .enterRingEvents(callId)
        }
        THEN("all required elements are on the screen") {
            userRobot
                .assertConnectingView(with: participants + user)
                .assertCallControls()
        }
    }
}
