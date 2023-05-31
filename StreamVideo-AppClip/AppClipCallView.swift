//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI
import Intents

struct AppClipCallView: View {

    private var callId: String
    @Injected(\.streamVideo) var streamVideo
    @StateObject var viewModel: CallViewModel
    @ObservedObject var appState = AppState.shared

    init(callId: String) {
        _viewModel = StateObject(wrappedValue: CallViewModel())
        self.callId = callId
    }

    var body: some View {
        StreamCallingView(viewModel: viewModel)
            .modifier(CallModifier(viewFactory: DemoAppViewFactory.shared, viewModel: viewModel))
            .onAppear { joinCallIfNeeded(with: callId) }
            .onReceive(appState.$deeplinkInfo) { deeplinkInfo in
                if deeplinkInfo != .empty {
                    joinCallIfNeeded(with: deeplinkInfo.callId, callType: deeplinkInfo.callType)
                    appState.deeplinkInfo = .empty
                }
            }
    }

    private func joinCallIfNeeded(with callId: String, callType: String = .default) {
        guard !callId.isEmpty, viewModel.callingState == .idle else {
            return
        }

        Task {
            await MainActor.run {
                Task {
                    try await streamVideo.connect()
                    viewModel.joinCall(callId: callId, type: callType)
                }
            }
        }
    }
}
