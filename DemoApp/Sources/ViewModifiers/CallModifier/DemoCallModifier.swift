//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoCallModifier<Factory: ViewFactory>: ViewModifier {

    var viewFactory: Factory
    var viewModel: CallViewModel
    var chatViewModel: DemoChatViewModel

    init(
        viewFactory: Factory,
        viewModel: CallViewModel,
        chatViewModel: DemoChatViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
        self.chatViewModel = chatViewModel

        InjectedValues[\.chatViewModel] = chatViewModel
    }

    func body(content: Content) -> some View {
        contentView(content)
    }

    @MainActor
    @ViewBuilder
    private func contentView(_ rootView: Content) -> some View {
        if
            let call = viewModel.call,
            call.callType == .livestream,
            (call.currentUserHasCapability(.sendAudio) == false) || (call.currentUserHasCapability(.sendVideo) == false) {
            ZStack {
                rootView
                LivestreamPlayer(
                    type: call.callType,
                    id: call.callId,
                    joinPolicy: .none,
                    showsLeaveCallButton: true,
                    onFullScreenStateChange: { [weak viewModel] in viewModel?.hideUIElements = $0 }
                )
            }
        } else {
            VideoViewOverlay(
                rootView: rootView,
                viewFactory: viewFactory,
                viewModel: viewModel
            )
            .modifier(ThermalStateViewModifier())
        }
    }
}
