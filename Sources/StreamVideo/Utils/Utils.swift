//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

internal extension DispatchQueue {

    static let sdk = DispatchQueue(label: "StreamVideoSDK", qos: .userInitiated)
}

func postNotification(with name: String, userInfo: [AnyHashable: Any] = [:]) {
    NotificationCenter.default.post(name: NSNotification.Name(name), object: nil, userInfo: userInfo)
}

func callCid(from callId: String, callType: String) -> String {
    "\(callType):\(callId)"
}

public enum CallNotification {
    public static let callEnded = "StreamVideo.Call.Ended"
    public static let participantLeft = "StreamVideo.Call.ParticipantLeft"
}

typealias EventHandling = ((WrappedEvent) -> Void)?

func executeOnMain(_ task: @escaping @MainActor() -> Void) {
    Task {
        await task()
    }
}

func infoPlistValue(for key: String) -> String? {
    Bundle.main.infoDictionary?[key] as? String
}
