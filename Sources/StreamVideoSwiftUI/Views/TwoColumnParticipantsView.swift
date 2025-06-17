//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct TwoColumnParticipantsView<Factory: ViewFactory>: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    var viewFactory: Factory
    var call: Call?
    var leftColumnParticipants: [CallParticipant]
    var rightColumnParticipants: [CallParticipant]
    var availableFrame: CGRect
    var innerItemSpace: CGFloat = 8
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        HStack(spacing: innerItemSpace) {
            VerticalParticipantsView(
                viewFactory: viewFactory,
                call: call,
                participants: leftColumnParticipants,
                availableFrame: bounds,
                onChangeTrackVisibility: onChangeTrackVisibility
            )
            .adjustVideoFrame(to: bounds.width)

            VerticalParticipantsView(
                viewFactory: viewFactory,
                call: call,
                participants: rightColumnParticipants,
                availableFrame: bounds,
                includeSpacer: leftColumnParticipants.count > rightColumnParticipants.count,
                onChangeTrackVisibility: onChangeTrackVisibility
            )
            .adjustVideoFrame(to: bounds.width)
        }
        .frame(maxWidth: availableFrame.width, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }

    private var bounds: CGRect {
        CGRect(
            origin: .zero,
            size: CGSize(
                width: (availableFrame.size.width - innerItemSpace) / 2,
                height: availableFrame.size.height
            )
        )
    }
}
