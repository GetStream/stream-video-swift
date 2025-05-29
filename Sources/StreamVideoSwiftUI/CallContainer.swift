//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
public struct VideoViewOverlay<RootView: View, Factory: ViewFactory>: View {
    
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
            CallContainer(viewFactory: viewFactory, viewModel: viewModel)
        }
    }
}

@available(iOS 14.0, *)
public struct CallContainer<Factory: ViewFactory>: View {
    
    @Injected(\.utils) var utils
    
    var viewFactory: Factory
    @StateObject var viewModel: CallViewModel
    
    private let padding: CGFloat = 16
    
    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        _viewModel = StateObject(wrappedValue: viewModel)
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

public struct WaitingLocalUserView<Factory: ViewFactory>: View {

    @Injected(\.appearance) var appearance

    var viewModel: CallViewModel
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

                contentView

                viewFactory.makeCallControlsView(viewModel: viewModel)
                    .opacity(viewModel.callingState == .reconnecting ? 0 : 1)
            }
            .presentParticipantListView(viewModel: viewModel, viewFactory: viewFactory)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        PublisherSubscriptionView(
            initial: viewModel.callingState,
            publisher: viewModel.$callingState.eraseToAnyPublisher()
        ) { callingState in
            PublisherSubscriptionView(
                initial: viewModel.localParticipant,
                publisher: viewModel.call?.state.$localParticipant.eraseToAnyPublisher()
            ) { localParticipant in
                if let localParticipant = localParticipant {
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
            .padding(.horizontal, 8)
            .opacity(callingState == .reconnecting ? 0 : 1)
        }
    }

}

@available(iOS 14.0, *)
public struct CallModifier<Factory: ViewFactory>: ViewModifier {
    
    var viewFactory: Factory
    var viewModel: CallViewModel

    @MainActor
    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
    }
    
    public func body(content: Content) -> some View {
        VideoViewOverlay(rootView: content, viewFactory: viewFactory, viewModel: viewModel)
    }
}

@available(iOS 14.0, *)
extension CallModifier where Factory == DefaultViewFactory {

    @MainActor
    public init(viewModel: CallViewModel) {
        self.init(viewFactory: DefaultViewFactory.shared, viewModel: viewModel)
    }
}
