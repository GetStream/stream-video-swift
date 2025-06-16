//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct WaitingLocalUserView<Factory: ViewFactory>: View {

    @Injected(\.appearance) var appearance

    var viewModel: CallViewModel
    var viewFactory: Factory

    @State private var callingState: CallingState
    @State private var participant: CallParticipant?

    public init(viewModel: CallViewModel, viewFactory: Factory) {
        self.viewModel = viewModel
        self.viewFactory = viewFactory
        callingState = viewModel.callingState
        participant = viewModel.localParticipant
    }
    
    public var body: some View {
        VStack {
            headerView
            centerView
            footerView
        }
        .background(DefaultBackgroundGradient().edgesIgnoringSafeArea(.all))
        .presentParticipantListView(viewModel: viewModel, viewFactory: viewFactory)
        .onReceive(viewModel.$callingState.removeDuplicates()) { callingState = $0 }
        .onReceive(viewModel.call?.state.$localParticipant.removeDuplicates(by: { $0?.sessionId == $1?.sessionId })) {
            participant = $0
        }
    }

    @ViewBuilder
    private var headerView: some View {
        if callingState != .reconnecting {
            viewFactory.makeCallTopView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var centerView: some View {
        if callingState != .reconnecting, let localParticipant = participant {
            GeometryReader { proxy in
                viewFactory.makeVideoParticipantView(
                    participant: localParticipant,
                    id: localParticipant.sessionId,
                    availableFrame: proxy.frame(in: .global),
                    contentMode: .scaleAspectFill,
                    customData: ["videoOn": .bool(viewModel.callSettings.videoOn)],
                    call: viewModel.call
                )
                .adjustVideoFrame(
                    to: proxy.frame(in: .global).width,
                    ratio: proxy.frame(in: .global).width / proxy.frame(in: .global).height
                )
                .modifier(viewFactory.makeLocalParticipantViewModifier(
                    localParticipant: localParticipant,
                    callSettings: .init(get: { viewModel.callSettings }, set: { viewModel.callSettings = $0 }),
                    call: viewModel.call
                ))
            }
            .padding(.horizontal, 8)
        } else {
            Spacer()
        }
    }

    @ViewBuilder
    private var footerView: some View {
        if callingState != .reconnecting {
            viewFactory.makeCallControlsView(viewModel: viewModel)
        }
    }
}
