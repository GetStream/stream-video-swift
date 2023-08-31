//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Intents
import NukeUI
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct SimpleCallingView: View {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.appearance) var appearance

    @State var text = ""

    private var callId: String
    @ObservedObject var appState = AppState.shared
    @ObservedObject var viewModel: CallViewModel

    init(viewModel: CallViewModel, callId: String) {
        self.viewModel = viewModel
        self.callId = callId
    }

    var body: some View {
        VStack {
            TopView()

            Spacer()

            Image("video")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 114)

            Text("Stream Video Calling")
                .font(.title)
                .bold()
                .padding()

            Text("Build reliable video calling, audio rooms, and live streaming with our easy-to-use SDKs and global edge network")
                .multilineTextAlignment(.center)
                .foregroundColor(.init(appearance.colors.textLowEmphasis.cgColor))
                .padding()

            HStack {
                Text("Call ID number")
                    .font(.caption)
                    .foregroundColor(.init(appearance.colors.textLowEmphasis.cgColor))
                Spacer()
            }

            HStack {
                TextField("Call ID", text: $text)
                    .padding(.all, 12)
                    .background(appearance.colors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(appearance.colors.textLowEmphasis.cgColor), lineWidth: 1))
                Button {
                    resignFirstResponder()
                    viewModel.enterLobby(callType: .default, callId: text, members: [])
                } label: {
                    CallButtonView(title: "Join Call", maxWidth: 120, isDisabled: appState.loading || text.isEmpty)
                        .disabled(appState.loading || text.isEmpty)
                }
                .disabled(appState.loading || text.isEmpty)
            }

            HStack {
                Text("Don't have a Call ID?")
                    .font(.caption)
                    .foregroundColor(.init(appearance.colors.textLowEmphasis.cgColor))
                Spacer()
            }
            .padding(.top)

            Button {
                resignFirstResponder()
                viewModel.startCall(callType: .default, callId: .unique, members: [], ring: false)
            } label: {
                CallButtonView(title: "Start New Call", isDisabled: appState.loading)
                    .disabled(appState.loading)
            }
            .padding(.bottom)
            .disabled(appState.loading)

            Spacer()
        }
        .padding()
        .alignedToReadableContentGuide()
        .background(appearance.colors.lobbyBackground.edgesIgnoringSafeArea(.all))
        .onChange(of: appState.deeplinkInfo) { deeplinkInfo in
            self.text = deeplinkInfo.callId
            joinCallIfNeeded(with: deeplinkInfo.callId, callType: deeplinkInfo.callType)
        }
        .onChange(of: viewModel.callingState) { callingState in
            switch callingState {
            case .inCall:
                appState.deeplinkInfo = .empty
            default:
                break
            }
        }
        .onAppear {
            self.text = callId
            joinCallIfNeeded(with: callId)
        }
    }

    private func joinCallIfNeeded(with callId: String, callType: String = .default) {
        guard !callId.isEmpty, viewModel.callingState == .idle else {
            return
        }

        Task {
            try await streamVideo.connect()
            await MainActor.run {
                viewModel.joinCall(callType: callType, callId: callId)
            }
        }
    }
}

private struct TopView: View {

    @Injected(\.streamVideo) var streamVideo

    @State var logoutAlertShown = false

    var body: some View {
        HStack {
            if AppEnvironment.configuration.isRelease {
                Label {
                    Text(streamVideo.user.name)
                        .bold()
                        .foregroundColor(.primary)
                } icon: {
                    UserAvatar(imageURL: streamVideo.user.imageURL, size: 32)
                        .accessibilityIdentifier("userAvatar")
                }
            } else {
                Button {
                    logoutAlertShown = !AppEnvironment.configuration.isRelease
                } label: {
                    Label {
                        Text(streamVideo.user.name)
                            .bold()
                            .foregroundColor(.primary)
                    } icon: {
                        UserAvatar(imageURL: streamVideo.user.imageURL, size: 32)
                            .accessibilityIdentifier("userAvatar")
                    }
                }
            }

            Spacer()
        }
        .alert(isPresented: $logoutAlertShown) {
            Alert(
                title: Text("Sign out"),
                message: Text("Are you sure you want to sign out?"),
                primaryButton: .destructive(Text("Sign out")) {
                    withAnimation {
                        AppState.shared.logout()
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
}
