//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

public struct ParticipantsSpotlightLayout<Factory: ViewFactory>: View {
    var viewFactory: Factory
    var participant: CallParticipant
    var frame: CGRect
    var call: Call?
    var innerItemSpace: CGFloat
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void

    @State var participants: [CallParticipant]
    var participantsPublisher: AnyPublisher<[CallParticipant], Never>?

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        participant: CallParticipant,
        call: Call?,
        participants: [CallParticipant],
        frame: CGRect,
        innerItemSpace: CGFloat = 8,
        onChangeTrackVisibility: @escaping @MainActor(CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.participant = participant
        self.participants = participants
        self.frame = frame
        self.call = call
        self.innerItemSpace = innerItemSpace
        self.onChangeTrackVisibility = onChangeTrackVisibility

        participantsPublisher = call?
            .state
            .$participants
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .map { value in value.filter { $0.sessionId != participant.sessionId } }
            .removeDuplicates(by: { lhs, rhs in
                let lhsSessionIds = lhs.map(\.sessionId)
                let rhsSessionIds = rhs.map(\.sessionId)
                return lhsSessionIds == rhsSessionIds
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
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
            .onReceive(participantsPublisher) { participants = $0 }
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
