//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Intents
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct SimpleCallingView: View {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.appearance) var appearance

    @State var text = ""
    @State private var changeEnvironmentPromptForURL: URL?
    @State private var showChangeEnvironmentPrompt: Bool = false

    @ObservedObject var appState = AppState.shared
    @ObservedObject var viewModel: CallViewModel

    init(viewModel: CallViewModel, callId: String) {
        self.viewModel = viewModel
        text = callId
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
                        .disabled(isAnonymous)

                    if !isAnonymous {
                        DemoQRCodeScannerButton(
                            viewModel: viewModel
                        ) { handleDeeplink($0) }
                    }
                }
                .background(Color(appearance.colors.background))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8).stroke(
                        Color(appearance.colors.textLowEmphasis),
                        lineWidth: 1
                    )
                )
                .changeEnvironmentIfRequired(
                    showPrompt: $showChangeEnvironmentPrompt,
                    environmentURL: $changeEnvironmentPromptForURL
                )

                Button {
                    resignFirstResponder()
                    viewModel.enterLobby(
                        callType: .default,
                        callId: text,
                        members: []
                    )
                } label: {
                    CallButtonView(
                        title: "Join Call",
                        maxWidth: 120,
                        isDisabled: appState.loading || text.isEmpty
                    )
                    .disabled(appState.loading || text.isEmpty)
                }
                .disabled(appState.loading || text.isEmpty)
            }

            if canStartCall {
                HStack {
                    Text("Don't have a Call ID?")
                        .font(.caption)
                        .foregroundColor(
                            .init(
                                appearance.colors.textLowEmphasis
                            )
                        )
                    Spacer()
                }
                .padding(.top)

                Button {
                    resignFirstResponder()
                    viewModel.startCall(
                        callType: .default,
                        callId: .unique,
                        members: [],
                        ring: false
                    )
                } label: {
                    CallButtonView(
                        title: "Start New Call",
                        isDisabled: appState.loading
                    )
                    .disabled(appState.loading)
                }
                .padding(.bottom)
                .disabled(appState.loading)
            }

            Spacer()
        }
        .modifier(
            DemoCallingViewModifier(
                text: $text,
                viewModel: viewModel
            )
        )
    }

    private var isAnonymous: Bool { appState.currentUser == .anonymous }
    private var canStartCall: Bool {
        appState.currentUser?.type == .regular
    }

    private func handleDeeplink(_ deeplinkInfo: DeeplinkInfo?) {
        guard let deeplinkInfo else {
            text = ""
            return
        }

        if deeplinkInfo.baseURL == AppEnvironment.baseURL {
            text = deeplinkInfo.callId
        } else if let url = deeplinkInfo.url {
            changeEnvironmentPromptForURL = url
            DispatchQueue
                .main
                .asyncAfter(deadline: .now() + 0.1) {
                    self.showChangeEnvironmentPrompt = true
                }
        }
    }
}

extension URL: Identifiable {
    public var id: ObjectIdentifier {
        .init(absoluteString as NSString)
    }
}
