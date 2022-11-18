//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct VideoViewOverlay<RootView: View, Factory: ViewFactory>: View {
    
    var rootView: RootView
    var viewFactory: Factory
    @StateObject var viewModel: CallViewModel
    
    public init(rootView: RootView, viewFactory: Factory, viewModel: CallViewModel) {
        self.rootView = rootView
        self.viewFactory = viewFactory
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            rootView
            VideoView(viewFactory: viewFactory, viewModel: viewModel)
        }
    }
}

public struct VideoView<Factory: ViewFactory>: View {
    
    @Injected(\.utils) var utils
    
    var viewFactory: Factory
    @StateObject var viewModel: CallViewModel
    
    private let padding: CGFloat = 16
    
    public init(viewFactory: Factory, viewModel: CallViewModel) {
        self.viewFactory = viewFactory
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            if viewModel.callingState == .outgoing {
                viewFactory.makeOutgoingCallView(viewModel: viewModel)
            } else if viewModel.callingState == .inCall {
                if !viewModel.participants.isEmpty {
                    if viewModel.isMinimized {
                        MinimizedCallView(viewModel: viewModel)
                    } else {
                        viewFactory.makeCallView(viewModel: viewModel)
                    }
                } else {
                    WaitingLocalUserView(viewModel: viewModel, viewFactory: viewFactory)
                }
            } else if case let .incoming(callInfo) = viewModel.callingState {
                viewFactory.makeIncomingCallView(viewModel: viewModel, callInfo: callInfo)
            }
        }
        .onReceive(viewModel.$callingState) { _ in
            if viewModel.callingState == .idle || viewModel.callingState == .inCall {
                utils.callSoundsPlayer.stopOngoingSound()
            }
        }
    }
}

public struct WaitingLocalUserView<Factory: ViewFactory>: View {
    
    @ObservedObject var viewModel: CallViewModel
    var viewFactory: Factory
    
    public var body: some View {
        ZStack {
            LocalVideoView(callSettings: viewModel.callSettings) { view in
                if let track = viewModel.localParticipant?.track {
                    view.add(track: track)
                } else {
                    viewModel.renderLocalVideo(renderer: view)
                }
            }
            VStack {
                Spacer()
                viewFactory.makeCallControlsView(viewModel: viewModel)
            }
        }
    }
}

public struct CallModifier<Factory: ViewFactory>: ViewModifier {
    
    var viewFactory: Factory
    var viewModel: CallViewModel
    
    public init(viewFactory: Factory = DefaultViewFactory.shared, viewModel: CallViewModel) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
    }
    
    public func body(content: Content) -> some View {
        VideoViewOverlay(rootView: content, viewFactory: viewFactory, viewModel: viewModel)
    }
}

extension CallModifier where Factory == DefaultViewFactory {
    
    public init(viewModel: CallViewModel) {
        self.init(viewFactory: DefaultViewFactory.shared, viewModel: viewModel)
    }
}
