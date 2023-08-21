//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct CustomCallTopView: View {

    @Injected(\.colors) var colors
    @Injected(\.images) var images
    @Injected(\.fonts) var fonts

    @ObservedObject var viewModel: CallViewModel
    @ObservedObject var appState = AppState.shared

    @State var sharingPopupDismissed = false

    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack {
            Menu {
                Button {
                    viewModel.toggleSpeaker()
                } label: {
                    HStack {
                        Text("Speaker")
                        if viewModel.callSettings.speakerOn {
                            Image(systemName: "checkmark")
                        }
                    }

                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.white)
                    .font(fonts.bodyBold)
                    .padding()
            }

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
