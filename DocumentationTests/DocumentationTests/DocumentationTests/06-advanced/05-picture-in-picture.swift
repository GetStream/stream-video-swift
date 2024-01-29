import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine

@MainActor
fileprivate func content() {
    container {
        struct CallView<Factory: ViewFactory>: View {
            @ObservedObject var viewModel: CallViewModel

            public var body: some View {
                YourHostView()
                    .enablePictureInPicture(viewModel.isPictureInPictureEnabled)
            }
        }
    }
}
