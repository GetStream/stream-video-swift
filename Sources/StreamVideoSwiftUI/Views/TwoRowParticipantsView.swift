//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct TwoRowParticipantsView<Factory: ViewFactory>: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    var viewFactory: Factory
    var call: Call?
    var firstRowParticipants: [CallParticipant]
    var secondRowParticipants: [CallParticipant]
    var availableFrame: CGRect
    var innerItemSpacing: CGFloat = 8
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HorizontalParticipantsView(
                viewFactory: viewFactory,
                call: call,
                participants: firstRowParticipants,
                availableFrame: bounds,
                onChangeTrackVisibility: onChangeTrackVisibility
            )
            
            HorizontalParticipantsView(
                viewFactory: viewFactory,
                call: call,
                participants: secondRowParticipants,
                availableFrame: bounds,
                onChangeTrackVisibility: onChangeTrackVisibility
            )
        }
        .frame(maxWidth: availableFrame.width, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
        .debugViewRendering()
    }
    
    private var bounds: CGRect {
        .init(
            origin: .zero,
            size: CGSize(width: availableFrame.width, height: availableFrame.height / 2)
        )
    }
}
