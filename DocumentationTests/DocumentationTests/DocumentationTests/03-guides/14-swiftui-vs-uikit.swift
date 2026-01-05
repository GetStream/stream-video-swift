//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import StreamVideoUIKit
import SwiftUI

@MainActor
private func content() {

    container {
        struct CallView: View {

            @StateObject var viewModel: CallViewModel

            init() {
                _viewModel = StateObject(wrappedValue: CallViewModel())
            }

            var body: some View {
                HomeView(viewModel: viewModel)
                    .modifier(CallModifier(viewModel: viewModel))
            }
        }
    }

    container {
        @MainActor
        final class CustomObject: UIViewController {
            var callViewModel: CallViewModel { viewModel }
            var selectedParticipants: [Member] = []
            var text = ""

            private func didTapStartButton() {
                let next = CallViewController(viewModel: callViewModel)
                next.modalPresentationStyle = .fullScreen
                next.startCall(callType: "default", callId: text, members: selectedParticipants)
                self.navigationController?.present(next, animated: true)
            }
        }
    }
}
