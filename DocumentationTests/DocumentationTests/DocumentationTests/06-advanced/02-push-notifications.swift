//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CallKit
import Combine
import PushKit
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import UserNotifications

typealias VoIPPushHandler = ((PKPushPayload, PKPushType, () -> Void)) -> Void

@MainActor
private func content() {
    container {
        final class VoIPPushService: NSObject, PKPushRegistryDelegate, @unchecked Sendable {

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

            func registerForVoIPPushes() {
                self.registry.delegate = self
                self.registry.desiredPushTypes = [.voIP]
            }

            func unregisterForVoIPPushes() {
                self.registry.delegate = nil
                self.registry.desiredPushTypes = []
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
                self.onReceiveIncomingPush((payload, type, completion))
            }
        }

        final class CallService: @unchecked Sendable {

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

            private func unregisterForIncomingCalls() {
                #if targetEnvironment(simulator)
                log.info("CallKit notifications not working on a simulator")
                #else
                voIPPushService.unregisterForVoIPPushes()
                #endif
            }

            private func makeVoIPPushService() -> VoIPPushService {
                let defaultCallText = "Unknown Caller"

                return .init(voIPTokenHandler: AppState.shared.unsecureRepository) { [weak self] payload, _, completion in
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
    }

    container {
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse,
            withCompletionHandler completionHandler: @escaping () -> Void
        ) {
            let userInfo = response.notification.request.content.userInfo

            // Extract call information from the payload
            if let streamDict = userInfo["stream"] as? [String: Any],
               let callCid = streamDict["call_cid"] as? String {
                // Parse call type and id from cid (format: "type:id")
                let components = callCid.split(separator: ":")
                if components.count == 2 {
                    let callType = String(components[0])
                    let callId = String(components[1])
                    // Navigate to the call
                    _ = (callType, callId)
                }
            }

            completionHandler()
        }
    }
}
