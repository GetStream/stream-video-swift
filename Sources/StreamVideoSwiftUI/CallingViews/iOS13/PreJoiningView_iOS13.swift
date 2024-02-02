//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS, introduced: 13, obsoleted: 14)
struct LobbyView_iOS13: View {
    
    @ObservedObject var callViewModel: CallViewModel
    @BackportStateObject var viewModel: LobbyViewModel
    @BackportStateObject var microphoneChecker = MicrophoneChecker()
    
    var callId: String
    var callType: String
    @Binding var callSettings: CallSettings
    var onJoinCallTap: () -> Void
    var onCloseLobby: () -> Void
    
    public init(
        callViewModel: CallViewModel,
        callId: String,
        callType: String,
        callSettings: Binding<CallSettings>,
        onJoinCallTap: @escaping () -> Void,
        onCloseLobby: @escaping () -> Void
    ) {
        _callViewModel = ObservedObject(wrappedValue: callViewModel)
        _viewModel = BackportStateObject(
            wrappedValue: LobbyViewModel(
                callType: callType,
                callId: callId
            )
        )
        _callSettings = callSettings
        self.callId = callId
        self.callType = callType
        self.onJoinCallTap = onJoinCallTap
        self.onCloseLobby = onCloseLobby
    }
    
    public var body: some View {
        LobbyContentView(
            viewModel: viewModel,
            microphoneChecker: microphoneChecker,
            callId: callId,
            callType: callType,
            callSettings: $callSettings,
            onJoinCallTap: onJoinCallTap,
            onCloseLobby: onCloseLobby
        )
    }
}
