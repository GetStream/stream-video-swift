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
    @State var sharingPopupDismissed = false

    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            HStack(spacing: 0) {
                HStack {
                    layoutMenuView
                    toggleCameraIconView
                    Spacer()
                }
                .frame(maxWidth: .infinity)

                HStack(alignment: .center) {
                    CallDurationView(viewModel)
                }
                .frame(height: 44)
                .frame(maxWidth: .infinity)

                HStack {
                    Spacer()
                    HangUpIconView(viewModel: viewModel)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.vertical)
            .frame(maxWidth: .infinity)
        }
        .overlay(
            CurrentUserScreenSharingIndicatorView(
                viewModel: viewModel,
                call: call,
                sharingPopupDismissed: $sharingPopupDismissed
            )
        )
    }

    @ViewBuilder
    private var layoutMenuView: some View {
        PublisherSubscriptionView(
            initial: viewModel.callParticipants.count,
            publisher: viewModel.$callParticipants.map(\.count).eraseToAnyPublisher()
        ) { participantsCount in
            if
                #available(iOS 14.0, *),
                participantsCount > 1
            {
                LayoutMenuView(viewModel: viewModel)
                    .opacity(hideLayoutMenu ? 0 : 1)
                    .accessibility(identifier: "viewMenu")
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var toggleCameraIconView: some View {
        PublisherSubscriptionView(
            initial: call?.state.ownCapabilities ?? [],
            publisher: call?.state.$ownCapabilities.eraseToAnyPublisher()
        ) { ownCapabilities in
            if ownCapabilities.contains(.sendVideo) == true {
                ToggleCameraIconView(viewModel: viewModel)
            } else {
                EmptyView()
            }
        }
    }

    private var hideLayoutMenu: Bool {
        viewModel.call?.state.screenSharingSession != nil
            && viewModel.call?.state.isCurrentUserScreensharing == false
    }

    private var call: Call? {
        switch viewModel.callingState {
        case .incoming, .outgoing:
            return streamVideo.state.ringingCall
        default:
            return viewModel.call
        }
    }
}

public struct CurrentUserScreenSharingIndicatorView: View {

    var viewModel: CallViewModel
    var call: Call?
    var sharingPopupDismissed: Binding<Bool>

    public var body: some View {
        PublisherSubscriptionView(
            initial: call?.state.isCurrentUserScreensharing ?? false,
            publisher: call?.state.$isCurrentUserScreensharing.eraseToAnyPublisher(),
            contentProvider: { isCurrentUserScreenSharing in
                if isCurrentUserScreenSharing {
                    SharingIndicator(
                        viewModel: viewModel,
                        sharingPopupDismissed: sharingPopupDismissed
                    )
                    .opacity(sharingPopupDismissed.wrappedValue ? 0 : 1)
                } else {
                    EmptyView()
                }
            }
        )
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
