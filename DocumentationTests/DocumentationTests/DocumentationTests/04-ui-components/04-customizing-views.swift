import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine

@MainActor
fileprivate func content() {
    container {
        class CustomViewFactory: ViewFactory {

            func makeOutgoingCallView(viewModel: CallViewModel) -> some View {
                CustomOutgoingCallView(viewModel: viewModel)
            }
        }
    }

    container {
        struct CustomView: View {
            var body: some View {
                YourHostingView()
                    .modifier(CallModifier(viewFactory: CustomViewFactory(), viewModel: viewModel))
            }
        }
    }
}
