//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

public struct WaitingLocalUserView<Factory: ViewFactory>: View {

    @Injected(\.appearance) var appearance

    var viewModel: CallViewModel
    var viewFactory: Factory

    @State var callingState: CallingState
    var callingStatePublisher: AnyPublisher<CallingState, Never>

    public init(viewModel: CallViewModel, viewFactory: Factory) {
        self.viewModel = viewModel
        self.viewFactory = viewFactory

        callingState = viewModel.callingState
        callingStatePublisher = viewModel
            .$callingState
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    public var body: some View {
        contentView
            .background(backgroundView)
            .onReceive(callingStatePublisher) { callingState = $0 }
            .debugViewRendering()
    }

    @ViewBuilder
    var contentView: some View {
        VStack {
            headerView
            middleView
                .padding(.horizontal, 8)
            footerView
        }
        .presentParticipantListView(viewFactory: viewFactory, viewModel: viewModel)
    }

    @ViewBuilder
    var headerView: some View {
        if callingState != .reconnecting {
            viewFactory.makeCallTopView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    var middleView: some View {
        if callingState != .reconnecting, let localParticipant = viewModel.localParticipant {
            GeometryReader { proxy in
                LocalVideoView(
                    viewFactory: viewFactory,
                    participant: localParticipant,
                    idSuffix: "waiting",
                    callSettings: viewModel.callSettings,
                    call: viewModel.call,
                    availableFrame: proxy.frame(in: .global)
                )
                .modifier(viewFactory.makeLocalParticipantViewModifier(
                    localParticipant: localParticipant,
                    callSettings: .init(get: { viewModel.callSettings }, set: { viewModel.callSettings = $0 }),
                    call: viewModel.call
                ))
            }
        } else {
            Spacer()
        }
    }

    @ViewBuilder
    var footerView: some View {
        if callingState != .reconnecting {
            viewFactory.makeCallControlsView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    var backgroundView: some View {
        DefaultBackgroundGradient()
            .edgesIgnoringSafeArea(.all)
    }
}
