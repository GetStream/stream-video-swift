//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    viewContainer {
        VideoParticipantsView(
            viewFactory: DefaultViewFactory.shared,
            viewModel: viewModel,
            availableFrame: availableFrame,
            onChangeTrackVisibility: onChangeTrackVisibility
        )
    }

    container {
        class CustomViewFactory: ViewFactory {

            public func makeVideoParticipantsView(
                viewModel: CallViewModel,
                availableFrame: CGRect,
                onChangeTrackVisibility: @escaping @MainActor (CallParticipant, Bool) -> Void
            ) -> some View {
                CustomVideoParticipantsView(
                    viewFactory: self,
                    viewModel: viewModel,
                    availableFrame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            }
        }
    }

    viewContainer {
        ParticipantsGridLayout(
            viewFactory: viewFactory,
            call: viewModel.call,
            participants: viewModel.participants,
            availableFrame: availableFrame,
            onChangeTrackVisibility: onChangeTrackVisibility
        )
    }

    viewContainer {
        let first: CallParticipant = participant

        ParticipantsSpotlightLayout(
            viewFactory: viewFactory,
            participant: first,
            call: viewModel.call,
            participants: Array(viewModel.participants.dropFirst()),
            frame: availableFrame,
            onChangeTrackVisibility: onChangeTrackVisibility
        )
    }

    viewContainer {
        let first: CallParticipant = participant
        
        ParticipantsFullScreenLayout(
            viewFactory: viewFactory,
            participant: first,
            call: viewModel.call,
            frame: availableFrame,
            onChangeTrackVisibility: onChangeTrackVisibility
        )
    }
}
