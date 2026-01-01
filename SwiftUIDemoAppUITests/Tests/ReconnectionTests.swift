//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

// Requires running a standalone Sinatra server
final class ReconnectionTests: StreamTestCase {
    
    override func tearDownWithError() throws {
        sinatra.setConnection(state: .on)
    
        try super.tearDownWithError()
    }

    func testReconnectingMessageWhenDisconnectedForMoreThanFastReconnectThreshold() throws {
        linkToScenario(withId: 2030)

        GIVEN("user starts a new call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
                .waitLiveMeetingLabelToAppear()
        }
        WHEN("user loses the internet connection") {
            sinatra.setConnection(state: .off)
        }
        THEN("user waits 10 second to recover connection") {
            let waitExpectation = expectation(description: "Waiting ....")
            waitExpectation.isInverted = true
            wait(for: [waitExpectation], timeout: 30)
        }
        WHEN("user restores the internet connection") {
            sinatra.setConnection(state: .on)
        }
        THEN("user observes a reconnecting message") {
            userRobot.assertReconnectingMessage(isVisible: true)
        }
        THEN("reconnecting message disappears") {
            userRobot.assertReconnectingMessage(isVisible: false)
        }
    }
}
