//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamWebRTC
import SwiftUI

public struct ParticipantsGridLayout<Factory: ViewFactory>: View {
    
    var viewFactory: Factory
    var call: Call?
    var participants: [CallParticipant]
    var availableFrame: CGRect
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void

    @ObservedObject private var orientationAdapter = InjectedValues[\.orientationAdapter]

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        call: Call?,
        participants: [CallParticipant],
        availableFrame: CGRect,
        onChangeTrackVisibility: @escaping @MainActor(CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.participants = participants
        self.availableFrame = availableFrame
        self.onChangeTrackVisibility = onChangeTrackVisibility
        self.call = call
    }
    
    public var body: some View {
        ZStack {
            if orientationAdapter.orientation.isPortrait {
                VideoParticipantsViewPortrait(
                    viewFactory: viewFactory,
                    call: call,
                    participants: participants,
                    availableFrame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else {
                VideoParticipantsViewLandscape(
                    viewFactory: viewFactory,
                    call: call,
                    participants: participants,
                    availableFrame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            }
        }
        .edgesIgnoringSafeArea(participants.count > 1 ? .bottom : .all)
        .debugViewRendering()
    }
}
