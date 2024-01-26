import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine

@MainActor
fileprivate func content() {
    viewContainer {
        LocalVideoView(
            viewFactory: viewFactory,
            participant: localParticipant,
            callSettings: viewModel.callSettings,
            call: viewModel.call,
            availableFrame: availableFrame
        )
    }

    viewContainer {
        CornerDraggableView(
            content: { availableFrame in
                LocalVideoView(
                    viewFactory: viewFactory,
                    participant: localParticipant,
                    callSettings: viewModel.callSettings,
                    call: viewModel.call,
                    availableFrame: availableFrame
                )
            },
            proxy: reader
        ) {
            withAnimation {
                if participants.count == 1 {
                    viewModel.localVideoPrimary.toggle()
                }
            }
        }
    }
}
