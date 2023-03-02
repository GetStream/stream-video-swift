//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS, introduced: 13, obsoleted: 14)
public struct VideoView_iOS13<Factory: ViewFactory>: View {
    
    @Injected(\.utils) var utils
    
    var viewFactory: Factory
    @BackportStateObject var viewModel: CallViewModel
    
    private let padding: CGFloat = 16
    
    public init(viewFactory: Factory, viewModel: CallViewModel) {
        self.viewFactory = viewFactory
        _viewModel = BackportStateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            if shouldShowCallView {
                if !viewModel.participants.isEmpty {
                    if viewModel.isMinimized {
                        MinimizedCallView(viewModel: viewModel)
                    } else {
                        viewFactory.makeCallView(viewModel: viewModel)
                    }
                } else {
                    WaitingLocalUserView(viewModel: viewModel, viewFactory: viewFactory)
                }
            } else if case let .waitingRoom(waitingRoomInfo) = viewModel.callingState {
                viewFactory.makePreJoiningView(viewModel: viewModel, waitingRoomInfo: waitingRoomInfo)
            }
        }
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
        } else {
            EmptyView()
        }
    }
    
    private var shouldShowCallView: Bool {
        switch viewModel.callingState {
        case .outgoing, .incoming(_), .inCall:
            return true
        default:
            return false
        }
    }
}
