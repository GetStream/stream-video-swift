//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

class PermissionsMiddleware: EventMiddleware {
    
    var onPermissionRequestEvent: ((PermissionRequest) -> Void)?
    var onPermissionsUpdatedEvent: ((PermissionsUpdated) -> Void)?
    
    func handle(event: Event) -> Event? {
        if let callPermissionRequest = event as? CallPermissionRequest {
            let permissionRequest = callPermissionRequest.toPermissionRequest()
            onPermissionRequestEvent?(permissionRequest)
        } else if let callPermissionsUpdated = event as? CallPermissionsUpdated {
            let permissionsUpdated = callPermissionsUpdated.toPermissionsUpdated()
            onPermissionsUpdatedEvent?(permissionsUpdated)
        }
        return event
    }
}

public struct PermissionRequest: Event, Sendable {
    public let callCid: String
    public let createdAt: Date?
    public let permissions: [String]
    public let type: String?
    public let user: User
}

public struct PermissionsUpdated: Event, Sendable {
    public let callCid: String
    public let ownCapabilities: [String]
    public let type: String?
    public let user: User
}

extension CallPermissionRequest {
    
    func toPermissionRequest() -> PermissionRequest {
        var imageUrl: URL?
        if let image = user.image {
            imageUrl = URL(string: image)
        }
        return PermissionRequest(
            callCid: callCid,
            createdAt: createdAt,
            permissions: permissions,
            type: type,
            user: User(id: user.id, name: user.name ?? user.id, imageURL: imageUrl)
        )
    }
}

extension CallPermissionsUpdated {
    
    func toPermissionsUpdated() -> PermissionsUpdated {
        var imageUrl: URL?
        if let image = user.image {
            imageUrl = URL(string: image)
        }
        return PermissionsUpdated(
            callCid: callCid,
            ownCapabilities: ownCapabilities,
            type: type,
            user: User(id: user.id, name: user.name ?? user.id, imageURL: imageUrl)
        )
    }
}
