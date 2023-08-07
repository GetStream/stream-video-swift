//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct CallTopView: View {
            
    @Injected(\.colors) var colors
    @Injected(\.images) var images
    
    @ObservedObject var viewModel: CallViewModel
    @State var sharingPopupDismissed = false
    
    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        HStack {
            Button {
                withAnimation {
                    viewModel.isMinimized = true
                }
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(colors.textInverted)
                    .padding()
            }
            .accessibility(identifier: "minimizeCallViewButton")
            
            if viewModel.recordingState == .recording {
                RecordingView()
                    .accessibility(identifier: "recordingLabel")
            }

            Spacer()
            
            
            if #available(iOS 14, *) {
                LayoutMenuView(viewModel: viewModel)
                    .opacity(hideLayoutMenu ? 0 : 1)
                    .accessibility(identifier: "viewMenu")
                
                Button {
                    viewModel.participantsShown.toggle()
                } label: {
                    images.participants
                        .padding(.horizontal)
                        .padding(.horizontal, 2)
                        .foregroundColor(.white)
                }
                .accessibility(identifier: "participantMenu")
            }
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
}

struct SharingIndicator: View {
    
    @ObservedObject var viewModel: CallViewModel
    @Binding var sharingPopupDismissed: Bool
    
    var body: some View {
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
