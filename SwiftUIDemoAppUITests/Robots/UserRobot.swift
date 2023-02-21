//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

/// Simulates user behavior
final class UserRobot: Robot {}

// CallDetailsPage
extension UserRobot {
    @discardableResult
    private func typeText(_ text: String, obtainKeyboardFocus: Bool = true) -> Self {
        let inputField = CallDetailsPage.callIdInputField
        if obtainKeyboardFocus {
            inputField.obtainKeyboardFocus().typeText(text)
        } else {
            inputField.typeText(text)
        }
        return self
    }
    
    @discardableResult
    func login() -> Self {
        let users = LoginPage.users
        if users.count > 0 {
            users.firstMatch.tap()
        }
        return self
    }
    
    @discardableResult
    func startCall(_ callId: String) -> Self {
        typeText(callId)
        CallDetailsPage.startCallButton.tap()
        return self
    }
    
    @discardableResult
    func joinCall(_ callId: String) -> Self {
        typeText(callId)
        CallDetailsPage.joinCallButton.tap()
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
    
    func microphone(_ action: UserControls) -> Self {
        userControls(toggle: CallPage.microphoneToggle, action: action)
    }
    
    func camera(_ action: UserControls) -> Self {
        userControls(toggle: CallPage.cameraToggle, action: action)
    }
    
    func camera(_ position: CameraPosition) -> Self {
        userControls(
            toggle: CallPage.cameraPositionToggle,
            action: position == .front ? .enable : .disable
        )
    }
    
    func minimizeCall() {
        CallPage.minimizeCallViewButton.wait().tap()
    }
    
    func endCall() {
        CallPage.hangUpButton.wait().tap()
    }
    
    private func userControls(toggle: XCUIElement, action: UserControls) -> Self {
        if action == .disable && toggle.isOn || action == .enable && toggle.isOff {
            toggle.tap()
        }
        return self
    }
}
