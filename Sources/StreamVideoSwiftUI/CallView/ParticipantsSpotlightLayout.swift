//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct ParticipantsSpotlightLayout<Factory: ViewFactory>: View {
    private let thumbnailSize: CGFloat = 120

    var viewFactory: Factory
    var participant: CallParticipant
    var participants: [CallParticipant]
    var frame: CGRect
    var call: Call?
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    public init(
        viewFactory: Factory,
        participant: CallParticipant,
        call: Call?,
        participants: [CallParticipant],
        frame: CGRect,
        onChangeTrackVisibility: @escaping @MainActor (CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.participant = participant
        self.participants = participants
        self.frame = frame
        self.call = call
        self.onChangeTrackVisibility = onChangeTrackVisibility
    }

    public var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                viewFactory.makeDominantSpeakerLayoutComponent(
                    participant: participant,
                    viewIdSuffix: "spotlight",
                    availableFrame: proxy.frame(in: .global),
                    call: call,
                    onChangeTrackVisibility: { onChangeTrackVisibility($0, $1) }
                )
            }

            viewFactory.makeBottomParticipantsBarLayoutComponent(
                participants: participants,
                availableFrame: participantsStripFrame,
                call: call,
                onChangeTrackVisibility: { onChangeTrackVisibility($0, $1) }
            )
        }
    }
    
    private var topParticipantFrame: CGRect {
        .init(
            origin: frame.origin,
            size: CGSize(width: frame.size.width, height: frame.size.height - thumbnailSize)
        )
    }

    private var participantsStripFrame: CGRect {
        .init(
            origin: .init(x: frame.origin.x, y: frame.maxY - thumbnailSize),
            size: CGSize(width: frame.size.width, height: thumbnailSize)
        )
    }

    private var topParticipantRatio: CGFloat {
        topParticipantFrame.size.width / topParticipantFrame.size.height
    }
}
