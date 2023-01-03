//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

class CallService {

    private static let defaultCallText = "You are receiving a call"

    static let shared = CallService()

    let callService = CallKitService()

    lazy var voipPushService = VoipPushService(
        voipTokenHandler: UnsecureUserRepository.shared
    ) { [weak self] payload, type, completion in
        let aps = payload.dictionaryPayload["aps"] as? [String: Any]
        let alert = aps?["alert"] as? [String: Any]
        let callCid = alert?["call_cid"] as? String ?? "unknown"
        self?.callService.reportIncomingCall(
            callCid: callCid,
            callInfo: self?.callInfo(from: alert) ?? Self.defaultCallText
        ) { _ in
            completion()
        }
    }

    func registerForIncomingCalls() {
        voipPushService.registerForVoIPPushes()
    }

    private func callInfo(from callPayload: [String: Any]?) -> String {
        guard let userIds = callPayload?["user_ids"] as? String else { return Self.defaultCallText }
        let parts = userIds.components(separatedBy: ",")
        if parts.count == 0 {
            return Self.defaultCallText
        } else if parts.count == 1 {
            return "\(parts[0]) is calling you"
        } else if parts.count == 2 {
            return "\(parts[0]) and \(parts[1]) are calling you"
        } else {
            let othersCount = parts.count - 2
            return "\(parts[0]), \(parts[1]) and \(othersCount) are calling you"
        }
    }
}
