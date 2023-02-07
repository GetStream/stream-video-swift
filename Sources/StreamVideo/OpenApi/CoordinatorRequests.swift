//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

struct JoinCallRequest {
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
    let username: String
    let role: String
}

struct PermissionsRequest {
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
