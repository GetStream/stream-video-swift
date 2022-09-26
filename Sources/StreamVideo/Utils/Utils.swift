//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

internal extension DispatchQueue {

    static let sdk = DispatchQueue(label: "StreamVideoSDK", qos: .userInitiated)
}

func postNotification(with name: String) {
    NotificationCenter.default.post(name: NSNotification.Name(name), object: nil)
}

public enum CallNotification {
    public static let callEnded = "StreamVideo.Call.Ended"
}
