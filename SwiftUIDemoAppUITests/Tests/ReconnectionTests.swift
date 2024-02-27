//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest

// Requires running a standalone Sinatra server
final class ReconnectionTests: StreamTestCase {
    
    override func tearDownWithError() throws {
        sinatra.setConnection(state: .on)
    
        try super.tearDownWithError()
    }
    
    func testReconnectingMessage() {
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
        THEN("user observes a reconnecting message") {
            userRobot.assertReconnectingMessage(isVisible: true)
        }
        WHEN("user restores the internet connection") {
            sinatra.setConnection(state: .on)
        }
        THEN("reconnecting message disappears") {
            userRobot.assertReconnectingMessage(isVisible: false)
        }
    }
}
