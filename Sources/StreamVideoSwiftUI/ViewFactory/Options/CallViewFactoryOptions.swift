//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

// MARK: - Calling Options

/// Options for creating the outgoing call view.
public final class OutgoingCallViewOptions: Sendable {
    /// The view model used for the call.
    public let viewModel: CallViewModel

    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }
}

/// Options for creating the joining call view.
public final class JoiningCallViewOptions: Sendable {
    /// The view model used for the call.
    public let viewModel: CallViewModel

    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }
}

/// Options for creating the incoming call view.
public final class IncomingCallViewOptions: Sendable {
    /// The view model used for the call.
    public let viewModel: CallViewModel
    /// The incoming call to display.
    public let callInfo: IncomingCall

    public init(viewModel: CallViewModel, callInfo: IncomingCall) {
        self.viewModel = viewModel
        self.callInfo = callInfo
    }
}

/// Options for creating the lobby view, shown before the user joins the call.
public final class LobbyViewOptions {
    /// The view model used for the call.
    public let viewModel: CallViewModel
    /// The call the user is about to join.
    public let lobbyInfo: LobbyInfo
    /// Binding to the call settings applied when joining.
    public let callSettings: Binding<CallSettings>

    public init(
        viewModel: CallViewModel,
        lobbyInfo: LobbyInfo,
        callSettings: Binding<CallSettings>
    ) {
        self.viewModel = viewModel
        self.lobbyInfo = lobbyInfo
        self.callSettings = callSettings
    }
}

// MARK: - Call Options

/// Options for creating the call view, shown when a call is in progress.
public final class CallViewOptions: Sendable {
    /// The view model used for the call.
    public let viewModel: CallViewModel

    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }
}

/// Options for creating the minimized call view.
public final class MinimizedCallViewOptions: Sendable {
    /// The view model used for the call.
    public let viewModel: CallViewModel

    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }
}

/// Options for creating the call controls view.
public final class CallControlsViewOptions: Sendable {
    /// The view model used for the call.
    public let viewModel: CallViewModel

    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }
}

/// Options for creating the view displayed at the top of the call view.
public final class CallTopViewOptions: Sendable {
    /// The view model used for the call.
    public let viewModel: CallViewModel

    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }
}

/// Options for creating the view shown when the local participant is alone on the call.
public final class WaitingLocalUserViewOptions: Sendable {
    /// The view model used for the call.
    public let viewModel: CallViewModel

    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }
}

/// Options for creating the list of participants in the call.
public final class ParticipantsListViewOptions: Sendable {
    /// The view model used for the call.
    public let viewModel: CallViewModel

    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }
}

/// Options for creating the view shown during a screen sharing session.
public final class ScreenSharingViewOptions {
    /// The view model used for the call.
    public let viewModel: CallViewModel
    /// The current screen sharing session.
    public let screenSharingSession: ScreenSharingSession
    /// The frame available to display the view.
    public let availableFrame: CGRect

    public init(
        viewModel: CallViewModel,
        screenSharingSession: ScreenSharingSession,
        availableFrame: CGRect
    ) {
        self.viewModel = viewModel
        self.screenSharingSession = screenSharingSession
        self.availableFrame = availableFrame
    }
}

/// Options for creating the view shown while the call is reconnecting.
public final class ReconnectionViewOptions: Sendable {
    /// The view model used for the call.
    public let viewModel: CallViewModel

    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }
}

/// Options for creating the prompt that asks the user to grant missing permissions.
public final class PermissionsPromptViewOptions: Sendable {
    /// The current call.
    public let call: Call?

    public init(call: Call?) {
        self.call = call
    }
}
