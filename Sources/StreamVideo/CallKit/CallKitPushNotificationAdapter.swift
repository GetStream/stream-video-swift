//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import PushKit

open class CallKitPushNotificationAdapter: NSObject, PKPushRegistryDelegate, ObservableObject {

    fileprivate struct StreamVoIPPushNotificationContent {
        var cid: String
        var localizedCallerName: String
        var callerId: String

        init(from payload: PKPushPayload, defaultCallText: String) {
            let streamDict = payload.dictionaryPayload["stream"] as? [String: Any]
            cid = streamDict?["call_cid"] as? String ?? "unknown"
            localizedCallerName = streamDict?["created_by_display_name"] as? String ?? defaultCallText
            callerId = streamDict?["created_by_id"] as? String ?? defaultCallText
        }
    }

    @Injected(\.streamVideo) private var streamVideo
    @Injected(\.callKitAdapter) private var callKitAdapter

    open private(set) lazy var registry: PKPushRegistry = .init(queue: .init(label: "io.getstream.voip"))

    open var defaultCallText: String = "Unknown Caller"

    @Published public private(set) var deviceToken: String = ""

    open func register() {
        registry.delegate = self
        registry.desiredPushTypes = [.voIP]
    }

    open func unregister() {
        registry.delegate = nil
        registry.desiredPushTypes = []
    }

    open func pushRegistry(
        _ registry: PKPushRegistry,
        didUpdate pushCredentials: PKPushCredentials,
        for type: PKPushType
    ) {
        let deviceToken = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
        log.debug("Device token updated to: \(deviceToken)")
        self.deviceToken = deviceToken
    }

    open func pushRegistry(
        _ registry: PKPushRegistry,
        didInvalidatePushTokenFor type: PKPushType
    ) {
        log.debug("Device token invalidated.")
        guard !deviceToken.isEmpty else {
            return
        }

        let deviceToken = self.deviceToken
        Task {
            try await streamVideo.deleteDevice(id: deviceToken)
            log.debug("VoIP push device for \(deviceToken) was deleted.")
            self.deviceToken = ""
        }
    }

    open func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping () -> Void
    ) {
        let content = StreamVoIPPushNotificationContent(
            from: payload,
            defaultCallText: defaultCallText
        )
        log
            .debug(
                "Received VoIP push notification with cid:\(content.cid) callerId:\(content.callerId) callerName:\(content.localizedCallerName)."
            )
        callKitAdapter.reportIncomingCall(
            content.cid,
            localizedCallerName: content.localizedCallerName,
            callerId: content.callerId,
            completion: { error in
                if let error {
                    log.error(error)
                }
                completion()
            }
        )
    }
}

extension CallKitPushNotificationAdapter: InjectionKey {
    public static var currentValue: CallKitPushNotificationAdapter = .init()
}

extension InjectedValues {
    public var callKitPushNotificationAdapter: CallKitPushNotificationAdapter {
        get { Self[CallKitPushNotificationAdapter.self] }
        set { Self[CallKitPushNotificationAdapter.self] = newValue }
    }
}
