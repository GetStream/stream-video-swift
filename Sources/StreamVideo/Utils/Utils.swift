//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

internal extension DispatchQueue {

    static let sdk = DispatchQueue(label: "StreamVideoSDK", qos: .userInitiated)
}

func postNotification(with name: String, userInfo: [AnyHashable: Any] = [:]) {
    NotificationCenter.default.post(name: NSNotification.Name(name), object: nil, userInfo: userInfo)
}

public enum CallNotification {
    public static let callEnded = "StreamVideo.Call.Ended"
    public static let participantLeft = "StreamVideo.Call.ParticipantLeft"
}
