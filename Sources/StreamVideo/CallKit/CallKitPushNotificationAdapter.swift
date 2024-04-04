//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import PushKit

/// Handles push notifications for CallKit integration.
open class CallKitPushNotificationAdapter: NSObject, PKPushRegistryDelegate, ObservableObject {

    /// Represents the content of a VoIP push notification.
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

    @Injected(\.callKitService) private var callKitService

    /// The push registry used for VoIP push notifications.
    open private(set) lazy var registry: PKPushRegistry = .init(queue: .init(label: "io.getstream.voip"))

    /// The default text for calls when the caller information is not available.
    open var defaultCallText: String = "Unknown Caller"

    /// The device token for push notifications.
    @Published public private(set) var deviceToken: String = ""

    /// Registers for push notifications.
    open func register() {
        #if targetEnvironment(simulator) && !STREAM_TESTS
        log.info("CallKit notifications are not supported on simulator.")
        #else
        registry.delegate = self
        registry.desiredPushTypes = [.voIP]
        #endif
    }

    /// Unregisters for push notifications.
    open func unregister() {
        #if targetEnvironment(simulator) && !STREAM_TESTS
        log.info("CallKit notifications are not supported on simulator.")
        #else
        registry.delegate = nil
        registry.desiredPushTypes = []
        #endif
    }

    /// Delegate method called when the device receives updated push credentials.
    open func pushRegistry(
        _ registry: PKPushRegistry,
        didUpdate pushCredentials: PKPushCredentials,
        for type: PKPushType
    ) {
        let deviceToken = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
        log.debug("Device token updated to: \(deviceToken)")
        self.deviceToken = deviceToken
    }

    /// Delegate method called when the push token becomes invalid for VoIP push notifications.
    open func pushRegistry(
        _ registry: PKPushRegistry,
        didInvalidatePushTokenFor type: PKPushType
    ) {
        log.debug("Device token invalidated.")
        deviceToken = ""
    }

    /// Delegate method called when the device receives a VoIP push notification.
    open func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping () -> Void
    ) {
        guard type == .voIP else { return }
        
        let content = StreamVoIPPushNotificationContent(
            from: payload,
            defaultCallText: defaultCallText
        )
        log
            .debug(
                "Received VoIP push notification with cid:\(content.cid) callerId:\(content.callerId) callerName:\(content.localizedCallerName)."
            )

        callKitService.reportIncomingCall(
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
    /// Provides the current instance of `CallKitPushNotificationAdapter`.
    public static var currentValue: CallKitPushNotificationAdapter = .init()
}

extension InjectedValues {
    /// A property wrapper to access the `CallKitPushNotificationAdapter` instance.
    public var callKitPushNotificationAdapter: CallKitPushNotificationAdapter {
        get { Self[CallKitPushNotificationAdapter.self] }
        set { Self[CallKitPushNotificationAdapter.self] = newValue }
    }
}
