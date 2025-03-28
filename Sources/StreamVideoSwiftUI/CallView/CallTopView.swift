//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct CallTopView: View {
            
    @Injected(\.streamVideo) var streamVideo
    @Injected(\.colors) var colors
    @Injected(\.images) var images
    
    @ObservedObject var viewModel: CallViewModel
    @State var sharingPopupDismissed = false
    
    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        Group {
            HStack(spacing: 0) {
                HStack {
                    if
                        #available(iOS 14.0, *),
                        viewModel.callParticipants.count > 1
                    {
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
            viewModel.call?.state.isCurrentUserScreensharing == true ?
                SharingIndicator(
                    viewModel: viewModel,
                    sharingPopupDismissed: $sharingPopupDismissed
                )
                .opacity(sharingPopupDismissed ? 0 : 1)
                : nil
        )
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
            
    @ObservedObject var viewModel: CallViewModel
    @Binding var sharingPopupDismissed: Bool
    
    public init(viewModel: CallViewModel, sharingPopupDismissed: Binding<Bool>) {
        _viewModel = ObservedObject(initialValue: viewModel)
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
