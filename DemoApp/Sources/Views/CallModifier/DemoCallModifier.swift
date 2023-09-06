//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

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
    }

    func body(content: Content) -> some View {
        VideoViewOverlay(
            rootView: content,
            viewFactory: viewFactory,
            viewModel: viewModel
        )
        .environment(\.chatViewModel, chatViewModel)
    }
}
