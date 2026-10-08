//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
                        viewFactory.makeMinimizedCallView(options: .init(viewModel: viewModel))
                    } else {
                        viewFactory.makeCallView(options: .init(viewModel: viewModel))
                    }
                } else {
                    viewFactory.makeWaitingLocalUserView(options: .init(viewModel: viewModel))
                }
            } else if viewModel.callingState == .reconnecting {
                viewFactory.makeReconnectionView(options: .init(viewModel: viewModel))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toastView(toast: $viewModel.toast)
        .moderationWarning(call: viewModel.call)
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
            viewFactory.makeIncomingCallView(options: .init(viewModel: viewModel, callInfo: callInfo))
        } else if viewModel.callingState == .outgoing {
            viewFactory.makeOutgoingCallView(options: .init(viewModel: viewModel))
        } else if viewModel.callingState == .joining {
            viewFactory.makeJoiningCallView(options: .init(viewModel: viewModel))
        } else if case let .lobby(lobbyInfo) = viewModel.callingState {
            viewFactory.makeLobbyView(
                options: .init(
                    viewModel: viewModel,
                    lobbyInfo: lobbyInfo,
                    callSettings: $viewModel.callSettings
                )
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
    @Injected(\.colors) var colors
    @Injected(\.layout) var layout

    @ObservedObject var viewModel: CallViewModel
    var viewFactory: Factory
    
    public init(viewModel: CallViewModel, viewFactory: Factory) {
        self.viewModel = viewModel
        self.viewFactory = viewFactory
    }
    
    public var body: some View {
        ZStack {
            Color(colors.backgroundCoreApp)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: layout.spacingXs) {
                viewFactory.makeCallTopView(options: .init(viewModel: viewModel))
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
                                options: .init(
                                    localParticipant: localParticipant,
                                    callSettings: $viewModel.callSettings,
                                    call: viewModel.call
                                )
                            ))
                        }
                    } else {
                        Spacer()
                    }
                }
                .padding(.horizontal, layout.spacingXs)
                .opacity(viewModel.callingState == .reconnecting ? 0 : 1)

                viewFactory.makeCallControlsView(options: .init(viewModel: viewModel))
                    .opacity(viewModel.callingState == .reconnecting ? 0 : 1)
            }
            .presentParticipantListView(viewModel: viewModel, viewFactory: viewFactory)
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
