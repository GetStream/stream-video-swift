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
