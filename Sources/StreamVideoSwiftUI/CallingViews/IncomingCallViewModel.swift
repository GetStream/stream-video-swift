//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo

@MainActor
public class IncomingViewModel: ObservableObject {
    
    @Injected(\.streamVideo) var streamVideo
    
    public private(set) var callInfo: IncomingCall
    
    var callParticipants: [CallParticipant] {
        callInfo.participants
    }
    
    public init(callInfo: IncomingCall) {
        self.callInfo = callInfo
    }
}
