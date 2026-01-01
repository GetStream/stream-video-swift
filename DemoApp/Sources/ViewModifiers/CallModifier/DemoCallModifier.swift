//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoCallModifier<Factory: ViewFactory>: ViewModifier {

    @Injected(\.appearance) private var appearance

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
            .modifier(ThermalStateViewModifier())
    }

    @MainActor
    @ViewBuilder
    private func contentView(_ rootView: Content) -> some View {
        DemoVideoViewOverlay(
            rootView: rootView,
            viewFactory: viewFactory,
            viewModel: viewModel
        )
    }
}
