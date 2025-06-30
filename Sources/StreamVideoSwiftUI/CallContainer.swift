//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

public struct VideoViewOverlay<RootView: View, Factory: ViewFactory>: View {

    var rootView: RootView
    var viewFactory: Factory
    var viewModel: CallViewModel

    public init(
        rootView: RootView,
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel
    ) {
        self.rootView = rootView
        self.viewFactory = viewFactory
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            rootView
            CallContainer(viewFactory: viewFactory, viewModel: viewModel)
        }
    }
}

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
            .receive(on: DispatchQueue.global(qos: .default))
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

    @MainActor
    public init(viewModel: CallViewModel) where Factory == DefaultViewFactory {
        self.init(viewFactory: DefaultViewFactory.shared, viewModel: viewModel)
    }

    public func body(content: Content) -> some View {
        VideoViewOverlay(rootView: content, viewFactory: viewFactory, viewModel: viewModel)
    }
}
