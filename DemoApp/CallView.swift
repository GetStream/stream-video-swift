//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI
import Intents

struct CallView: View {
    
    @StateObject var viewModel: CallViewModel
    
    @ObservedObject var appState = AppState.shared
    
    init(callId: String? = nil) {
        _viewModel = StateObject(wrappedValue: CallViewModel())
        if let callId = callId, viewModel.callingState == .idle {
            viewModel.joinCall(callId: callId, type: .default)
        }
    }
        
    var body: some View {
        CallHomeView(viewModel: viewModel)
            .modifier(CallModifier(viewFactory: DemoAppViewFactory.shared, viewModel: viewModel))
            .onContinueUserActivity(NSStringFromClass(INStartCallIntent.self), perform: { userActivity in
                    let interaction = userActivity.interaction
                    if let callIntent = interaction?.intent as? INStartCallIntent {

                        let contact = callIntent.contacts?.first

                        guard let name = contact?.personHandle?.value else { return }
                        viewModel.startCall(callId: UUID().uuidString, type: .default, members: [.init(id: name)], ring: true)
                    }
                }
            )
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
