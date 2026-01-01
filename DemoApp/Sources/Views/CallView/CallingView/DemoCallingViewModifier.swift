//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoCallingViewModifier: ViewModifier {

    @Injected(\.streamVideo) private var streamVideo
    @Injected(\.callKitAdapter) private var callKitAdapter
    @Injected(\.appearance) private var appearance

    @ObservedObject var viewModel: CallViewModel
    @ObservedObject private var appState = AppState.shared

    private var text: Binding<String>

    private var isAnonymous: Bool { appState.currentUser == .anonymous }

    @State private var callType: String =
        !AppState.shared.deeplinkInfo.callType.isEmpty
            ? AppState.shared.deeplinkInfo.callType
            : AppEnvironment.preferredCallType ?? .default

    init(
        text: Binding<String>,
        viewModel: CallViewModel
    ) {
        self.viewModel = viewModel
        self.text = text
    }

    func body(content: Content) -> some View {
        content
            .padding()
            .alignedToReadableContentGuide()
            .background(appearance.colors.lobbyBackground.edgesIgnoringSafeArea(.all))
            .onReceive(appState.$deeplinkInfo) { deeplinkInfo in
                guard
                    !isAnonymous,
                    deeplinkInfo.callId != self.text.wrappedValue
                else { return }

                // We may get in this situation when launching the app from a
                // deeplink.
                if deeplinkInfo.callId.isEmpty {
                    joinCallIfNeeded(with: self.text.wrappedValue, callType: callType)
                } else {
                    self.text.wrappedValue = deeplinkInfo.callId
                    joinCallIfNeeded(
                        with: self.text.wrappedValue,
                        callType: callType
                    )
                }
            }
            .onChange(of: viewModel.callingState) { callingState in
                switch callingState {
                case .inCall where !self.text.wrappedValue.isEmpty:
                    appState.deeplinkInfo = .empty
                    self.text.wrappedValue = ""
                default:
                    break
                }
            }
            .onReceive(appState.$activeAnonymousCallId) { activeAnonymousCallId in
                guard isAnonymous, !activeAnonymousCallId.isEmpty else { return }
                self.text.wrappedValue = activeAnonymousCallId
            }
            .onAppear {
                guard !isAnonymous else { return }
                callKitAdapter.registerForIncomingCalls()
                callKitAdapter.iconTemplateImageData = UIImage(named: "logo")?.pngData()
                joinCallIfNeeded(with: text.wrappedValue, callType: callType)
            }
            .onReceive(appState.$activeCall) { call in
                viewModel.setActiveCall(call)
                call?.setDisconnectionTimeout(AppEnvironment.disconnectionTimeout.duration)
            }
            .onReceive(appState.$userState) { userState in
                if userState == .notLoggedIn {
                    text.wrappedValue = ""
                }
            }
            .toastView(toast: $viewModel.toast)
    }

    private func joinCallIfNeeded(with callId: String, callType: String) {
        guard !callId.isEmpty, viewModel.callingState == .idle else {
            return
        }

        Task {
            do {
                try await streamVideo.connect()
                let call = streamVideo.call(callType: callType, callId: callId)
                await call.updatePublishOptions(
                    preferredVideoCodec: AppEnvironment.preferredVideoCodec.videoCodec
                )
                _ = await Task { @MainActor in
                    viewModel.update(
                        participantsSortComparators: callType == .livestream
                            ? livestreamOrAudioRoomSortPreset
                            : defaultSortPreset
                    )
                    viewModel.joinCall(callType: callType, callId: callId)
                }.result
            } catch {
                log.error(error)
            }
            AppState.shared.deeplinkInfo = .empty
        }
    }
}
