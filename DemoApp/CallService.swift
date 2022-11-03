//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

class CallService {
    
    static let shared = CallService()
    
    let callService = CallKitService()
    
    lazy var voipPushService = VoipPushService(
        voipTokenHandler: UnsecureUserRepository.shared
    ) { [weak self] payload, type, completion in
        guard let self = self,
              let callCid = payload.dictionaryPayload["callCid"] as? String else {
            return
        }
        self.callService.reportIncomingCall(callCid: callCid) { _ in
            completion()
        }
    }
    
    func registerForIncomingCalls() {
        voipPushService.registerForVoIPPushes()
    }
    
}
