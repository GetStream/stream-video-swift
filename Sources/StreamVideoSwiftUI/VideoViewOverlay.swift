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
    
    var viewFactory: Factory
    @StateObject var viewModel: CallViewModel
    
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
                    viewFactory.makeCallView(viewModel: viewModel)
                } else {
                    WaitingLocalUserView(viewModel: viewModel)
                }
            } else if case let .incoming(callInfo) = viewModel.callingState {
                viewFactory.makeIncomingCallView(viewModel: viewModel, callInfo: callInfo)
            }
        }
    }
}

public struct WaitingLocalUserView: View {
    
    @ObservedObject var viewModel: CallViewModel
    
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
                CallControlsView(viewModel: viewModel)
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
