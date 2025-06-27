//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoVideoViewOverlay<RootView: View, Factory: ViewFactory>: View {
    
    var rootView: RootView
    var viewFactory: Factory
    var viewModel: CallViewModel

    public init(
        rootView: RootView,
        viewFactory: Factory,
        viewModel: CallViewModel
    ) {
        self.rootView = rootView
        self.viewFactory = viewFactory
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack {
            rootView
            DemoCallContainer(viewFactory: viewFactory, viewModel: viewModel)
        }
    }
}

struct DemoCallContainer<Factory: ViewFactory>: View {
    
    @Injected(\.appearance) private var appearance
    
    var viewFactory: Factory
    var viewModel: CallViewModel

    @State var call: Call?
    var callPublisher: AnyPublisher<Call?, Never>

    public init(
        viewFactory: Factory,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel

        call = viewModel.call
        callPublisher = viewModel
            .$call
            .removeDuplicates(by: { $0?.cId == $1?.cId })
            .eraseToAnyPublisher()
    }
    
    public var body: some View {
        Group {
            if
                let call = viewModel.call,
                call.callType == .livestream {
                ZStack {
                    if call.state.backstage == true {
                        VStack {
                            viewFactory.makeCallTopView(viewModel: viewModel)
                            Spacer()
                        }
                    }
                    
                    LivestreamPlayer(
                        viewFactory: viewFactory,
                        type: call.callType,
                        id: call.callId,
                        joinPolicy: .none,
                        showsLeaveCallButton: true,
                        onFullScreenStateChange: { [weak viewModel] in viewModel?.hideUIElements = $0 }
                    )
                }
                .toastView(toast: .init(get: { viewModel.toast }, set: { viewModel.toast = $0 }))
                .background(appearance.colors.lobbyBackground)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                CallContainer(viewFactory: viewFactory, viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(callPublisher) { call = $0 }
    }
}
