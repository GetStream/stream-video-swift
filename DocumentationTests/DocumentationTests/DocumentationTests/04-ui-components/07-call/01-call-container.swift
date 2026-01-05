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
            @StateObject var viewModel = CallViewModel()

            public var body: some View {
                ZStack {
                    YourRootView()
                    CallContainer(viewFactory: CustomViewFactory(), viewModel: viewModel)
                }
            }
        }
    }

    container {
        CallContainer(viewFactory: DefaultViewFactory.shared, viewModel: viewModel)
    }

    container {
        struct CustomView: View {
            @StateObject var viewModel = CallViewModel()

            var body: some View {
                YourRootView()
                    .modifier(CallModifier(viewModel: viewModel))
            }
        }
    }

    container {
        struct CustomView: View {
            @StateObject var viewModel = CallViewModel()

            var body: some View {
                YourRootView()
                    .modifier(CallModifier(viewFactory: CustomViewFactory(), viewModel: viewModel))
            }
        }
    }
}
