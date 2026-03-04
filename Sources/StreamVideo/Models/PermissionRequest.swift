//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public struct PermissionRequest: @unchecked Sendable, Identifiable {
    public let id: UUID = .init()
    public let permission: String
    public let user: User
    public let requestedAt: Date
    let onReject: (PermissionRequest) -> Void
    
    public init(
        permission: String,
        user: User,
        requestedAt: Date,
        onReject: @escaping (PermissionRequest) -> Void = { _ in }
    ) {
        self.permission = permission
        self.user = user
        self.requestedAt = requestedAt
        self.onReject = onReject
    }
    
    public func reject() {
        onReject(self)
    }
}
