//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS, introduced: 13, obsoleted: 14)
public struct CallContainer_iOS13<Factory: ViewFactory>: View {
    
    @Injected(\.utils) var utils
    
    var viewFactory: Factory
    @BackportStateObject var viewModel: CallViewModel
    
    private let padding: CGFloat = 16
    
    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        _viewModel = BackportStateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        Group {
            if shouldShowCallView {
                if viewModel.callParticipants.count > 1 {
                    if viewModel.isMinimized {
                        viewFactory.makeMinimizedCallView(viewModel: viewModel)
                    } else {
                        viewFactory.makeCallView(viewModel: viewModel)
                    }
                } else {
                    viewFactory.makeWaitingLocalUserView(viewModel: viewModel)
                }
            } else if viewModel.callingState == .reconnecting {
                viewFactory.makeReconnectionView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toastView(toast: $viewModel.toast)
        .overlay(overlayView)
        .onReceive(viewModel.$callingState) { _ in
            if viewModel.callingState == .idle || viewModel.callingState == .inCall {
                utils.callSoundsPlayer.stopOngoingSound()
            }
        }
    }

    @ViewBuilder
    private var overlayView: some View {
        if case let .incoming(callInfo) = viewModel.callingState {
            viewFactory.makeIncomingCallView(viewModel: viewModel, callInfo: callInfo)
        } else if viewModel.callingState == .outgoing {
            viewFactory.makeOutgoingCallView(viewModel: viewModel)
        } else if viewModel.callingState == .joining {
            viewFactory.makeJoiningCallView(viewModel: viewModel)
        } else if case let .lobby(lobbyInfo) = viewModel.callingState {
            viewFactory.makeLobbyView(
                viewModel: viewModel,
                lobbyInfo: lobbyInfo,
                callSettings: $viewModel.callSettings
            )
        } else {
            EmptyView()
        }
    }

    private var shouldShowCallView: Bool {
        switch viewModel.callingState {
        case .outgoing, .incoming(_), .inCall, .joining, .lobby:
            return true
        default:
            return false
        }
    }
}
