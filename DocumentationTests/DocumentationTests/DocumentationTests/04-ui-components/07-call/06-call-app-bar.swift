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
        struct CustomView: View {
            var callInfo: IncomingCall

            var body: some View {
                CallTopView(viewModel: viewModel)
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            public func makeCallTopView(options: CallTopViewOptions) -> some View {
                CustomCallTopView(viewModel: options.viewModel)
            }
        }
    }
}
