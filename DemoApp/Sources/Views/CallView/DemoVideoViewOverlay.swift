//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoVideoViewOverlay<RootView: View, Factory: ViewFactory>: View {

    var rootView: RootView
    var viewFactory: Factory
    @StateObject var viewModel: CallViewModel

    public init(
        rootView: RootView,
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel
    ) {
        self.rootView = rootView
        self.viewFactory = viewFactory
        _viewModel = StateObject(wrappedValue: viewModel)
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
    @StateObject var viewModel: CallViewModel

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        Group {
            if
                let call = viewModel.call,
                call.callType == .livestream {
                LivestreamPlayer(
                    viewFactory: viewFactory,
                    type: call.callType,
                    id: call.callId,
                    joinPolicy: .none,
                    showsLeaveCallButton: true,
                    onFullScreenStateChange: { [weak viewModel] in viewModel?.hideUIElements = $0 }
                )
                .toastView(toast: $viewModel.toast)
                .background(appearance.colors.lobbyBackground)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                CallContainer(viewFactory: viewFactory, viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
