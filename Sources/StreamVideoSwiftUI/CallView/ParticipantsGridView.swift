//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamWebRTC
import SwiftUI

@MainActor
struct ParticipantsGridView<Factory: ViewFactory>: View {

    var viewFactory: Factory
    var call: Call?
    var participants: [CallParticipant]
    var availableFrame: CGRect
    var isPortrait: Bool
    var participantVisibilityChanged: (CallParticipant, Bool) -> Void
    var innerItemSpace: CGFloat = 8

    private var itemSize: CGSize = .zero
    private var itemRatio: CGFloat = 0

    init(
        viewFactory: Factory,
        call: Call?,
        participants: [CallParticipant],
        availableFrame: CGRect,
        isPortrait: Bool,
        innerItemSpace: CGFloat = 8,
        participantVisibilityChanged: @escaping (CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.call = call
        self.participants = participants
        self.availableFrame = availableFrame
        self.isPortrait = isPortrait
        self.participantVisibilityChanged = participantVisibilityChanged
        self.innerItemSpace = innerItemSpace

        itemSize = {
            if #available(iOS 14.0, *) {
                let itemsInRow: CGFloat = isPortrait ? 2 : 3
                let itemsInColumn: CGFloat = isPortrait ? 3 : 2
                let width = (availableFrame.width - ((itemsInRow - 1) * innerItemSpace)) / itemsInRow
                let height = (availableFrame.height - ((itemsInColumn - 1) * innerItemSpace)) / itemsInColumn
                /// We are using floor for width as on different devices/orientations the dimensions may be
                /// fractions that causing the LazyVStack to break the layout.
                return CGSize(width: floor(width), height: floor(height))
            } else {
                return CGSize(width: availableFrame.width, height: (availableFrame.height / 2) - innerItemSpace)
            }
        }()

        itemRatio = itemSize.width / itemSize.height
    }

    var body: some View {
        ScrollView {
            if #available(iOS 14.0, *) {
                LazyVGrid(
                    columns: [
                        .init(.adaptive(minimum: itemSize.width), spacing: innerItemSpace)
                    ]
                ) {
                    participantsContent(availableFrame)
                }
            } else {
                VStack(spacing: innerItemSpace) {
                    participantsContent(availableFrame)
                }
            }
        }
        .frame(width: availableFrame.width)
        .accessibility(identifier: "gridScrollView")
    }

    @ViewBuilder
    private func participantsContent(_ bounds: CGRect) -> some View {
        ForEach(participants) { participant in
            viewFactory.makeVideoParticipantView(
                participant: participant,
                id: participant.id,
                availableFrame: .init(origin: .zero, size: itemSize),
                contentMode: .scaleAspectFill,
                customData: [:],
                call: call
            )
            .modifier(
                viewFactory.makeVideoCallParticipantModifier(
                    participant: participant,
                    call: call,
                    availableFrame: .init(origin: .zero, size: itemSize),
                    ratio: itemRatio,
                    showAllInfo: true
                )
            )
            .visibilityObservation(in: bounds) {
                log.debug("Participant \(participant.name) is \($0 ? "visible" : "not visible.")")
                participantVisibilityChanged(participant, $0)
            }
        }
    }
}
