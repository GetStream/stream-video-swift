import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine

@MainActor
fileprivate func content() {
    container {
        struct CustomView: View {
            var callInfo: IncomingCall

            var body: some View {
                CallTopView(viewModel: viewModel)
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            public func makeCallTopView(viewModel: CallViewModel) -> some View {
                CustomCallTopView(viewModel: viewModel)
            }
        }
    }
}
