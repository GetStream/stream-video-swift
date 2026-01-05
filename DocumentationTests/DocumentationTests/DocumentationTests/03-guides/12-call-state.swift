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
    viewContainer {
        ZStack {
            if viewModel.callingState == .outgoing {
                viewFactory.makeOutgoingCallView(viewModel: viewModel)
            } else if viewModel.callingState == .inCall {
                if !viewModel.participants.isEmpty {
                    if viewModel.isMinimized {
                        MinimizedCallView(viewModel: viewModel)
                    } else {
                        viewFactory.makeCallView(viewModel: viewModel)
                    }
                } else {
                    WaitingLocalUserView(viewModel: viewModel, viewFactory: viewFactory)
                }
            } else if case let .incoming(callInfo) = viewModel.callingState {
                viewFactory.makeIncomingCallView(viewModel: viewModel, callInfo: callInfo)
            }
        }
        .onReceive(viewModel.$callingState) { _ in
            if viewModel.callingState == .idle || viewModel.callingState == .inCall {
                utils.callSoundsPlayer.stopOngoingSound()
            }
        }
    }

    container {
        @MainActor
        class CallViewHelper {

            static let shared = CallViewHelper()

            private var callView: UIView?

            private init() {}

            func add(callView: UIView) {
                guard self.callView == nil else { return }
                guard let window = UIApplication.shared.windows.first else {
                    return
                }
                callView.isOpaque = false
                callView.backgroundColor = UIColor.clear
                self.callView = callView
                window.addSubview(callView)
            }

            func removeCallView() {
                callView?.removeFromSuperview()
                callView = nil
            }
        }

        final class CustomObject: UIViewController {

            var callViewModel: CallViewModel { viewModel }
            var cancellables: Set<AnyCancellable> = []

            @MainActor
            private func listenToIncomingCalls() {
                callViewModel.$callingState.sink { [weak self] newState in
                    guard let self = self else { return }
                    if case .incoming = newState, self == self.navigationController?.topViewController {
                        let next = CallViewController(viewModel: self.callViewModel)
                        CallViewHelper.shared.add(callView: next.view)
                    } else if newState == .idle {
                        CallViewHelper.shared.removeCallView()
                    }
                }
                .store(in: &cancellables)
            }
        }
    }
}
