//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct VerticalParticipantsView<Factory: ViewFactory>: View {
            
    var viewFactory: Factory
    var call: Call?
    var participants: [CallParticipant]
    var availableFrame: CGRect
    var innerItemSpace: CGFloat = 8
    var includeSpacer: Bool = false
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void

    var body: some View {
        VStack(spacing: innerItemSpace) {
            ForEach(participants) { participant in
                viewFactory.makeVideoParticipantView(
                    participant: participant,
                    id: participant.id,
                    availableFrame: itemFrame,
                    contentMode: .scaleAspectFill,
                    customData: [:],
                    call: call
                )
                .modifier(
                    viewFactory.makeVideoCallParticipantModifier(
                        participant: participant,
                        call: call,
                        availableFrame: itemFrame,
                        ratio: ratio,
                        showAllInfo: true
                    )
                )
                .onAppear {
                    onChangeTrackVisibility(participant, true)
                }
            }

            if includeSpacer {
                Spacer()
                    .frame(maxHeight: .infinity)
            }
        }
    }
    
    private var ratio: CGFloat {
        itemFrame.width / itemFrame.height
    }
    
    private var itemFrame: CGRect {
        let itemsCount = CGFloat(includeSpacer ? participants.count + 1 : participants.count)
        return .init(
            origin: availableFrame.origin,
            size: .init(
                width: availableFrame.width,
                height: (availableFrame.height - ((itemsCount - 1) * innerItemSpace)) / itemsCount
            )
        )
    }
}
