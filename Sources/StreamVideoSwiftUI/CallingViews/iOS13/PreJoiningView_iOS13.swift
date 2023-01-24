//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import SwiftUI

@available(iOS, introduced: 13, obsoleted: 14)
struct PreJoiningView_iOS13: View {
    
    @ObservedObject var callViewModel: CallViewModel
    @BackportStateObject var viewModel = PreJoiningViewModel()
    @BackportStateObject var microphoneChecker = MicrophoneChecker()
    
    var callId: String
    var callType: String?
    var callParticipants: [User]
        
    public init(
        callViewModel: CallViewModel,
        callId: String,
        callType: String?,
        callParticipants: [User]
    ) {
        _callViewModel = ObservedObject(wrappedValue: callViewModel)
        self.callId = callId
        self.callType = callType
        self.callParticipants = callParticipants
    }
    
    public var body: some View {
        PreJoiningContentView(
            callViewModel: callViewModel,
            viewModel: viewModel,
            microphoneChecker: microphoneChecker,
            callId: callId,
            callType: callType,
            callParticipants: callParticipants
        )
    }
}
