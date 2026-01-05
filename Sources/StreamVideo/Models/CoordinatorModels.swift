//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public struct FetchingLocationError: Error {}

public enum RecordingState: Sendable {
    case noRecording
    case requested
    case recording
}

public struct CreateCallOptions: Sendable, Hashable {
    public var memberIds: [String]?
    public var members: [MemberRequest]?
    public var custom: [String: RawJSON]?
    public var settings: CallSettingsRequest?
    public var startsAt: Date?
    public var team: String?
    
    public init(
        memberIds: [String]? = nil,
        members: [MemberRequest]? = nil,
        custom: [String: RawJSON]? = nil,
        settings: CallSettingsRequest? = nil,
        startsAt: Date? = nil,
        team: String? = nil
    ) {
        self.memberIds = memberIds
        self.members = members
        self.custom = custom
        self.settings = settings
        self.startsAt = startsAt
        self.team = team
    }
}

public struct Ingress {
    public let rtmp: RTMP
}

public struct RTMP {
    public let address: String
    public let streamKey: String
}
