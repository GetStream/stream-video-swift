//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct ParticipantsSpotlightLayout<Factory: ViewFactory>: View {
    var viewFactory: Factory
    var participant: CallParticipant
    var participants: [CallParticipant]
    var frame: CGRect
    var call: Call?
    var innerItemSpace: CGFloat
    var onChangeTrackVisibility: @MainActor (CallParticipant, Bool) -> Void
    
    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        participant: CallParticipant,
        call: Call?,
        participants: [CallParticipant],
        frame: CGRect,
        innerItemSpace: CGFloat = 8,
        onChangeTrackVisibility: @escaping @MainActor (CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.participant = participant
        self.participants = participants
        self.frame = frame
        self.call = call
        self.innerItemSpace = innerItemSpace
        self.onChangeTrackVisibility = onChangeTrackVisibility
    }

    public var body: some View {
        VStack(spacing: innerItemSpace) {
            GeometryReader { proxy in
                SpotlightSpeakerView(
                    viewFactory: viewFactory,
                    participant: participant,
                    viewIdSuffix: "spotlight",
                    call: call,
                    availableFrame: proxy.frame(in: .global)
                )
            }

            HorizontalParticipantsListView(
                viewFactory: viewFactory,
                participants: participants,
                frame: participantsStripFrame,
                call: call,
                showAllInfo: true
            )
        }
    }
    
    private var topParticipantFrame: CGRect {
        /// Top
        .init(
            origin: frame.origin,
            size: CGSize(width: frame.size.width, height: frame.height - participantsStripFrame.height - innerItemSpace)
        )
    }

    private var participantsStripFrame: CGRect {
        let barHeight = frame.height / 4
        let barY = frame.maxY - barHeight
        return CGRect(
            x: frame.origin.x,
            y: barY,
            width: frame.width,
            height: barHeight
        )
    }

    private var topParticipantRatio: CGFloat {
        topParticipantFrame.size.width / topParticipantFrame.size.height
    }
}
