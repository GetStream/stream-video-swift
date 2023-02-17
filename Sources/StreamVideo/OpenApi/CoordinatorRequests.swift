//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

struct JoinCallRequestDto {
    let id: String
    let type: String
    let getOrCreateCallRequest: GetOrCreateCallRequest
}

struct SelectEdgeServerRequest {
    let id: String
    let type: String
    let getCallEdgeServerRequest: GetCallEdgeServerRequest
}

struct EventRequest {
    let id: String
    let type: String
    let sendEventRequest: SendEventRequest
}

struct EndCallRequest {
    let id: String
    let type: String
}

struct ConnectRequest: Codable {
    let token: String
    let user_details: UserDetailsPayload
}

struct UserDetailsPayload: Codable {
    let id: String
    let name: String
    let custom: [String: String]
}

struct RequestPermissionsRequest {
    let id: String
    let type: String
    let requestPermissionRequest: RequestPermissionRequest
}

struct UpdatePermissionsRequest {
    let id: String
    let type: String
    let updateUserPermissionsRequest: UpdateUserPermissionsRequest
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
