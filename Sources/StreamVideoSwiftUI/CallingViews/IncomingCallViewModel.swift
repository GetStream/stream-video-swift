//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo

@MainActor
public class IncomingViewModel: ObservableObject {
    
    @Injected(\.streamVideo) var streamVideo
    
    public private(set) var callInfo: IncomingCall
    
    var callParticipants: [CallParticipant] {
        callInfo.participants.filter { $0.userId != streamVideo.user.id }
    }
    
    public init(callInfo: IncomingCall) {
        self.callInfo = callInfo
    }
}
