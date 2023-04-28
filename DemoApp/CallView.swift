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
        HomeView(viewModel: viewModel)
            .modifier(CallModifier(viewModel: viewModel))
            .onContinueUserActivity(
                NSStringFromClass(INStartCallIntent.self), perform: { userActivity in
                    let interaction = userActivity.interaction
                    if let callIntent = interaction?.intent as? INStartCallIntent {
                        
                        let contact = callIntent.contacts?.first
                        
                        let contactHandle = contact?.personHandle
                        
                        if let phoneNumber = contactHandle?.value {
                            print(phoneNumber)
                            // Your Call Logic
                        }
                    }
                }
            )
    }
}
