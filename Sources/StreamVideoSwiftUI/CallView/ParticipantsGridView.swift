//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import WebRTC

@MainActor
struct ParticipantsGridView<Factory: ViewFactory>: View {

    var viewFactory: Factory
    var call: Call?
    var participants: [CallParticipant]
    var availableFrame: CGRect
    var isPortrait: Bool
    var participantVisibilityChanged: (CallParticipant, Bool) -> Void

    var body: some View {
        ScrollView {
            if #available(iOS 14.0, *) {
                LazyVGrid(
                    columns: [
                        .init(.adaptive(minimum: size.width, maximum: size.width), spacing: 0)
                    ],
                    spacing: 0
                ) {
                    participantsContent(availableFrame)
                }
                .frame(width: availableFrame.width)
            } else {
                VStack {
                    participantsContent(availableFrame)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .accessibility(identifier: "gridScrollView")
    }

    @ViewBuilder
    private func participantsContent(_ bounds: CGRect) -> some View {
        ForEach(participants) { participant in
            viewFactory.makeVideoParticipantView(
                participant: participant,
                id: participant.id,
                availableFrame: .init(origin: .zero, size: size),
                contentMode: .scaleAspectFill,
                customData: [:],
                call: call
            )
            .modifier(
                viewFactory.makeVideoCallParticipantModifier(
                    participant: participant,
                    call: call,
                    availableFrame: .init(origin: .zero, size: size),
                    ratio: ratio,
                    showAllInfo: true
                )
            )
            .visibilityObservation(in: bounds) {
                log.debug("Participant \(participant.name) is \($0 ? "visible" : "not visible.")")
                participantVisibilityChanged(participant, $0)
            }
        }
    }

    var ratio: CGFloat {
        if isPortrait {
            let width = availableFrame.width / 2
            let height = availableFrame.height / 3
            return width / height
        } else {
            let width = availableFrame.width / 3
            let height = availableFrame.height / 2
            return width / height
        }
    }

    private var size: CGSize {
        if #available(iOS 14.0, *) {
            let dividerWidth: CGFloat = isPortrait ? 2 : 3
            let dividerHeight: CGFloat = isPortrait ? 3 : 2
            return CGSize(width: availableFrame.width / dividerWidth, height: availableFrame.height / dividerHeight)
        } else {
            return CGSize(width: availableFrame.width, height: availableFrame.height / 2)
        }
    }
}
