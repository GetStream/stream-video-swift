//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

class CallService {
    
    static let shared = CallService()
    
    let callService = CallKitService()
    
    lazy var voipPushService = VoipPushService { [weak self] payload, type, completion in
        guard let self = self else { return }
        self.callService.reportIncomingCall { _ in
            completion()
        }
    }
    
    func registerForIncomingCalls() {
        voipPushService.registerForVoIPPushes()
    }
    
}
