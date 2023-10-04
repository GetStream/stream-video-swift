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
    var availableSize: CGSize
    var isPortrait: Bool
    var participantVisibilityChanged: (CallParticipant, Bool) -> Void

    var body: some View {
        GeometryReader { geometryProxy in
            ScrollView {
                if #available(iOS 14.0, *) {
                    LazyVGrid(
                        columns: [
                            .init(.adaptive(minimum: size.width, maximum: size.width), spacing: 0)
                        ],
                        spacing: 0
                    ) {
                        participantsContent(geometryProxy.frame(in: .global))
                    }
                    .frame(width: availableSize.width)
                } else {
                    VStack {
                        participantsContent(geometryProxy.frame(in: .global))
                    }
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
                availableSize: size,
                contentMode: .scaleAspectFill,
                customData: [:],
                call: call
            )
            .modifier(
                viewFactory.makeVideoCallParticipantModifier(
                    participant: participant,
                    call: call,
                    availableSize: size,
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
            let width = availableSize.width / 2
            let height = availableSize.height / 3
            return width / height
        } else {
            let width = availableSize.width / 3
            let height = availableSize.height / 2
            return width / height
        }
    }

    private var size: CGSize {
        if #available(iOS 14.0, *) {
            let dividerWidth: CGFloat = isPortrait ? 2 : 3
            let dividerHeight: CGFloat = isPortrait ? 3 : 2
            return CGSize(width: availableSize.width / dividerWidth, height: availableSize.height / dividerHeight)
        } else {
            return CGSize(width: availableSize.width, height: availableSize.height / 2)
        }
    }
}
