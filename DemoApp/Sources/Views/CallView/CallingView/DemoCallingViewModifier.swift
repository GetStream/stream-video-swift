//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoCallingViewModifier: ViewModifier {

    @Injected(\.streamVideo) private var streamVideo
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
                guard !isAnonymous else { return }
                self.text.wrappedValue = deeplinkInfo.callId
                DispatchQueue.main.async {
                    joinCallIfNeeded(
                        with: deeplinkInfo.callId,
                        callType: deeplinkInfo.callType
                    )
                }
            }
            .onChange(of: viewModel.callingState) { callingState in
                switch callingState {
                case .inCall:
                    appState.deeplinkInfo = .empty
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
                CallService.shared.registerForIncomingCalls()
                joinCallIfNeeded(with: text.wrappedValue)
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
}
