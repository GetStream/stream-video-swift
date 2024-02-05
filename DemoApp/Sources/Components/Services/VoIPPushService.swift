//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import PushKit
import StreamVideo

typealias VoIPPushHandler = ((PKPushPayload, PKPushType, () -> Void)) -> Void

final class VoIPPushService: NSObject, PKPushRegistryDelegate {

    @Injected(\.streamVideo) var streamVideo
    
    private let queue: DispatchQueue
    private let registry: PKPushRegistry
    private let tokenHandler: VoIPTokenHandler

    var onReceiveIncomingPush: VoIPPushHandler
    
    init(voIPTokenHandler: VoIPTokenHandler, pushHandler: @escaping VoIPPushHandler) {
        tokenHandler = voIPTokenHandler
        queue = DispatchQueue(label: "io.getstream.voip")
        registry = PKPushRegistry(queue: queue)
        onReceiveIncomingPush = pushHandler
    }
    
    func registerForVoIPPushes() {
        registry.delegate = self
        registry.desiredPushTypes = [.voIP]
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        print(credentials.token)
        let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
        log.debug("pushRegistry deviceToken = \(deviceToken)")
        Task {
            await MainActor.run(body: {
                AppState.shared.voIPPushToken = deviceToken
            })
        }
    }
            
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        log.debug("pushRegistry:didInvalidatePushTokenForType:")
        if let savedToken = tokenHandler.currentVoIPPushToken() {
            Task {
                try await streamVideo.deleteDevice(id: savedToken)
                tokenHandler.save(voIPPushToken: nil)
            }
        }
    }
    
    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping () -> Void
    ) {
        onReceiveIncomingPush((payload, type, completion))
    }
}
