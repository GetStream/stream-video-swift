//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

extension CallSettingsResponse: @unchecked Sendable {}
extension ModelResponse: @unchecked Sendable {}
extension AcceptCallResponse: @unchecked Sendable {}
extension RejectCallResponse: @unchecked Sendable {}
extension CallResponse: @unchecked Sendable {}
extension OwnCapability: @unchecked Sendable {}
extension MemberRequest: @unchecked Sendable {}
extension MemberResponse: @unchecked Sendable {}
extension UpdateCallMembersResponse: @unchecked Sendable {}
extension CallSettingsRequest: @unchecked Sendable {}
extension JoinCallResponse: @unchecked Sendable {}

public struct FetchingLocationError: Error {}

public enum RecordingState {
    case noRecording
    case requested
    case recording
}

public struct CreateCallOptions: Sendable {
    public var memberIds: [String]?
    public var members: [MemberRequest]?
    public var custom: [String: RawJSON]?
    public var settings: CallSettingsRequest?
    public var startsAt: Date?
    public var team: String?
    
    public init(
        memberIds: [String]? = nil,
        members: [MemberRequest]? = nil,
        custom: [String : RawJSON]? = nil,
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
