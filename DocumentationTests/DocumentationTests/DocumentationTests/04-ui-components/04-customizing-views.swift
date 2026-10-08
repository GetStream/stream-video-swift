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
        class CustomViewFactory: ViewFactory {

            func makeOutgoingCallView(options: OutgoingCallViewOptions) -> some View {
                CustomOutgoingCallView(viewModel: options.viewModel)
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
