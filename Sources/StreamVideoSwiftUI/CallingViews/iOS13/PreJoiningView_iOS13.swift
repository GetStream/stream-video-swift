//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS, introduced: 13, obsoleted: 14)
public struct LobbyView_iOS13<Factory: ViewFactory>: View {

    @ObservedObject var callViewModel: CallViewModel
    @BackportStateObject var viewModel: LobbyViewModel
    @BackportStateObject var microphoneChecker: MicrophoneChecker

    var viewFactory: Factory
    var callId: String
    var callType: String
    @Binding var callSettings: CallSettings
    var onJoinCallTap: () -> Void
    var onCloseLobby: () -> Void
    
    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
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
        let microphoneCheckerInstance = MicrophoneChecker()
        _microphoneChecker = BackportStateObject(wrappedValue: microphoneCheckerInstance)
        _callSettings = callSettings
        self.viewFactory = viewFactory
        self.callId = callId
        self.callType = callType
        self.onJoinCallTap = onJoinCallTap
        self.onCloseLobby = onCloseLobby
    }
    
    public var body: some View {
        LobbyContentView(
            viewModel: viewModel,
            microphoneChecker: microphoneChecker,
            viewFactory: viewFactory,
            callId: callId,
            callType: callType,
            callSettings: $callSettings,
            onJoinCallTap: onJoinCallTap,
            onCloseLobby: onCloseLobby
        )
        .onChange(of: callSettings) { viewModel.didUpdate(callSettings: $0) }
    }
}
