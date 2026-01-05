//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

internal extension DispatchQueue {

    static let sdk = DispatchQueue(label: "StreamVideoSDK", qos: .userInitiated)
}

func postNotification(
    with name: String,
    object: Any? = nil,
    userInfo: [AnyHashable: Any] = [:]
) {
    NotificationCenter.default.post(
        name: NSNotification.Name(name),
        object: object,
        userInfo: userInfo
    )
}

public func callCid(from callId: String, callType: String) -> String {
    "\(callType):\(callId)"
}

public enum CallNotification {
    public static let callEnded = "StreamVideo.Call.Ended"
    public static let participantLeft = "StreamVideo.Call.ParticipantLeft"
}

struct EventHandler {
    var handler: ((WrappedEvent) -> Void)
    var cancel: () -> Void
}

func infoPlistValue(for key: String) -> String? {
    Bundle.main.infoDictionary?[key] as? String
}
