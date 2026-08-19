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

        AppEnvironment.EncryptionKeys.shared.applyDeeplink(deeplinkInfo)

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

    private func setEncryptionIfNeeded(for callId: String) async {
        let call = streamVideo.call(callType: callType, callId: callId)
        await AppEnvironment.EncryptionKeys.shared.attachIfNeeded(
            to: call,
            userId: streamVideo.user.id
        )
    }

    private func prepareCall(id: String) async {
        await setPreferredVideoCodec(for: id)
        try? await setAudioSessionPolicyOverride(for: id)
        await setClientCapabilities(for: id)
    }

    private func parseURLIfRequired(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let adapter = DeeplinkAdapter()
        let url = URLComponents(string: trimmed)?.url ?? URL(string: trimmed)
        guard let url, adapter.canHandle(url: url) else { return }

        var deeplinkInfo = adapter.handle(url: url).deeplinkInfo
        if deeplinkInfo.encryptionKey?.isEmpty ?? true {
            deeplinkInfo.encryptionKey = DeeplinkAdapter.encryptionKey(
                fromRaw: trimmed
            )
        }
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
            await prepareCall(id: text)
            viewModel.enterLobby(
                callType: callType,
                callId: text,
                members: []
            )
        case .join:
            await prepareCall(id: text)
            await setEncryptionIfNeeded(for: text)
            viewModel.joinCall(
                callType: callType,
                callId: text,
                encryption: AppEnvironment.EncryptionKeys.shared.encryptionRequest
            )
        case let .start(callId):
            await prepareCall(id: callId)
            await setEncryptionIfNeeded(for: callId)
            let highScaleHint = AppEnvironment
                .highScaleLivestreamPublisherHint
                .value
            viewModel.startCall(
                callType: callType,
                callId: callId,
                members: [],
                ring: false,
                maxDuration: AppEnvironment.callExpiration.duration,
                highScaleLivestreamPublisherHint: highScaleHint,
                video: viewModel.callSettings.videoOn,
                encryption: AppEnvironment.EncryptionKeys.shared.encryptionRequest
            )
        }
    }
}
