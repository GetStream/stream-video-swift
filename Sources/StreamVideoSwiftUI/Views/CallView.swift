//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamWebRTC
import SwiftUI

public struct CallView<Factory: ViewFactory>: View {

    @Injected(\.colors) var colors

    var viewFactory: Factory
    var viewModel: CallViewModel

    @State var hideUIElements: Bool
    var hideUIElementsPublisher: AnyPublisher<Bool, Never>

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
        hideUIElements = viewModel.hideUIElements
        hideUIElementsPublisher = viewModel
            .$hideUIElements
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    public var body: some View {
        VStack {
            headerView
            middleView
            footerView
        }
        .onReceive(hideUIElementsPublisher) { hideUIElements = $0 }
        .background(backgroundView)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .enablePictureInPicture(viewModel.isPictureInPictureEnabled)
        .presentParticipantListView(viewFactory: viewFactory, viewModel: viewModel)
        .debugViewRendering()
    }

    @ViewBuilder
    var headerView: some View {
        viewFactory
            .makeCallTopView(viewModel: viewModel)
            .presentParticipantEventsNotification(viewModel: viewModel)
    }

    @ViewBuilder
    var middleView: some View {
        GeometryReader { proxy in
            contentView(in: proxy.frame(in: .global))
                .overlay(overlayView(with: proxy))
        }
        .padding([.leading, .trailing], 8)
    }

    @ViewBuilder
    var footerView: some View {
        if !hideUIElements {
            viewFactory.makeCallControlsView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    var backgroundView: some View {
        Color(colors.callBackground).edgesIgnoringSafeArea(.all)
    }

    @ViewBuilder
    private func contentView(in bounds: CGRect) -> some View {
        CallContentView(
            viewFactory: viewFactory,
            viewModel: viewModel,
            bounds: bounds
        )
    }

    @ViewBuilder
    private func overlayView(with proxy: GeometryProxy) -> some View {
        CallOverlayContentView(
            viewFactory: viewFactory,
            viewModel: viewModel,
            proxy: proxy
        )
    }
}
