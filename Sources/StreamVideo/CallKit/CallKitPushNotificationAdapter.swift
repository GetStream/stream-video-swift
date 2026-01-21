//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import PushKit

/// Handles push notifications for CallKit integration.
open class CallKitPushNotificationAdapter: NSObject, PKPushRegistryDelegate, ObservableObject, @unchecked Sendable {

    /// Represents the keys that the Payload dictionary
    public enum PayloadKey: String {
        case stream
        case callCid = "call_cid"
        case displayName = "call_display_name"
        case createdByName = "created_by_display_name"
        case createdById = "created_by_id"
        case video
    }

    /// Represents the content of a VoIP push notification.
    public struct Content: Sendable {
        var cid: String
        var localizedCallerName: String
        var callerId: String
        var hasVideo: Bool

        public init(
            cid: String,
            localizedCallerName: String,
            callerId: String,
            hasVideo: Bool
        ) {
            self.cid = cid
            self.localizedCallerName = localizedCallerName
            self.callerId = callerId
            self.hasVideo = hasVideo
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
        log.info("CallKit notifications are not supported on simulator.", subsystems: .callKit)
        #else
        registry.delegate = self
        registry.desiredPushTypes = [.voIP]
        #endif
    }

    /// Unregisters for push notifications.
    open func unregister() {
        #if targetEnvironment(simulator) && !STREAM_TESTS
        log.info("CallKit notifications are not supported on simulator.", subsystems: .callKit)
        #else
        registry.delegate = nil
        registry.desiredPushTypes = []
        deviceToken = ""
        #endif
    }

    /// Delegate method called when the device receives updated push credentials.
    open func pushRegistry(
        _ registry: PKPushRegistry,
        didUpdate pushCredentials: PKPushCredentials,
        for type: PKPushType
    ) {
        let deviceToken = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
        log.debug("Device token updated to: \(deviceToken)", subsystems: .callKit)
        self.deviceToken = deviceToken
    }

    /// Delegate method called when the push token becomes invalid for VoIP push notifications.
    open func pushRegistry(
        _ registry: PKPushRegistry,
        didInvalidatePushTokenFor type: PKPushType
    ) {
        log.debug("Device token invalidated.", subsystems: .callKit)
        deviceToken = ""
    }

    /// Delegate method called when the device receives a VoIP push notification.
    open nonisolated func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping () -> Void
    ) {
        defer { completion() }
        guard type == .voIP else { return }
        
        let content = decodePayload(payload)

        log
            .debug(
                "Received VoIP push notification with cid:\(content.cid) callerId:\(content.callerId) callerName:\(content.localizedCallerName)."
            )

        callKitService.reportIncomingCall(
            content.cid,
            localizedCallerName: content.localizedCallerName,
            callerId: content.callerId,
            hasVideo: content.hasVideo,
            completion: { error in
                if let error {
                    log.error(error, subsystems: .callKit)
                }
            }
        )
    }

    /// Decodes push notification Payload to a type that the CallKit implementation can use.
    open func decodePayload(
        _ payload: PKPushPayload
    ) -> Content {
        func string(from: [String: Any], key: PayloadKey, fallback: String) -> String {
            from[key.rawValue] as? String ?? fallback
        }

        guard
            let streamDict = payload.dictionaryPayload[PayloadKey.stream.rawValue] as? [String: Any]
        else {
            return .init(
                cid: "unknown",
                localizedCallerName: defaultCallText,
                callerId: defaultCallText,
                hasVideo: false
            )
        }

        let cid = string(from: streamDict, key: .callCid, fallback: "unknown")

        let displayName = string(from: streamDict, key: .displayName, fallback: "")
        /// If no displayName ("display_name", "name", "title") was set, we default to the creator's name.
        let localizedCallerName = displayName.isEmpty
            ? string(from: streamDict, key: .createdByName, fallback: defaultCallText)
            : displayName
        
        let callerId = string(
            from: streamDict,
            key: .createdById,
            fallback: defaultCallText
        )

        let hasVideo: Bool = {
            if let booleanValue = streamDict[PayloadKey.video.rawValue] as? Bool {
                return booleanValue
            } else if let stringValue = streamDict[PayloadKey.video.rawValue] as? String {
                return stringValue == "true"
            } else {
                return false
            }
        }()

        return .init(
            cid: cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: hasVideo
        )
    }
}

extension CallKitPushNotificationAdapter: InjectionKey {
    /// Provides the current instance of `CallKitPushNotificationAdapter`.
    public nonisolated(unsafe) static var currentValue: CallKitPushNotificationAdapter = .init()
}

extension InjectedValues {
    /// A property wrapper to access the `CallKitPushNotificationAdapter` instance.
    public var callKitPushNotificationAdapter: CallKitPushNotificationAdapter {
        get { Self[CallKitPushNotificationAdapter.self] }
        set { Self[CallKitPushNotificationAdapter.self] = newValue }
    }
}
