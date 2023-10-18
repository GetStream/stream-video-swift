//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct DominantSpeakerLayoutComponent<Factory: ViewFactory>: View {

    public var viewFactory: Factory
    public var participant: CallParticipant
    public var viewIdSuffix: String
    public var call: Call?
    public var availableFrame: CGRect
    public var onChangeTrackVisibility: (CallParticipant, Bool) -> Void

    private var viewId: String { participant.id + (!viewIdSuffix.isEmpty ? "-\(viewIdSuffix)" : "") }

    public init(
        viewFactory: Factory,
        participant: CallParticipant,
        viewIdSuffix: String,
        call: Call?,
        availableFrame: CGRect,
        onChangeTrackVisibility: @escaping (CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.participant = participant
        self.viewIdSuffix = viewIdSuffix
        self.call = call
        self.availableFrame = availableFrame
        self.onChangeTrackVisibility = onChangeTrackVisibility
    }

    public var body: some View {
        viewFactory.makeVideoParticipantView(
            participant: participant,
            id: viewId,
            availableFrame: availableFrame,
            contentMode: .scaleAspectFill,
            customData: [:],
            call: call
        )
        .modifier(
            viewFactory.makeVideoCallParticipantModifier(
                participant: participant,
                call: call,
                availableFrame: availableFrame,
                ratio: availableFrame.width / availableFrame.height,
                showAllInfo: true
            )
        )
        .modifier(ParticipantChangeModifier(
            participant: participant,
            onChangeTrackVisibility: onChangeTrackVisibility)
        )
        .visibilityObservation(in: availableFrame) { onChangeTrackVisibility(participant, $0) }
    }
}
