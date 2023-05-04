//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

class CallService {
    
    private static let defaultCallText = "Unknown Caller"
    
    static let shared = CallService()
    
    let callService = CallKitService()
    
    lazy var voipPushService = VoipPushService(
        voipTokenHandler: UnsecureUserRepository.shared
    ) { [weak self] payload, type, completion in
        let streamDict = payload.dictionaryPayload["stream"] as? [String: Any]
        let callCid = streamDict?["call_cid"] as? String ?? "unknown"
        let createdByName = streamDict?["created_by_display_name"] as? String ?? Self.defaultCallText
        let createdById = streamDict?["created_by_id"] as? String ?? Self.defaultCallText
        self?.callService.reportIncomingCall(
            callCid: callCid,
            displayName: createdByName,
            callerId: createdById
        ) { _ in
            completion()
        }
    }
    
    func registerForIncomingCalls() {
    #if targetEnvironment(simulator)
        log.info("CallKit notifications not working on a simulator")
    #else
        voipPushService.registerForVoIPPushes()
    #endif
    }
}
