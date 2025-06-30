//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

public struct CallTopView: View {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.colors) var colors
    @Injected(\.images) var images

    var viewModel: CallViewModel

    @State var isCurrentUserScreensharing: Bool
    var isCurrentUserScreensharingPublisher: AnyPublisher<Bool, Never>?

    @State var sharingPopupDismissed = false

    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel

        isCurrentUserScreensharing = viewModel
            .call?
            .state
            .isCurrentUserScreensharing ?? false
        isCurrentUserScreensharingPublisher = viewModel
            .call?
            .state
            .$isCurrentUserScreensharing
            .removeDuplicates()
            .eraseToAnyPublisher()
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
        .onReceive(isCurrentUserScreensharingPublisher) { isCurrentUserScreensharing = $0 }
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
        if isCurrentUserScreensharing {
            SharingIndicator(
                viewModel: viewModel,
                sharingPopupDismissed: $sharingPopupDismissed
            )
        }
    }
}

public struct SharingIndicator: View {

    var viewModel: CallViewModel
    @Binding var sharingPopupDismissed: Bool

    public init(viewModel: CallViewModel, sharingPopupDismissed: Binding<Bool>) {
        self.viewModel = viewModel
        _sharingPopupDismissed = sharingPopupDismissed
    }

    public var body: some View {
        HStack {
            Text(L10n.Call.Current.sharing)
                .font(.headline)
            Divider()
            Button {
                viewModel.stopScreensharing()
            } label: {
                Text(L10n.Call.Current.stopSharing)
                    .font(.headline)
            }
            Button {
                sharingPopupDismissed = true
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 14)
            }
            .padding(.leading, 4)
        }
        .padding(.all, 8)
        .modifier(ShadowViewModifier())
    }
}
