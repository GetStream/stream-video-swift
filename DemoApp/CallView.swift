//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI
import Intents

struct CallView: View {

    private var callId: String
    @Injected(\.streamVideo) var streamVideo
    @StateObject var viewModel: CallViewModel
    @ObservedObject var appState = AppState.shared
    
    init(callId: String) {
        _viewModel = StateObject(wrappedValue: CallViewModel())
        self.callId = callId
    }
        
    var body: some View {
        HomeView(viewModel: viewModel)
            .modifier(CallModifier(viewFactory: DemoAppViewFactory.shared, viewModel: viewModel))
            .onContinueUserActivity(NSStringFromClass(INStartCallIntent.self), perform: { userActivity in
                    let interaction = userActivity.interaction
                    if let callIntent = interaction?.intent as? INStartCallIntent {

                        let contact = callIntent.contacts?.first

                        guard let name = contact?.personHandle?.value else { return }
                        let member = Member(user: User(id: name), role: "user")
                        viewModel.startCall(callId: UUID().uuidString, type: .default, members: [member], ring: true)
                    }
                }
            )
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

struct CallHomeView: View {
    
    @ObservedObject var viewModel: CallViewModel
    
    var body: some View {
        if ProcessInfo.processInfo.arguments.contains("STREAM_TESTS") {
            HomeView(viewModel: viewModel)
        } else {
            StreamCallingView(viewModel: viewModel)
        }
    }
    
}
