//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import SwiftUI

@available(iOS, introduced: 13, obsoleted: 14)
struct LobbyView_iOS13: View {
    
    @ObservedObject var callViewModel: CallViewModel
    @BackportStateObject var viewModel: LobbyViewModel
    @Injected(\.microphoneChecker) var microphoneChecker: MicrophoneChecker
    
    var callId: String
    var callType: String
    @Binding var callSettings: CallSettings
    var onJoinCallTap: () -> ()
    var onCloseLobby: () -> ()
    
    public init(
        callViewModel: CallViewModel,
        callId: String,
        callType: String,
        callSettings: Binding<CallSettings>,
        onJoinCallTap: @escaping () -> (),
        onCloseLobby: @escaping () -> ()
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
