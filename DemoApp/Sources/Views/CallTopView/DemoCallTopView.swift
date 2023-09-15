//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import StreamVideoSwiftUI

struct DemoCallTopView: View {

    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors
    @Injected(\.images) var images

    @ObservedObject private var reactionsHelper = AppState.shared.reactionsHelper

    @ObservedObject var viewModel: CallViewModel
    @ObservedObject var appState = AppState.shared
    @State var sharingPopupDismissed = false
    @State private var isLogsViewerVisible = false

    init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
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

                Button {
                    if appState.audioFilter == nil {
                        appState.audioFilter = RobotVoiceFilter(pitchShift: 0.8)
                    } else {
                        appState.audioFilter = nil
                    }
                } label: {
                    HStack {
                        Text("Robot voice")
                        if appState.audioFilter != nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                reactionsList()

                if AppEnvironment.configuration == .debug {
                    Button {
                        isLogsViewerVisible = true
                    } label: {
                        Label {
                            Text("Show logs")
                        } icon: {
                            Image(systemName: "text.insert")
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
                HStack(spacing: 16) {
                    LayoutMenuView(viewModel: viewModel)
                        .opacity(hideLayoutMenu ? 0 : 1)
                        .accessibility(identifier: "viewMenu")

                    Button {
                        viewModel.participantsShown.toggle()
                    } label: {
                        images.participants
                            .foregroundColor(.white)
                    }
                    .accessibility(identifier: "participantMenu")
                }
                .padding(.horizontal)
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
        ).sheet(isPresented: $isLogsViewerVisible) {
            NavigationView {
                MemoryLogViewer()
            }
        }
    }

    private var hideLayoutMenu: Bool {
        viewModel.call?.state.screenSharingSession != nil
            && viewModel.call?.state.isCurrentUserScreensharing == false
    }

    @ViewBuilder
    private func reactionsList() -> some View {
        ForEach(availableReactions) { reaction in
            Button {
                reactionsHelper.send(reaction: reaction.id == .lowerHand ? .raiseHand : reaction)
            } label: {
                Label(
                    title: {
                        Text(reaction.title)
                    },
                    icon: { Image(systemName: reaction.iconName) }
                )
            }
        }
    }

    private var availableReactions: [Reaction] {
        guard let userId = viewModel.localParticipant?.userId else {
            return []
        }

        let hasRaisedHand = reactionsHelper.activeReactions[userId]?.first(where: { $0.id == .raiseHand }) != nil

        if hasRaisedHand {
            return reactionsHelper.availableReactions.filter { $0.id != .raiseHand }
        } else {
            return reactionsHelper.availableReactions.filter { $0.id != .lowerHand }
        }
    }
}

struct SharingIndicator: View {

    @ObservedObject var viewModel: CallViewModel
    @Binding var sharingPopupDismissed: Bool

    init(viewModel: CallViewModel, sharingPopupDismissed: Binding<Bool>) {
        _viewModel = ObservedObject(initialValue: viewModel)
        _sharingPopupDismissed = sharingPopupDismissed
    }

    var body: some View {
        HStack {
            Text("You are sharing your screen")
                .font(.headline)
            Divider()
            Button {
                viewModel.stopScreensharing()
            } label: {
                Text("Stop sharing")
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

/// Modifier for adding shadow and corner radius to a view.
fileprivate struct ShadowViewModifier: ViewModifier {

    var cornerRadius: CGFloat = 16
    var borderColor: Color = Color.gray

    func body(content: Content) -> some View {
        content
            .background(Color(UIColor.systemBackground))
            .cornerRadius(cornerRadius)
            .modifier(ShadowModifier())
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        borderColor,
                        lineWidth: 0.5
                    )
            )
    }
}

/// Modifier for adding shadow to a view.
fileprivate struct ShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 12)
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}

