//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import PushKit
import StreamVideo

typealias VoipPushHandler = ((PKPushPayload, PKPushType, () -> Void)) -> ()

class VoipPushService: NSObject, PKPushRegistryDelegate {
    
    @Injected(\.streamVideo) var streamVideo
    
    private let voipQueue: DispatchQueue
    private let voipRegistry: PKPushRegistry
    private let voipTokenHandler: VoipTokenHandler
    private lazy var voipNotificationsController = streamVideo.makeVoipNotificationsController()
    
    var onReceiveIncomingPush: VoipPushHandler
    
    init(voipTokenHandler: VoipTokenHandler, pushHandler: @escaping VoipPushHandler) {
        self.voipTokenHandler = voipTokenHandler
        self.voipQueue = DispatchQueue(label: "io.getstream.voip")
        self.voipRegistry = PKPushRegistry(queue: voipQueue)        
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
        voipNotificationsController.addDevice(with: deviceToken)
        voipTokenHandler.save(voipPushToken: deviceToken)
    }
            
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        log.debug("pushRegistry:didInvalidatePushTokenForType:")
        if let savedToken = voipTokenHandler.currentVoipPushToken() {
            voipNotificationsController.removeDevice(with: savedToken)
            voipTokenHandler.save(voipPushToken: nil)
        }
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
