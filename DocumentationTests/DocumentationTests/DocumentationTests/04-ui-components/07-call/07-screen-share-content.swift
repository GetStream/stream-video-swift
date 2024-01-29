import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine

@MainActor
fileprivate func content() {
    container {
        @MainActor
        func custom(screensharingSession: ScreenSharingSession) {
            ScreenSharingView(
                viewModel: viewModel,
                screenSharing: screensharingSession,
                availableFrame: availableFrame
            )
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            public func makeScreenSharingView(
                viewModel: CallViewModel,
                screensharingSession: ScreenSharingSession,
                availableFrame: CGRect
            ) -> some View {
                CustomScreenSharingView(
                    viewModel: viewModel,
                    screenSharing: screensharingSession,
                    availableFrame: availableFrame
                )
            }
        }
    }
}
