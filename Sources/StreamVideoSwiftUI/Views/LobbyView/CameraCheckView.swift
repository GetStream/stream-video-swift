//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

struct CameraCheckView<Factory: ViewFactory>: View {

    @Injected(\.images) var images
    @Injected(\.colors) var colors
    @Injected(\.streamVideo) var streamVideo

    var viewFactory: Factory
    var viewModel: LobbyViewModel

    init(
        viewFactory: Factory,
        viewModel: LobbyViewModel
    ) {
        self.viewModel = viewModel
        self.viewFactory = viewFactory
    }

    var body: some View {
        contentView
            .overlay(overlayView)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .debugViewRendering()
    }

    @ViewBuilder
    var contentView: some View {
        CameraFeedPreviewView(viewFactory: viewFactory, viewModel: viewModel)
    }

    @ViewBuilder
    var overlayView: some View {
        BottomView {
            HStack {
                MicrophoneCheckView(viewModel: viewModel, isPinned: false)
                    .accessibility(identifier: "microphoneCheckView")
                Spacer()
            }
        }
    }
}
