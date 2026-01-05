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
        YourView()
            .overlay(
                participant.connectionQuality == .poor ? Text("Your network connection is bad.") : nil
            )
    }

    container {
        class CustomViewFactory: ViewFactory {

            func makeReconnectionView(viewModel: CallViewModel) -> some View {
                ReconnectionView(viewModel: viewModel, viewFactory: self)
            }
        }
    }
}
