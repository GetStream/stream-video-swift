//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
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

            public func makeScreenSharingView(options: ScreenSharingViewOptions) -> some View {
                CustomScreenSharingView(
                    viewModel: options.viewModel,
                    screenSharing: options.screenSharingSession,
                    availableFrame: options.availableFrame
                )
            }
        }
    }
}
