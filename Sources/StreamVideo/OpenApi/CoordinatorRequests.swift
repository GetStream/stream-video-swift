//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

struct JoinCallRequestData {
    let id: String
    let type: String
    let joinCallRequest: JoinCallRequest
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
