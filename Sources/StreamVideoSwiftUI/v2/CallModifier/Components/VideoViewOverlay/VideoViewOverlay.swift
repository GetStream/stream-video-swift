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

@available(iOS, introduced: 13, obsoleted: 14)
public struct VideoViewOverlay_iOS13<RootView: View, Factory: ViewFactory>: View {

    var rootView: RootView
    var viewFactory: Factory
    @BackportStateObject var viewModel: CallViewModel

    public init(
        rootView: RootView,
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel
    ) {
        self.rootView = rootView
        self.viewFactory = viewFactory
        _viewModel = BackportStateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ZStack {
            rootView
            CallContainer(viewFactory: viewFactory, viewModel: viewModel)
        }
    }
}
