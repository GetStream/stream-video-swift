//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct CallTopView<Factory: ViewFactory>: View {

    @Injected(\.streamVideo) var streamVideo

    private var viewFactory: Factory

    @ObservedObject var viewModel: CallViewModel
    @State var sharingPopupDismissed = false
    
    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
    }
    
    public var body: some View {
        Group {
            HStack(spacing: 0) {
                HStack(spacing: layout.spacingXs) {
                    if
                        #available(iOS 14.0, *),
                        viewModel.callParticipants.count > 1 {
                        LayoutMenuView(viewModel: viewModel)
                            .opacity(hideLayoutMenu ? 0 : 1)
                            .accessibility(identifier: "viewMenu")
                    }

                    if call?.state.ownCapabilities.contains(.sendVideo) == true {
                        ToggleCameraIconView(viewModel: viewModel)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)

                HStack(alignment: .center, spacing: layout.spacingXs) {
                    CallDurationView(viewModel)
                }
                .frame(height: 44)
                .frame(maxWidth: .infinity)

                HStack(spacing: layout.spacingXs) {
                    Spacer()
                    HangUpIconView(viewModel: viewModel)
                }
                .frame(maxWidth: .infinity)
            }
            .overlay(overlayView)
            .padding(.horizontal, layout.spacingMd)
            .padding(.vertical, layout.spacingMd)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var overlayView: some View {
        if viewModel.call?.state.isCurrentUserScreensharing == true, !sharingPopupDismissed {
            SharingIndicator(
                viewModel: viewModel,
                sharingPopupDismissed: $sharingPopupDismissed
            )
        } else {
            viewFactory.makePermissionsPromptView(call: viewModel.call)
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

public struct SharingIndicator: View {
    @Injected(\.videoAppearance) var videoAppearance

    @ObservedObject var viewModel: CallViewModel
    @Binding var sharingPopupDismissed: Bool
    
    public init(viewModel: CallViewModel, sharingPopupDismissed: Binding<Bool>) {
        _viewModel = ObservedObject(initialValue: viewModel)
        _sharingPopupDismissed = sharingPopupDismissed
    }
    
    public var body: some View {
        HStack(spacing: layout.spacingXs) {
            Text(L10n.Call.Current.sharing)
                .font(fonts.headline)
                .foregroundColor(Color(colors.textPrimary))
            Divider()
            Button {
                viewModel.stopScreensharing()
            } label: {
                Text(L10n.Call.Current.stopSharing)
                    .font(fonts.headline)
                    .foregroundColor(Color(colors.accentPrimary))
            }
            Button {
                sharingPopupDismissed = true
            } label: {
                videoAppearance.images.xmark
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 14)
                    .foregroundColor(Color(colors.accentPrimary))
            }
            .padding(.leading, layout.spacingXxs)
        }
        .padding(layout.spacingXs)
        .modifier(ShadowViewModifier())
    }
}
