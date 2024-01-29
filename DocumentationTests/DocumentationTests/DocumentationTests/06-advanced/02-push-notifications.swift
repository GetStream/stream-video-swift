import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine
import CallKit
import PushKit

@MainActor
fileprivate func content() {
    container {
        class VoIPPushService: NSObject, PKPushRegistryDelegate {

            @Injected(\.streamVideo) var streamVideo

            private let queue: DispatchQueue
            private let registry: PKPushRegistry
            private let tokenHandler: VoIPTokenHandler

            var onReceiveIncomingPush: VoIPPushHandler

            init(voIPTokenHandler: VoIPTokenHandler, pushHandler: @escaping VoIPPushHandler) {
                self.tokenHandler = voIPTokenHandler
                self.queue = DispatchQueue(label: "io.getstream.voip")
                self.registry = PKPushRegistry(queue: queue)
                self.onReceiveIncomingPush = pushHandler
            }
        }
    }
}
