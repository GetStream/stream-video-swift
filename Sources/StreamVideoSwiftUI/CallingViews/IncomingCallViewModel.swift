//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo

@MainActor
public class IncomingViewModel: ObservableObject {
    
    @Injected(\.streamVideo) var streamVideo
    
    public private(set) var callInfo: IncomingCall
    
    var callParticipants: [Member] {
        callInfo.members.filter { $0.id != streamVideo.user.id }
    }
    
    public init(callInfo: IncomingCall) {
        self.callInfo = callInfo
    }
}
