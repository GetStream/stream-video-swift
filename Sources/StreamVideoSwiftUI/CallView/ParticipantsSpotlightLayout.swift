//
// Copyright © 2023 Stream.io Inc. All rights reserved.
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
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    public init(
        viewFactory: Factory,
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
                itemsOnScreen: itemsVisibleOnScreen,
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

    private var itemsVisibleOnScreen: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return UIDevice.current.orientation == .portrait ? 3 : 4
        } else {
            return 2
        }
    }

    private var participantsStripFrame: CGRect {
        /// Each video tile has an aspect ratio of 3:4 with width as base. Given that each tile has the
        /// half width of the screen, the calculation below applies the aspect ratio to the expected width.
        let aspectRatio: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 9 / 16 : 3 / 4
        let barHeight = (frame.width / itemsVisibleOnScreen) * aspectRatio
        return .init(
            origin: .init(x: frame.origin.x, y: frame.maxY - barHeight),
            size: CGSize(width: frame.width, height: barHeight)
        )
    }

    private var topParticipantRatio: CGFloat {
        topParticipantFrame.size.width / topParticipantFrame.size.height
    }
}
