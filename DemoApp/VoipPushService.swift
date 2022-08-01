//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import PushKit
import StreamVideo

typealias VoipPushHandler = ((PKPushPayload, PKPushType, () -> Void)) -> ()

class VoipPushService: NSObject, PKPushRegistryDelegate {
    
    let voipRegistry = PKPushRegistry(queue: nil)
    
    var onReceiveIncomingPush: VoipPushHandler
    
    init(pushHandler: @escaping VoipPushHandler) {
        self.onReceiveIncomingPush = pushHandler
    }
    
    func registerForVoIPPushes() {
        self.voipRegistry.delegate = self
        self.voipRegistry.desiredPushTypes = [.voIP]
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        print(credentials.token)
        let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
        log.debug("pushRegistry deviceToken = \(deviceToken)")
    }
            
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        log.debug("pushRegistry:didInvalidatePushTokenForType:")
    }
    
    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping () -> Void
    ) {
        self.onReceiveIncomingPush((payload, type, completion))
    }
}
