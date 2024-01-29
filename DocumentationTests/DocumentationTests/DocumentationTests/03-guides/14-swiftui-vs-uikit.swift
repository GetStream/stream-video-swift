import StreamVideo
import StreamVideoSwiftUI
import StreamVideoUIKit
import SwiftUI
import Combine

@MainActor
fileprivate func content() {

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
            var selectedParticipants: [MemberRequest] = []
            var text = ""

            private func didTapStartButton() {
                let next = CallViewController.make(with: callViewModel)
                next.modalPresentationStyle = .fullScreen
                next.startCall(callType: "default", callId: text, members: selectedParticipants)
                self.navigationController?.present(next, animated: true)
            }
        }
    }
}
