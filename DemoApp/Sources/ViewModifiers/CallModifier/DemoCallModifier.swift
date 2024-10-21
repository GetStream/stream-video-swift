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
        VideoViewOverlay(
            rootView: content,
            viewFactory: viewFactory,
            viewModel: viewModel
        )
        .modifier(ThermalStateViewModifier(viewModel.call))
    }
}
