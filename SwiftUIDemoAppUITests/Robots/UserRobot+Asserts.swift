//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

extension UserRobot {
    
    static let defaultTimeout: Double = 15
    
    @discardableResult
    func assertParticipantJoinCall() -> Self {
        let expectedText = "joined"
        let participantEvent = CallPage.participantEvent.wait().waitForText(expectedText, mustBeEqual: false)
        XCTAssertTrue(participantEvent.label.contains(expectedText))
        return self
    }
    
    @discardableResult
    func assertParticipantLeaveCall() -> Self {
        let expectedText = "left"
        let participantEvent = CallPage.participantEvent.wait().waitForDisappearance().wait().waitForText(expectedText, mustBeEqual: false)
        XCTAssertTrue(participantEvent.label.contains(expectedText))
        return self
    }
    
    @discardableResult
    func assertParticipantIsVisible() -> Self {
        let videoView = CallPage.participantVideoView.waitCount(1, timeout: UserRobot.defaultTimeout)
        XCTAssertTrue(videoView.firstMatch.exists)
        return self
    }
    
    @discardableResult
    func assertParticipantIsNotVisible() -> Self {
        let imageView = CallPage.participantImageView.waitCount(1, timeout: UserRobot.defaultTimeout)
        XCTAssertTrue(imageView.firstMatch.exists)
        return self
    }
    
    @discardableResult
    func assertParticipantIsMuted() -> Self {
        let mutedMicImage = CallPage.participantMicDisabledImage.waitCount(1, timeout: UserRobot.defaultTimeout)
        XCTAssertTrue(mutedMicImage.firstMatch.exists)
        return self
    }
    
    @discardableResult
    func assertParticipantIsNotMuted() -> Self {
        let unmutedMicImage = CallPage.participantMicEnabledImage.waitCount(1, timeout: UserRobot.defaultTimeout)
        XCTAssertTrue(unmutedMicImage.firstMatch.exists)
        return self
    }
    
    @discardableResult
    func assertParticipantStartSharingScreen(userCount: Int = 2) -> Self {
        XCTAssertTrue(CallPage.screenSharingView.wait(timeout: UserRobot.defaultTimeout).exists)
        XCTAssertTrue(CallPage.screenSharingLabel.label.contains("presenting"))
        XCTAssertEqual(userCount, CallPage.screenSharingParticipantView.count)
        return self
    }
    
    @discardableResult
    func assertParticipantStopSharingScreen() -> Self {
        XCTAssertFalse(CallPage.screenSharingView.waitForDisappearance().exists)
        XCTAssertFalse(CallPage.screenSharingLabel.exists)
        XCTAssertEqual(0, CallPage.screenSharingParticipantView.count)
        return self
    }
}

extension XCUIElement {
    
    @discardableResult
    func wait(timeout: Double = UserRobot.defaultTimeout) -> Self {
        _ = waitForExistence(timeout: timeout)
        return self
    }
}
