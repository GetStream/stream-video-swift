//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

final class Sample_Tests: StreamTestCase {
    
    func testScreenSharing() {
        let callId = randomCallId()
        
        GIVEN("user starts a call") {
            userRobot
                .login()
                .start(callId: callId)
        }
        WHEN("participant joins the call and shares the screen") {
            participantRobot.join(
                callId: callId,
                options: [.withCamera, .withMicrophone, .beFrozen, .beSilent],
                actions: [.shareScreen]
            )
        }
        THEN("dummy assert happens") {
            XCTAssertFalse(callId == "")
        }
    }
}
