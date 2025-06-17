//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct WaitingLocalUserView<Factory: ViewFactory>: View {

    @Injected(\.appearance) var appearance

    @ObservedObject var viewModel: CallViewModel
    var viewFactory: Factory
    
    public init(viewModel: CallViewModel, viewFactory: Factory) {
        self.viewModel = viewModel
        self.viewFactory = viewFactory
    }
    
    public var body: some View {
        ZStack {
            DefaultBackgroundGradient()
                .edgesIgnoringSafeArea(.all)

            VStack {
                viewFactory.makeCallTopView(viewModel: viewModel)
                    .opacity(viewModel.callingState == .reconnecting ? 0 : 1)

                Group {
                    if let localParticipant = viewModel.localParticipant {
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
                                callSettings: $viewModel.callSettings,
                                call: viewModel.call
                            ))
                        }
                    } else {
                        Spacer()
                    }
                }
                .padding(.horizontal, 8)
                .opacity(viewModel.callingState == .reconnecting ? 0 : 1)

                viewFactory.makeCallControlsView(viewModel: viewModel)
                    .opacity(viewModel.callingState == .reconnecting ? 0 : 1)
            }
            .presentParticipantListView(viewModel: viewModel, viewFactory: viewFactory)
        }
        .debugViewRendering()
    }
}
