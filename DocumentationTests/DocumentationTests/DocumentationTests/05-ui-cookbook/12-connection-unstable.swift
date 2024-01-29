import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine

@MainActor
fileprivate func content() {
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
