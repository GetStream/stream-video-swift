//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// All possibility of string to use
public final class OwnCapability: RawRepresentable, Decodable, CustomStringConvertible, Hashable, Sendable {
    public let rawValue: String

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let blockUsers = OwnCapability(rawValue: "block-users")
    public static let changeMaxDuration = OwnCapability(rawValue: "change-max-duration")
    public static let createCall = OwnCapability(rawValue: "create-call")
    public static let createReaction = OwnCapability(rawValue: "create-reaction")
    public static let enableNoiseCancellation = OwnCapability(rawValue: "enable-noise-cancellation")
    public static let endCall = OwnCapability(rawValue: "end-call")
    public static let joinBackstage = OwnCapability(rawValue: "join-backstage")
    public static let joinCall = OwnCapability(rawValue: "join-call")
    public static let joinEndedCall = OwnCapability(rawValue: "join-ended-call")
    public static let kickUser = OwnCapability(rawValue: "kick-user")
    public static let muteUsers = OwnCapability(rawValue: "mute-users")
    public static let pinForEveryone = OwnCapability(rawValue: "pin-for-everyone")
    public static let readCall = OwnCapability(rawValue: "read-call")
    public static let removeCallMember = OwnCapability(rawValue: "remove-call-member")
    public static let screenshare = OwnCapability(rawValue: "screenshare")
    public static let sendAudio = OwnCapability(rawValue: "send-audio")
    public static let sendClosedCaptionsCall = OwnCapability(rawValue: "send-closed-captions-call")
    public static let sendVideo = OwnCapability(rawValue: "send-video")
    public static let startBroadcastCall = OwnCapability(rawValue: "start-broadcast-call")
    public static let startClosedCaptionsCall = OwnCapability(rawValue: "start-closed-captions-call")
    public static let startFrameRecordCall = OwnCapability(rawValue: "start-frame-record-call")
    public static let startIndividualRecordCall = OwnCapability(rawValue: "start-individual-record-call")
    public static let startRawRecordCall = OwnCapability(rawValue: "start-raw-record-call")
    public static let startRecordCall = OwnCapability(rawValue: "start-record-call")
    public static let startTranscriptionCall = OwnCapability(rawValue: "start-transcription-call")
    public static let stopBroadcastCall = OwnCapability(rawValue: "stop-broadcast-call")
    public static let stopClosedCaptionsCall = OwnCapability(rawValue: "stop-closed-captions-call")
    public static let stopFrameRecordCall = OwnCapability(rawValue: "stop-frame-record-call")
    public static let stopIndividualRecordCall = OwnCapability(rawValue: "stop-individual-record-call")
    public static let stopRawRecordCall = OwnCapability(rawValue: "stop-raw-record-call")
    public static let stopRecordCall = OwnCapability(rawValue: "stop-record-call")
    public static let stopTranscriptionCall = OwnCapability(rawValue: "stop-transcription-call")
    public static let updateCall = OwnCapability(rawValue: "update-call")
    public static let updateCallMember = OwnCapability(rawValue: "update-call-member")
    public static let updateCallPermissions = OwnCapability(rawValue: "update-call-permissions")
    public static let updateCallSettings = OwnCapability(rawValue: "update-call-settings")
}
