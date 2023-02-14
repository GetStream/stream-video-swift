//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public struct CallCapability: RawRepresentable, ExpressibleByStringLiteral, Hashable {
    public var rawValue: String

    public init?(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        rawValue = value
    }

    public static let joinCall: Self = "join-call"
    public static let readCall: Self = "read-call"
    public static let createCall: Self = "create-call"
    public static let joinEndedCall: Self = "join-ended-call"
    public static let updateCall: Self = "update-call"
    public static let updateCallSettings: Self = "update-call-settings"
    public static let screenshare: Self = "screenshare"
    public static let sendVideo: Self = "send-video"
    public static let sendAudio: Self = "send-audio"
    public static let startRecordCall: Self = "start-record-call"
    public static let stopRecordCall: Self = "stop-record-call"
    public static let endCall: Self = "end-call"
    public static let muteUsers: Self = "mute-users"
    public static let updateCallPermissions: Self = "update-call-permissions"
}
