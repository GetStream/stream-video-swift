//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

/// Simulates user behavior
final class UserRobot: Robot {}

// CallDetailsPage
extension UserRobot {
    @discardableResult
    private func typeText(_ text: String, obtainKeyboardFocus: Bool = true, clean: Bool = false) -> Self {
        let inputField = CallDetailsPage.callIdInputField
        if obtainKeyboardFocus {
            inputField.obtainKeyboardFocus()
        }
        if clean {
            inputField.clear()
        }
        inputField.typeText(text)
        return self
    }
    
    @discardableResult
    func login(userIndex: Int = 0, waitForLoginPage: Bool = false) -> Self {
        let users = LoginPage.users
        if waitForLoginPage {
            users.firstMatch.wait()
        }
        if users.count > 0 {
            users.element(boundBy: userIndex).tap()
        }
        return self
    }
    
    @discardableResult
    func logout() -> Self {
        let users = LoginPage.users
        if users.count == 0 {
            CallDetailsPage.userAvatar.wait().tap()
            CallDetailsPage.signOutButton.wait().tap()
        }
        return self
    }
    
    @discardableResult
    func tapOnStartCallButton(withDelay: Bool = false) -> Self {
        if withDelay { sleep(2) } // FIXME: https://github.com/GetStream/ios-issues-tracking/issues/382
        CallDetailsPage.startCallButton.tap()
        return self
    }
    
    @discardableResult
    func startCall(_ callId: String, clearTextField clean: Bool = false, waitForCompletion: Bool = true) -> Self {
        typeText(callId, clean: clean)
        tapOnStartCallButton()
        if waitForCompletion {
            CallPage.hangUpButton.wait()
            CallPage.ConnectingView.callConnectingView.waitForDisappearance(timeout: Self.defaultTimeout)
        }
        return self
    }
    
    @discardableResult
    func joinCall(_ callId: String, clearTextField clean: Bool = false, waitForCompletion: Bool = true) -> Self {
        CallDetailsPage.joinCallTab.tap()
        typeText(callId, clean: clean)
        CallDetailsPage.joinCallButton.tap()
        if waitForCompletion {
            CallPage.ConnectingView.callConnectingView.waitForDisappearance(timeout: Self.defaultTimeout)
        }
        return self
    }
    
    @discardableResult
    func joinCallFromLobby() -> Self {
        if !LobbyPage.otherParticipantsCount.exists {
            CallDetailsPage.lobbyTab.tap()
            tapOnStartCallButton()
        }
        LobbyPage.joinCallButton.tap()
        return self
    }
    
    @discardableResult
    func enterLobby(_ callId: String, clearTextField clean: Bool = false) -> Self {
        typeText(callId, clean: clean)
        enterLobby()
        return self
    }
    
    @discardableResult
    func enterLobby() -> Self {
        CallDetailsPage.lobbyTab.tap()
        tapOnStartCallButton()
        return self
    }
    
    @discardableResult
    func enterRingEvents(_ callId: String) -> Self {
        typeText(callId)
        enterRingEvents()
        return self
    }
    
    @discardableResult
    func enterRingEvents() -> Self {
        CallDetailsPage.ringEventsTab.tap()
        tapOnStartCallButton()
        return self
    }
    
    @discardableResult
    func selectParticipants(count: Int) -> Self {
        CallDetailsPage.participants.waitCount(1)
        for i in 0...count - 1 {
            CallDetailsPage.participants.element(boundBy: i).tap()
        }
        return self
    }
}

// CallPage
extension UserRobot {
    enum UserControls {
        case enable
        case disable
    }
    
    enum CameraPosition {
        case back
        case front
    }
    
    enum Direction {
        case right
        case left
        case up
        case down
    }
    
    enum View: String {
        case grid
        case fullscreen
        case spotlight
    }
    
    @discardableResult
    func microphone(_ action: UserControls) -> Self {
        userControls(toggle: CallPage.microphoneToggle.firstMatch, action: action)
    }
    
    @discardableResult
    func camera(_ action: UserControls) -> Self {
        userControls(toggle: CallPage.cameraToggle.firstMatch, action: action)
    }
    
    @discardableResult
    func camera(_ position: CameraPosition) -> Self {
        userControls(
            toggle: CallPage.cameraPositionToggle.firstMatch,
            action: position == .front ? .enable : .disable
        )
    }
    
    @discardableResult
    func minimizeCall() -> Self {
        CallPage.minimizeCallViewButton.wait().tap()
        return self
    }
    
    @discardableResult
    func endCall() -> Self {
        CallPage.hangUpButton.firstMatch.safeTap()
        return self
    }
    
    @discardableResult
    func setView(mode: View) -> Self {
        CallPage.viewMenu.wait().tapFrameCenter()
        switch mode {
        case .grid:
            CallPage.ViewMenu.grid.tapFrameCenter()
        case .fullscreen:
            CallPage.ViewMenu.fullscreen.tapFrameCenter()
        case .spotlight:
            CallPage.ViewMenu.spotlight.tapFrameCenter()
        }
        return self
    }
    
    @discardableResult
    func minimizeVideoView() -> Self {
        CallPage.minimizeCallViewButton.wait().tap()
        return self
    }
    
    @discardableResult
    func maximizeVideoView() -> Self {
        CallPage.minimizedCallView.wait().tapFrameCenter()
        return self
    }
    
    @discardableResult
    func moveCornerDragableViewToTheBottom() -> Self {
        CallPage.cornerDragableView.dragAndDrop(dropElement: CallPage.hangUpButton, duration: 0.5)
        return self
    }
    
    @discardableResult
    func moveMinimizedCallViewToTheLeft() -> Self {
        CallPage.minimizedCallView.dragAndDrop(dropElement: CallDetailsPage.userAvatar, duration: 0.5)
        return self
    }
    
    @discardableResult
    func scrollScreenSharingParticipantList(to: Direction, times: Int = 1) -> Self {
        let scrollView = CallPage.screenSharingParticipantList
        for _ in 1...times {
            switch to {
            case .right:
                scrollView.swipeLeft()
            case .left:
                scrollView.swipeRight()
            default:
                break
            }
        }
        return self
    }
    
    @discardableResult
    func scrollSpotlightParticipantList(to: Direction, times: Int = 1) -> Self {
        let scrollView = CallPage.spotlightViewParticipantList
        for _ in 1...times {
            switch to {
            case .right:
                scrollView.swipeLeft()
            case .left:
                scrollView.swipeRight()
            default:
                break
            }
        }
        return self
    }
    
    @discardableResult
    func scrollGridViewParticipantList(to: Direction, times: Int = 1) -> Self {
        let scrollView = CallPage.gridViewParticipantList
        for _ in 1...times {
            switch to {
            case .down:
                scrollView.swipeUp()
            case .up:
                scrollView.swipeDown()
            default:
                break
            }
        }
        return self
    }
    
    @discardableResult
    private func userControls(toggle: XCUIElement, action: UserControls) -> Self {
        if action == .disable && toggle.isOn || action == .enable && toggle.isOff {
            toggle.tap()
        }
        return self
    }

    @discardableResult
    func waitForDisappearanceOfParticipantEventLabel(_ timeout: Double = defaultTimeout) -> Self {
        CallPage.participantEvent.waitForDisappearance(timeout: timeout)
        return self
    }
    
    @discardableResult
    func waitForParticipantsToJoin(_ participantCount: Int, timeout: Double = defaultTimeout) -> Self {
        CallPage.participantMenu.wait(timeout: timeout).tap()
        let user = 1
        let expectedCount = participantCount + user
        CallPage.ParticipantMenu.participantCount
            .waitForValue("\(expectedCount)", timeout: timeout)
            .tapFrameCenter() // to take a screenshot
        safelyCloseParticipantsMenu()
        return self
    }
    
    @discardableResult
    func waitCallControllsToAppear(timeout: Double = defaultTimeout) -> Self {
        XCTAssertTrue(CallPage.hangUpButton.wait(timeout: timeout).exists, "Can't join the call")
        return self
    }
    
    private func safelyCloseParticipantsMenu() {
        var retries = 0
        let closeButton = CallPage.ParticipantMenu.closeButton
        while closeButton.exists && retries < 3 {
            CallPage.ParticipantMenu.closeButton.waitForHitPoint().tapFrameCenter()
            retries += 1
        }
    }
}
