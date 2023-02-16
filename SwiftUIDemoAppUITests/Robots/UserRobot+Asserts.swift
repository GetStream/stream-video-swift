//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

extension UserRobot {
    
    private static let defaultTimeout: Double = 15
    
    func assertParticipantIsPresenting() {
        XCTAssertTrue(app.staticTexts["presentingLabel"].wait(timeout: UserRobot.defaultTimeout).exists)
    }
}
