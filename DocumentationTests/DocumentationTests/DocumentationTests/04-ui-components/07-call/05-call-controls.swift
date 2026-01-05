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

            public var body: some View {
                CallControlsView(viewModel: viewModel)
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            public func makeCallControlsView(viewModel: CallViewModel) -> some View {
                CustomCallControlsView(viewModel: viewModel)
            }
        }
    }

    container {
        struct CustomCallControlsView: View {

            @ObservedObject var viewModel: CallViewModel

            var body: some View {
                HStack(spacing: 32) {
                    VideoIconView(viewModel: viewModel)
                    MicrophoneIconView(viewModel: viewModel)
                    ToggleCameraIconView(viewModel: viewModel)
                    HangUpIconView(viewModel: viewModel)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 85)
            }
        }
    }
}
