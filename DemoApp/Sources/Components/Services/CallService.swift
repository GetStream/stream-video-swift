//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

final class CallService {

    static let shared = CallService()
    
    let callService = CallKitService()
    lazy var voIPPushService = makeVoIPPushService()

    private init() {}

    func registerForIncomingCalls() {
    #if targetEnvironment(simulator)
        log.info("CallKit notifications not working on a simulator")
    #else
        voIPPushService.registerForVoIPPushes()
    #endif
    }

    private func makeVoIPPushService() -> VoIPPushService {
        let defaultCallText = "Unknown Caller"

        return .init(voIPTokenHandler: AppState.shared.unsecureRepository) { [weak self] payload, type, completion in
            guard let self = self else {
                completion()
                return
            }

            let streamDict = payload.dictionaryPayload["stream"] as? [String: Any]
            let callCid = streamDict?["call_cid"] as? String ?? "unknown"
            let createdByName = streamDict?["created_by_display_name"] as? String ?? defaultCallText
            let createdById = streamDict?["created_by_id"] as? String ?? defaultCallText
            
            self.callService.reportIncomingCall(
                callCid: callCid,
                displayName: createdByName,
                callerId: createdById
            ) { _ in
                completion()
            }
        }
    }
}
