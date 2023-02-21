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
    let name: String
    let image: String?
    let custom: [String: AnyCodable]
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

extension DatacenterResponse: @unchecked Sendable {}
