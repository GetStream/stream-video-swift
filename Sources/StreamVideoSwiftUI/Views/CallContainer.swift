//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

public struct CallContainer<Factory: ViewFactory>: View {
    
    @Injected(\.utils) var utils
    
    var viewFactory: Factory
    var viewModel: CallViewModel
    var padding: CGFloat = 16

    @State var callingState: CallingState
    var callingStatePublisher: AnyPublisher<CallingState, Never>

    @State var hasParticipants: Bool
    var hasParticipantsPublisher: AnyPublisher<Bool, Never>

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel

        callingState = viewModel.callingState
        callingStatePublisher = viewModel
            .$callingState
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        hasParticipants = viewModel.callParticipants.count > 1
        hasParticipantsPublisher = viewModel
            .$callParticipants
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .map(\.count)
            .map { $0 > 1 }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    public var body: some View {
        Group {
            if shouldShowCallView {
                if hasParticipants {
                    if viewModel.isMinimized {
                        viewFactory.makeMinimizedCallView(viewModel: viewModel)
                    } else {
                        viewFactory.makeCallView(viewModel: viewModel)
                    }
                } else {
                    viewFactory.makeWaitingLocalUserView(viewModel: viewModel)
                }
            } else if callingState == .reconnecting {
                viewFactory.makeReconnectionView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toastView(toast: .init(get: { viewModel.toast }, set: { viewModel.toast = $0 }))
        .overlay(overlayView)
        .onReceive(callingStatePublisher) {
            if $0 == .idle || $0 == .inCall {
                utils.callSoundsPlayer.stopOngoingSound()
            }
            callingState = $0
        }
        .onReceive(hasParticipantsPublisher) { hasParticipants = $0 }
        .debugViewRendering()
    }
    
    @ViewBuilder
    private var overlayView: some View {
        if case let .incoming(callInfo) = callingState {
            viewFactory.makeIncomingCallView(viewModel: viewModel, callInfo: callInfo)
        } else if callingState == .outgoing {
            viewFactory.makeOutgoingCallView(viewModel: viewModel)
        } else if callingState == .joining {
            viewFactory.makeJoiningCallView(viewModel: viewModel)
        } else if case let .lobby(lobbyInfo) = callingState {
            viewFactory.makeLobbyView(
                viewModel: viewModel,
                lobbyInfo: lobbyInfo,
                callSettings: .init(get: { viewModel.callSettings }, set: { viewModel.callSettings = $0 })
            )
        } else {
            EmptyView()
        }
    }
    
    private var shouldShowCallView: Bool {
        switch callingState {
        case .outgoing, .incoming(_), .inCall, .joining, .lobby:
            return true
        default:
            return false
        }
    }
}
