//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct CallTopView: View {
            
    @Injected(\.streamVideo) var streamVideo
    @Injected(\.colors) var colors
    @Injected(\.images) var images
    
    var viewModel: CallViewModel

    @State var isCurrentUserScreensharing: Bool
    @State var sharingPopupDismissed = false
    
    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
        isCurrentUserScreensharing = viewModel.call?.state.isCurrentUserScreensharing ?? false
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            leadingView
                .frame(maxWidth: .infinity)

            middleView
                .frame(maxWidth: .infinity)

            trailingView
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .overlay(overlayView)
        .debugViewRendering()
    }

    @ViewBuilder
    private var leadingView: some View {
        HStack {
            LayoutMenuView(viewModel: viewModel)
            ToggleCameraIconView(viewModel: viewModel)
            Spacer()
        }
    }

    @ViewBuilder
    private var middleView: some View {
        HStack(alignment: .center) {
            CallDurationView(viewModel)
        }
        .frame(height: 44)
    }

    @ViewBuilder
    private var trailingView: some View {
        HStack {
            Spacer()
            HangUpIconView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var overlayView: some View {
        Group {
            if isCurrentUserScreensharing {
                SharingIndicator(
                    viewModel: viewModel,
                    sharingPopupDismissed: $sharingPopupDismissed
                )
            }
        }
        .onReceive(viewModel.call?.state.$isCurrentUserScreensharing.removeDuplicates().eraseToAnyPublisher()) {
            isCurrentUserScreensharing = $0
        }
    }
}
