//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

struct JoinCallRequestData {
    let id: String
    let type: String
    let getOrCreateCallRequest: GetOrCreateCallRequest
}

struct SelectEdgeServerRequestData {
    let id: String
    let type: String
    let getCallEdgeServerRequest: GetCallEdgeServerRequest
}

struct EventRequestData {
    let id: String
    let type: String
    let sendEventRequest: SendEventRequest
}

struct EndCallRequestData {
    let id: String
    let type: String
}

struct ConnectRequestData: Codable {
    let token: String
    let user_details: UserDetailsPayload
}

struct UserDetailsPayload: Codable {
    let id: String
    // TODO: revert this when fixed on the backend.
//    let name: String
//    let image: String?
    let Custom: [String: AnyCodable]
}

struct RequestPermissionsRequestData {
    let id: String
    let type: String
    let requestPermissionRequest: RequestPermissionRequest
}

struct UpdatePermissionsRequestData {
    let id: String
    let type: String
    let updateUserPermissionsRequest: UpdateUserPermissionsRequest
}

struct MuteUsersRequestData {
    let id: String
    let type: String
    let muteUsersRequest: MuteUsersRequest
}

struct BlockUserRequestData {
    let id: String
    let type: String
    let blockUserRequest: BlockUserRequest
}

struct UnblockUserRequestData {
    let id: String
    let type: String
    let unblockUserRequest: UnblockUserRequest
}

struct HealthCheck: HealthCheckEvent, Codable {
    let connection_id: String
}

public struct CustomEventRequest {
    public let callId: String
    public let callType: CallType
    public let type: EventType
    public let extraData: [String: RawJSON]
    
    public init(
        callId: String,
        callType: CallType,
        type: EventType,
        extraData: [String: RawJSON]
    ) {
        self.callId = callId
        self.callType = callType
        self.type = type
        self.extraData = extraData
    }
}

public struct MuteRequest {
    public let userIds: [String]
    public let muteAllUsers: Bool
    public let audio: Bool
    public let video: Bool
    public let screenshare: Bool
    
    public init(
        userIds: [String],
        muteAllUsers: Bool,
        audio: Bool,
        video: Bool,
        screenshare: Bool
    ) {
        self.userIds = userIds
        self.muteAllUsers = muteAllUsers
        self.audio = audio
        self.video = video
        self.screenshare = screenshare
    }
}

extension DatacenterResponse: @unchecked Sendable {}
