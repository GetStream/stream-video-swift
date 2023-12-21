//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Intents
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct SimpleCallingView: View {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.appearance) var appearance

    @State var text = ""
    @State private var changeEnvironmentPromptForURL: URL?
    @State private var showChangeEnvironmentPrompt: Bool = false

    private var callId: String
    @ObservedObject var appState = AppState.shared
    @ObservedObject var viewModel: CallViewModel

    init(viewModel: CallViewModel, callId: String) {
        self.viewModel = viewModel
        self.callId = callId
    }

    var body: some View {
        VStack {
            DemoCallingTopView(callViewModel: viewModel)

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
                .foregroundColor(.init(appearance.colors.textLowEmphasis))
                .padding()

            HStack {
                Text("Call ID number")
                    .font(.caption)
                    .foregroundColor(.init(appearance.colors.textLowEmphasis))
                Spacer()
            }

            HStack {
                HStack {
                    TextField("Call ID", text: $text)
                        .foregroundColor(appearance.colors.text)
                        .padding(.all, 12)

                    DemoQRCodeScannerButton(viewModel: viewModel) { handleDeeplink($0) }
                }
                .background(Color(appearance.colors.background))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(appearance.colors.textLowEmphasis), lineWidth: 1))

                Button {
                    resignFirstResponder()
                    viewModel.enterLobby(callType: .default, callId: text, members: [])
                } label: {
                    CallButtonView(
                        title: "Join Call", maxWidth: 120, isDisabled: appState.loading || text.isEmpty
                    )
                    .disabled(appState.loading || text.isEmpty)
                }
                .disabled(appState.loading || text.isEmpty)
                .alert(isPresented: $showChangeEnvironmentPrompt) {
                    if let url = changeEnvironmentPromptForURL {
                        return Alert(
                            title: Text("Change environment"),
                            message: Text("In order to access the call you scanned, we will need to change the environment you are logged in. Would you like to proceed?"),
                            primaryButton: .default(Text("OK")) { Router.shared.handle(url: url) },
                            secondaryButton: .cancel()
                        )
                    } else {
                        return Alert(
                            title: Text("Invalid URL"),
                            message: Text("The URL contained in the QR you scanned was invalid. Please try again."),
                            dismissButton: .cancel()
                        )
                    }
                }
            }

            HStack {
                Text("Don't have a Call ID?")
                    .font(.caption)
                    .foregroundColor(.init(appearance.colors.textLowEmphasis))
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
            CallService.shared.registerForIncomingCalls()
            self.text = callId
            joinCallIfNeeded(with: callId)
        }
        .onReceive(appState.$activeCall) { call in
            viewModel.setActiveCall(call)
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

    private func handleDeeplink(_ deeplinkInfo: DeeplinkInfo?) {
        guard let deeplinkInfo else {
            self.text = ""
            return
        }

        if deeplinkInfo.baseURL == AppEnvironment.baseURL {
            self.text = deeplinkInfo.callId
        } else if let url = deeplinkInfo.url {
            self.changeEnvironmentPromptForURL = url
            Task { @MainActor in
                self.showChangeEnvironmentPrompt = true
            }
        }
    }
}

extension URL: Identifiable {
    public var id: ObjectIdentifier {
        .init(self.absoluteString as NSString)
    }
}
