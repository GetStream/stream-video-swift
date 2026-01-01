//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Intents
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct SimpleCallingView: View {

    private enum CallAction { case lobby, join, start(callId: String) }

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.appearance) var appearance

    @State var text = ""
    @State private var callType: String
    @State private var changeEnvironmentPromptForURL: URL?
    @State private var showChangeEnvironmentPrompt: Bool = false

    @ObservedObject var appState = AppState.shared
    @ObservedObject var viewModel: CallViewModel

    init(viewModel: CallViewModel, callId: String) {
        self.viewModel = viewModel
        _text = .init(initialValue: callId)
        _callType = .init(initialValue: {
            guard
                !AppState.shared.deeplinkInfo.callId.isEmpty,
                !AppState.shared.deeplinkInfo.callType.isEmpty
            else {
                return AppEnvironment.preferredCallType ?? .default
            }

            return AppState.shared.deeplinkInfo.callType
        }())
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
                Text("\(callTypeTitle) ID number")
                    .font(.caption)
                    .foregroundColor(.init(appearance.colors.textLowEmphasis))
                Spacer()
            }

            HStack {
                HStack {
                    TextField("\(callTypeTitle) ID", text: $text)
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
                    Task {
                        await performCallAction(
                            callType != .livestream ? .lobby : .join
                        )
                    }
                } label: {
                    CallButtonView(
                        title: "Join \(callTypeTitle)",
                        maxWidth: 120,
                        isDisabled: appState.loading || text.isEmpty
                    )
                    .disabled(appState.loading || text.isEmpty)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                }
                .disabled(appState.loading || text.isEmpty)
            }

            if canStartCall {
                HStack {
                    Text("Don't have a \(callTypeTitle) ID?")
                        .font(.caption)
                        .foregroundColor(.init(appearance.colors.textLowEmphasis))
                    Spacer()
                }
                .padding(.top)

                Button {
                    resignFirstResponder()
                    Task { await performCallAction(.start(callId: .unique)) }
                } label: {
                    CallButtonView(
                        title: "Start New \(callTypeTitle)",
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
        .onChange(of: text) { parseURLIfRequired($0) }
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

        if
            deeplinkInfo.baseURL == AppEnvironment.baseURL || (deeplinkInfo.baseURL == .legacy && AppEnvironment.baseURL == .pronto)
        {
            if !Set(AppEnvironment.availableCallTypes).contains(deeplinkInfo.callType) {
                AppEnvironment.availableCallTypes.append(deeplinkInfo.callType)
            }
            AppEnvironment.preferredCallType = deeplinkInfo.callType

            callType = deeplinkInfo.callType
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

    private func setPreferredVideoCodec(for callId: String) async {
        let call = streamVideo.call(callType: callType, callId: callId)
        await call.updatePublishOptions(
            preferredVideoCodec: AppEnvironment.preferredVideoCodec.videoCodec
        )
    }

    private func setAudioSessionPolicyOverride(for callId: String) async throws {
        let call = streamVideo.call(callType: callType, callId: callId)
        await call.updateAudioSessionPolicy(AppEnvironment.audioSessionPolicy.value)
    }

    private func setClientCapabilities(for callId: String) async {
        guard let clientCapabilities = AppEnvironment.clientCapabilities else {
            return
        }
        let call = streamVideo.call(callType: callType, callId: callId)
        await call.enableClientCapabilities(clientCapabilities)
    }

    private func parseURLIfRequired(_ text: String) {
        let adapter = DeeplinkAdapter()
        guard
            let url = URL(string: text),
            adapter.canHandle(url: url)
        else {
            return
        }

        let deeplinkInfo = adapter.handle(url: url).deeplinkInfo
        guard !deeplinkInfo.callId.isEmpty else { return }

        handleDeeplink(deeplinkInfo)
    }

    private var callTypeTitle: String {
        switch callType {
        case .livestream:
            return "Livestream"
        case .audioRoom:
            return "AudioRoom"
        default:
            return "Call"
        }
    }

    private func performCallAction(_ action: CallAction) async {
        viewModel.update(
            participantsSortComparators: callType == .livestream
                ? livestreamOrAudioRoomSortPreset
                : defaultSortPreset
        )
        switch action {
        case .lobby:
            await setPreferredVideoCodec(for: text)
            try? await setAudioSessionPolicyOverride(for: text)
            await setClientCapabilities(for: text)
            viewModel.enterLobby(
                callType: callType,
                callId: text,
                members: []
            )
        case .join:
            await setPreferredVideoCodec(for: text)
            try? await setAudioSessionPolicyOverride(for: text)
            await setClientCapabilities(for: text)
            viewModel.joinCall(callType: callType, callId: text)
        case let .start(callId):
            await setPreferredVideoCodec(for: callId)
            try? await setAudioSessionPolicyOverride(for: callId)
            await setClientCapabilities(for: callId)
            viewModel.startCall(
                callType: callType,
                callId: callId,
                members: [],
                ring: false,
                maxDuration: AppEnvironment.callExpiration.duration,
                video: viewModel.callSettings.videoOn
            )
        }
    }
}
