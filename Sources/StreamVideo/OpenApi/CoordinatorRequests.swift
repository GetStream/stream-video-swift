//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

struct JoinCallRequestData {
    let id: String
    let type: String
    let joinCallRequest: JoinCallRequest
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

struct SendReactionRequestData {
    let id: String
    let type: String
    let sendReactionRequest: SendReactionRequest
}

public struct CustomEventRequest {
    public let callId: String
    public let callType: CallType
    public let type: EventType
    public let customData: [String: RawJSON]
    
    public init(
        callId: String,
        callType: CallType,
        type: EventType,
        customData: [String: RawJSON]
    ) {
        self.callId = callId
        self.callType = callType
        self.type = type
        self.customData = customData
    }
}

public struct CallReactionRequest {
    public let callId: String
    public let callType: CallType
    public let reactionType: String
    public let emojiCode: String?
    public let customData: [String: RawJSON]
    
    public init(
        callId: String,
        callType: CallType,
        reactionType: String,
        emojiCode: String? = nil,
        customData: [String : RawJSON]
    ) {
        self.callId = callId
        self.callType = callType
        self.reactionType = reactionType
        self.emojiCode = emojiCode
        self.customData = customData
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
