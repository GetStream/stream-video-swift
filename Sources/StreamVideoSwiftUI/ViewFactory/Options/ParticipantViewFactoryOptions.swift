//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

// MARK: - Participant Options

/// Options for creating the video participants view, shown during a call.
public final class VideoParticipantsViewOptions {
    /// The view model used for the call.
    public let viewModel: CallViewModel
    /// The frame available for rendering.
    public let availableFrame: CGRect
    /// Called when a participant's track changes its visibility.
    public let onChangeTrackVisibility: @MainActor (CallParticipant, Bool) -> Void

    public init(
        viewModel: CallViewModel,
        availableFrame: CGRect,
        onChangeTrackVisibility: @escaping @MainActor (CallParticipant, Bool) -> Void
    ) {
        self.viewModel = viewModel
        self.availableFrame = availableFrame
        self.onChangeTrackVisibility = onChangeTrackVisibility
    }
}

/// Options for creating the view of a single call participant.
public final class VideoParticipantViewOptions: Sendable {
    /// The participant to display.
    public let participant: CallParticipant
    /// The id used to identify the participant's view.
    public let id: String
    /// The frame available for the participant's video.
    public let availableFrame: CGRect
    /// The content mode of the participant's video.
    public let contentMode: UIView.ContentMode
    /// Custom data passed to the view.
    public let customData: [String: RawJSON]
    /// The current call.
    public let call: Call?

    public init(
        participant: CallParticipant,
        id: String,
        availableFrame: CGRect,
        contentMode: UIView.ContentMode,
        customData: [String: RawJSON],
        call: Call?
    ) {
        self.participant = participant
        self.id = id
        self.availableFrame = availableFrame
        self.contentMode = contentMode
        self.customData = customData
        self.call = call
    }
}

/// Options for creating the modifier applied to a call participant's view.
public final class VideoCallParticipantModifierOptions: Sendable {
    /// The participant whose view is modified.
    public let participant: CallParticipant
    /// The current call.
    public let call: Call?
    /// The frame available for the participant's video.
    public let availableFrame: CGRect
    /// The aspect ratio of the participant's video.
    public let ratio: CGFloat
    /// Whether to show all the participant info, such as name and connection quality.
    public let showAllInfo: Bool

    public init(
        participant: CallParticipant,
        call: Call?,
        availableFrame: CGRect,
        ratio: CGFloat,
        showAllInfo: Bool
    ) {
        self.participant = participant
        self.call = call
        self.availableFrame = availableFrame
        self.ratio = ratio
        self.showAllInfo = showAllInfo
    }
}

/// Options for creating the modifier applied to the local participant's view.
public final class LocalParticipantViewModifierOptions {
    /// The local participant.
    public let localParticipant: CallParticipant
    /// Binding to the call settings.
    public let callSettings: Binding<CallSettings>
    /// The current call.
    public let call: Call?

    public init(
        localParticipant: CallParticipant,
        callSettings: Binding<CallSettings>,
        call: Call?
    ) {
        self.localParticipant = localParticipant
        self.callSettings = callSettings
        self.call = call
    }
}

/// Options for creating a user avatar.
public final class UserAvatarViewOptions {
    /// The user to show the avatar for.
    public let user: User
    /// The size of the avatar.
    public let size: CGFloat
    /// Provides the view shown when the avatar image can't be loaded.
    public let failbackProvider: (() -> AnyView)?

    public init(
        user: User,
        size: CGFloat,
        failbackProvider: (() -> AnyView)? = nil
    ) {
        self.user = user
        self.size = size
        self.failbackProvider = failbackProvider
    }
}
