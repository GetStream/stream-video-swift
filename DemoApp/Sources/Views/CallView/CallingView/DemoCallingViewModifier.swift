//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
                    joinCallIfNeeded(with: self.text.wrappedValue)
                } else {
                    self.text.wrappedValue = deeplinkInfo.callId
                    joinCallIfNeeded(
                        with: self.text.wrappedValue,
                        callType: deeplinkInfo.callType
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
                joinCallIfNeeded(with: text.wrappedValue)
            }
            .onReceive(appState.$activeCall) { call in
                viewModel.setActiveCall(call)
            }
            .onReceive(appState.$userState) { userState in
                if userState == .notLoggedIn {
                    text.wrappedValue = ""
                }
            }
            .toastView(toast: $viewModel.toast)
    }

    private func joinCallIfNeeded(with callId: String, callType: String = .default) {
        guard !callId.isEmpty, viewModel.callingState == .idle else {
            return
        }

        Task {
            do {
                try await streamVideo.connect()
                await MainActor.run {
                    viewModel.joinCall(callType: callType, callId: callId)
                }
            } catch {
                log.error(error)
            }
        }
    }
}
