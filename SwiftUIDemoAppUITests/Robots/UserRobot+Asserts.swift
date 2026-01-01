//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

extension UserRobot {
    
    static let defaultTimeout: Double = TestRunnerEnvironment.isCI ? 60 : 30
    
    @discardableResult
    func assertParticipantJoinCall() -> Self {
        assertParticipantEvent("joined")
    }
    
    @discardableResult
    func assertParticipantLeaveCall() -> Self {
        assertParticipantEvent("left")
    }
    
    @discardableResult
    private func assertParticipantEvent(_ expectedText: String) -> Self {
        let participantEvent = CallPage.participantEvent.wait().waitForText(
            expectedText,
            timeout: UserRobot.defaultTimeout,
            mustBeEqual: false
        )
        let errMessage = "`\(participantEvent.label)` does not contain `\(expectedText)`"
        XCTAssertTrue(participantEvent.label.contains(expectedText), errMessage)
        return self
    }
    
    @discardableResult
    func assertUserMicrophoneIsEnabled() -> Self {
        assertToogle(CallPage.microphoneToggle, state: .enable)
    }
    
    @discardableResult
    func assertUserMicrophoneIsDisabled() -> Self {
        assertToogle(CallPage.microphoneToggle, state: .disable)
    }
    
    @discardableResult
    func assertParticipantCameraIsEnabled() -> Self {
        assertToogle(CallPage.participantView.firstMatch, state: .enable)
    }
    
    @discardableResult
    func assertParticipantCameraIsDisabled() -> Self {
        assertToogle(CallPage.participantView.firstMatch, state: .disable)
    }
    
    @discardableResult
    func assertParticipantMicrophoneIsEnabled() -> Self {
        assertToogle(CallPage.participantMicIcon.firstMatch, state: .enable)
    }
    
    @discardableResult
    func assertParticipantMicrophoneIsDisabled() -> Self {
        assertToogle(CallPage.participantMicIcon.firstMatch, state: .disable)
    }
    
    @discardableResult
    private func assertToogle(_ toogle: XCUIElement, state: UserControls) -> Self {
        switch state {
        case .enable:
            XCTAssertTrue(
                toogle.wait().waitForValue("1", timeout: UserRobot.defaultTimeout).isOn,
                "Toggle should be on"
            )
        case .disable:
            XCTAssertTrue(
                toogle.wait().waitForValue("0", timeout: UserRobot.defaultTimeout).isOff,
                "Toggle should be off"
            )
        }
        return self
    }
    
    @discardableResult
    func assertConnectionQualityIndicator() -> Self {
        XCTAssertTrue(CallPage.connectionQualityIndicator.wait().exists, "connectionQualityIndicator should appear")
        return self
    }
    
    @discardableResult
    func assertParticipantStartSharingScreen() -> Self {
        let expectedText = "presenting"
        XCTAssertTrue(CallPage.screenSharingView.wait(timeout: UserRobot.defaultTimeout).exists, "screenSharingView should appear")
        XCTAssertTrue(
            CallPage.screenSharingLabel.label.contains(expectedText),
            "`\(CallPage.screenSharingLabel.label)` does not contain `\(expectedText)`"
        )
        return self
    }
    
    @discardableResult
    func assertRecordingIcon(isVisible: Bool) -> Self {
        if isVisible {
            XCTAssertTrue(CallPage.recordingView.wait().exists, "recording icon should appear")
        } else {
            XCTAssertFalse(
                CallPage.recordingView.waitForDisappearance(timeout: UserRobot.defaultTimeout).exists,
                "recording icon should disappear"
            )
        }
        return self
    }
    
    @discardableResult
    func assertCallDurationView(isVisible: Bool) -> Self {
        if isVisible {
            XCTAssertTrue(CallPage.callDurationView.wait().exists, "callDurationView should appear")
        } else {
            XCTAssertFalse(
                CallPage.callDurationView.waitForDisappearance(timeout: UserRobot.defaultTimeout).exists,
                "callDurationView should disappear"
            )
        }
        return self
    }
    
    @discardableResult
    func assertUserCountWhenScreenSharing(_ userCount: Int) -> Self {
        let actualViewsCount = CallPage.screenSharingParticipantView.waitCount(
            userCount,
            timeout: UserRobot.defaultTimeout,
            exact: true
        ).count
        XCTAssertEqual(userCount, actualViewsCount)
        return self
    }
    
    @discardableResult
    func assertGridViewParticipantListVisibity(percent: Int) -> Self {
        assertParticipantListVisibility(expectedPercent: percent, details: CallPage.gridViewParticipantListDetails)
    }
    
    @discardableResult
    private func assertParticipantListVisibility(expectedPercent: Int, details: XCUIElement) -> Self {
        let expectedValue = "\(expectedPercent)%"
        let actualValue = (details.wait().waitForValue("\(expectedPercent)", mustBeEqual: false).value as! String)
            .filter { !$0.isWhitespace }
        XCTAssertEqual(expectedValue, actualValue)
        return self
    }
    
    @discardableResult
    func assertParticipantStopSharingScreen() -> Self {
        XCTAssertFalse(
            CallPage.screenSharingView.waitForDisappearance(timeout: Self.defaultTimeout).exists,
            "screenSharingView should disappear"
        )
        XCTAssertFalse(CallPage.screenSharingLabel.exists, "screenSharingLabel should disappear")
        XCTAssertEqual(0, CallPage.screenSharingParticipantView.count)
        return self
    }
    
    @discardableResult
    func assertCallControls() -> Self {
        XCTAssertTrue(CallPage.cameraToggle.wait().exists, "cameraToggle should appear")
        XCTAssertTrue(CallPage.cameraPositionToggle.wait().exists, "cameraPositionToggle should appear")
        XCTAssertTrue(CallPage.microphoneToggle.wait().exists, "microphoneToggle should appear")
        XCTAssertTrue(CallPage.hangUpButton.wait().exists, "hangUpButton should appear")
        return self
    }
    
    @discardableResult
    func assertThereAreNoCallControls() -> Self {
        XCTAssertFalse(CallPage.hangUpButton.waitForDisappearance().exists, "hangUpButton should disappear")
        XCTAssertFalse(CallPage.cameraToggle.exists, "cameraToggle should disappear")
        XCTAssertFalse(CallPage.cameraPositionToggle.exists, "cameraPositionToggle should disappear")
        XCTAssertFalse(CallPage.microphoneToggle.exists, "microphoneToggle should disappear")
        return self
    }
    
    @discardableResult
    func assertEmptyCall() -> Self {
        XCTAssertEqual(1, CallPage.participantView.waitCount(1).count) // active user is treated as a participant
        XCTAssertEqual(0, CallPage.participantName.count)
        XCTAssertTrue(CallPage.participantMenu.exists, "participantMenu icon should disappear")
        return self
    }
    
    @discardableResult
    func assertConnectingView(with participantCount: Int) -> Self {
        XCTAssertTrue(CallPage.ConnectingView.callConnectingView.wait().exists, "callConnectingView should appear")
        XCTAssertTrue(CallPage.ConnectingView.callingIndicator.exists, "callingIndicator should appear")
        if participantCount > 3 {
            XCTAssertEqual(
                3,
                CallPage.ConnectingView.participantsBubblesWithImages.count + CallPage.ConnectingView
                    .participantsBubblesWithoutImages.count
            )
            XCTAssertEqual("+\(participantCount - 2)", CallPage.ConnectingView.participantsBubblesWithoutImages.lastMatch?.text)
        } else if participantCount > 1 {
            XCTAssertEqual(
                participantCount,
                CallPage.ConnectingView.participantsBubblesWithImages.count + CallPage.ConnectingView
                    .participantsBubblesWithoutImages.count
            )
            if let name = CallPage.ConnectingView.participantsBubblesWithoutImages.lastMatch?.text {
                XCTAssertFalse(name.contains("+"))
            }
        } else if participantCount > 0 {
            XCTAssertTrue(
                CallPage.ConnectingView.callConnectingParticipantView.exists,
                "callConnectingParticipantView should appear"
            )
        }
        return self
    }
    
    @discardableResult
    func assertGridView(with participantCount: Int) -> Self {
        if participantCount > 2 {
            let user = 1
            XCTAssertFalse(CallPage.cornerDraggableView.waitForDisappearance().exists, "cornerDraggableView should disappear")
            XCTAssertEqual(participantCount + user, CallPage.participantView.count, "GridView")
        } else {
            XCTAssertTrue(CallPage.cornerDraggableView.wait().exists, "cornerDraggableView should appear")
            XCTAssertEqual(participantCount, CallPage.participantView.count, "GridView")
        }
        XCTAssertFalse(CallPage.spotlightViewParticipantList.exists, "spotlightViewParticipantList should disappear")
        return self
    }
    
    @discardableResult
    func assertSpotlightView(with participantCount: Int) -> Self {
        XCTAssertTrue(CallPage.spotlightViewParticipantList.wait().exists, "spotlightViewParticipantList should appear")
        XCTAssertEqual(1, CallPage.participantView.count, "SpotlightView")
        XCTAssertFalse(CallPage.cornerDraggableView.exists, "cornerDraggableView should disappear")

        let maxVisibleCount = 6
        let actualCount = CallPage.spotlightParticipantView.count
        if participantCount > maxVisibleCount {
            XCTAssertTrue(
                actualCount >= maxVisibleCount && actualCount <= participantCount,
                "SpotlightView, expected: \(maxVisibleCount) <= \(actualCount) <= \(participantCount)"
            )
        } else {
            XCTAssertEqual(participantCount, actualCount, "SpotlightView")
        }
        return self
    }
    
    @discardableResult
    func assertFullscreenView() -> Self {
        XCTAssertEqual(1, CallPage.participantView.count, "FullscreenView")
        XCTAssertEqual(0, CallPage.spotlightParticipantView.count, "FullscreenView")
        XCTAssertFalse(CallPage.spotlightViewParticipantList.exists, "spotlightViewParticipantList should disappear")
        XCTAssertFalse(CallPage.cornerDraggableView.exists, "cornerDraggableView should disappear")
        return self
    }
    
    @discardableResult
    func assertLobby() -> Self {
        XCTAssertTrue(LobbyPage.callParticipantsCount.wait().exists, "callParticipantsCount should appear")
        XCTAssertTrue(LobbyPage.microphoneToggle.exists, "microphoneToggle should appear")
        XCTAssertTrue(LobbyPage.cameraToggle.exists, "cameraToggle should appear")
        XCTAssertTrue(LobbyPage.microphoneCheckView.exists, "microphoneCheckView should appear")
        XCTAssertTrue(LobbyPage.cameraCheckView.exists, "cameraCheckView should appear")
        return self
    }
    
    @discardableResult
    func assertOtherParticipantsCountInLobby(_ count: Int) -> Self {
        XCTAssertEqual("\(count)", LobbyPage.callParticipantsCount.wait().value as? String)
        return self
    }
    
    @discardableResult
    func assertParticipantsAreVisible(count: Int) -> Self {
        XCTAssertEqual(count, CallPage.participantView.waitCount(count, timeout: UserRobot.defaultTimeout, exact: true).count)
        return self
    }
    
    @discardableResult
    func assertReconnectingMessage(isVisible: Bool) -> Self {
        if isVisible {
            XCTAssertTrue(CallPage.reconnectingMessage.wait().exists, "reconnectingMessage should appear")
        } else {
            XCTAssertFalse(
                CallPage.reconnectingMessage.waitForDisappearance(timeout: UserRobot.defaultTimeout * 2).exists,
                "reconnectingMessage should disappear"
            )
        }
        return self
    }
    
    @discardableResult
    func assertConnectionErrorAlert() -> Self {
        XCTAssertTrue(CallDetailsPage.connectionErrorAlert.wait().exists)
        return self
    }
}

extension XCUIElement {
    
    @discardableResult
    func wait(timeout: Double = UserRobot.defaultTimeout) -> Self {
        if !exists {
            _ = waitForExistence(timeout: timeout)
        }
        return self
    }
}
