//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// `SpotlightSpeakerView` represents a view for the dominant speaker's thumbnail.
public struct SpotlightSpeakerView<Factory: ViewFactory>: View {

    // MARK: - Properties

    /// Factory for creating views.
    public var viewFactory: Factory

    /// The dominant speaker participant whose thumbnail will be displayed.
    public var participant: CallParticipant

    /// Suffix for constructing the view ID.
    public var viewIdSuffix: String

    /// Information about the call (if available).
    public var call: Call?

    /// Frame in which the dominant speaker's thumbnail will be displayed.
    public var availableFrame: CGRect

    /// Computed property to generate a unique view ID for the dominant speaker.
    var viewId: String { participant.id + (!viewIdSuffix.isEmpty ? "-\(viewIdSuffix)" : "") }

    // MARK: - Initialization

    /// Creates a new instance of `SpotlightSpeakerView`.
    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        participant: CallParticipant,
        viewIdSuffix: String,
        call: Call?,
        availableFrame: CGRect
    ) {
        self.viewFactory = viewFactory
        self.participant = participant
        self.viewIdSuffix = viewIdSuffix
        self.call = call
        self.availableFrame = availableFrame
    }

    // MARK: - View Body

    /// Defines the structure and layout of the view.
    public var body: some View {
        // Creates the video view for the dominant speaker.
        viewFactory.makeVideoParticipantView(
            participant: participant,
            id: viewId,
            availableFrame: availableFrame,
            contentMode: .scaleAspectFill,
            customData: [:],
            call: call
        )
        // Modifies the video view based on the participant's details and the call's state.
        .modifier(
            viewFactory.makeVideoCallParticipantModifier(
                participant: participant,
                call: call,
                availableFrame: availableFrame,
                ratio: availableFrame.width / availableFrame.height,
                showAllInfo: true
            )
        )
        // Applies changes to the participant's video track.
        .modifier(
            ParticipantChangeModifier(
                participant: participant,
                onChangeTrackVisibility: { participant, isVisible in
                    Task {
                        await call?.changeTrackVisibility(
                            for: participant,
                            isVisible: isVisible
                        )
                    }
                }
            )
        )
        // Observes visibility changes of the dominant speaker's video track.
        .visibilityObservation(
            in: availableFrame
        ) { isVisible in
            Task {
                await call?.changeTrackVisibility(
                    for: participant,
                    isVisible: isVisible
                )
            }
        }
    }
}
