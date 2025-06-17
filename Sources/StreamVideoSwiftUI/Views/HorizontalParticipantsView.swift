//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct HorizontalParticipantsView<Factory: ViewFactory>: View {
            
    var viewFactory: Factory
    var call: Call?
    var participants: [CallParticipant]
    var availableFrame: CGRect
    var innerItemSpacing: CGFloat = 8
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void

    var body: some View {
        HStack(spacing: innerItemSpacing) {
            ForEach(participants) { participant in
                viewFactory.makeVideoParticipantView(
                    participant: participant,
                    id: participant.id,
                    availableFrame: bounds,
                    contentMode: .scaleAspectFill,
                    customData: [:],
                    call: call
                )
                .modifier(
                    viewFactory.makeVideoCallParticipantModifier(
                        participant: participant,
                        call: call,
                        availableFrame: bounds,
                        ratio: ratio,
                        showAllInfo: true
                    )
                )
                .onAppear {
                    onChangeTrackVisibility(participant, true)
                }
            }
        }
    }
    
    private var bounds: CGRect {
        .init(
            origin: .zero,
            size: CGSize(width: availableWidth, height: availableFrame.height)
        )
    }
    
    private var ratio: CGFloat {
        availableWidth / availableFrame.height
    }
    
    private var availableWidth: CGFloat {
        (availableFrame.width - totalInnerItemSpacing) / CGFloat(participants.count)
    }

    private var totalInnerItemSpacing: CGFloat {
        CGFloat(participants.endIndex - 1) * innerItemSpacing
    }
}
