//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamWebRTC
import SwiftUI

public struct VideoParticipantsView<Factory: ViewFactory>: View {
    
    var viewFactory: Factory
    @ObservedObject var viewModel: CallViewModel
    var availableFrame: CGRect
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel,
        availableFrame: CGRect,
        onChangeTrackVisibility: @escaping @MainActor(CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
        self.availableFrame = availableFrame
        self.onChangeTrackVisibility = onChangeTrackVisibility
    }
    
    public var body: some View {
        ZStack {
            if viewModel.participantsLayout == .fullScreen, let first = viewModel.participants.first {
                ParticipantsFullScreenLayout(
                    viewFactory: viewFactory,
                    participant: first,
                    call: viewModel.call,
                    frame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else if viewModel.participantsLayout == .spotlight, let first = viewModel.participants.first {
                ParticipantsSpotlightLayout(
                    viewFactory: viewFactory,
                    participant: first,
                    call: viewModel.call,
                    participants: Array(viewModel.participants.dropFirst()),
                    frame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else {
                ParticipantsGridLayout(
                    viewFactory: viewFactory,
                    call: viewModel.call,
                    participants: viewModel.participants,
                    availableFrame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            }
        }
    }
}
