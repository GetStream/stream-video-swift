//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public class PermissionsController {
    
    private let callCoordinatorController: CallCoordinatorController
    private let currentUser: User
    
    var onPermissionRequestEvent: ((PermissionRequest) -> Void)?
    var onPermissionsUpdatedEvent: ((PermissionsUpdated) -> Void)?
    
    private var coordinatorClient: CoordinatorClient {
        callCoordinatorController.coordinatorClient
    }
    
    init(
        callCoordinatorController: CallCoordinatorController,
        currentUser: User
    ) {
        self.callCoordinatorController = callCoordinatorController
        self.currentUser = currentUser
    }
    
    public func currentUserCanRequestPermissions(_ permissions: [Permission]) -> Bool {
        guard let callSettings = callCoordinatorController.currentCallSettings?.callSettings else {
            return false
        }
        for permission in permissions {
            if permission.rawValue == Permission.sendAudio.rawValue
                && callSettings.audio.accessRequestEnabled == false {
                return false
            } else if permission.rawValue == Permission.sendVideo.rawValue
                && callSettings.video.accessRequestEnabled == false {
                return false
            } else if permission.rawValue == Permission.screenshare.rawValue
                && callSettings.screensharing.accessRequestEnabled == false {
                return false
            }
        }
        return true
    }
    
    public func request(
        permissions: [Permission],
        callId: String,
        callType: String
    ) async throws {
        guard currentUserCanRequestPermissions(permissions) else {
            // TODO: throw correct error.
            throw ClientError.Unexpected()
        }
        let request = RequestPermissionRequest(
            permissions: permissions.map(\.rawValue)
        )
        let permissionsRequest = RequestPermissionsRequest(
            id: callId,
            type: callType,
            requestPermissionRequest: request
        )
        _ = try await coordinatorClient.requestPermission(with: permissionsRequest)
    }
    
    public func currentUserCanModifyPermissions(
        _ permissions: [String],
        for userId: String
    ) -> Bool {
        let currentCallCapabilities = callCoordinatorController.currentCallSettings?.callCapabilities
        return currentCallCapabilities?.contains(
            CallCapability.updateCallPermissions.rawValue
        ) == true
    }
    
    public func grant(
        permissions: [Permission],
        for userId: String,
        callId: String,
        callType: String
    ) async throws {
        try await updatePermissions(
            for: userId,
            callId: callId,
            callType: callType,
            granted: permissions,
            revoked: []
        )
    }
    
    public func revoke(
        permissions: [Permission],
        for userId: String,
        callId: String,
        callType: String
    ) async throws {
        try await updatePermissions(
            for: userId,
            callId: callId,
            callType: callType,
            granted: [],
            revoked: permissions
        )
    }
    
    func updatePermissions(
        for userId: String,
        callId: String,
        callType: String,
        granted: [Permission],
        revoked: [Permission]
    ) async throws {
        if !currentUserCanModifyPermissions(granted.map(\.rawValue), for: userId)
            || !currentUserCanModifyPermissions(revoked.map(\.rawValue), for: userId) {
            // TODO: proper error.
            throw ClientError.Unexpected()
        }
        let updatePermissionsRequest = UpdateUserPermissionsRequest(
            grantPermissions: granted.map(\.rawValue),
            revokePermissions: revoked.map(\.rawValue),
            userId: userId
        )
        let request = UpdatePermissionsRequest(
            id: callId,
            type: callType,
            updateUserPermissionsRequest: updatePermissionsRequest
        )
        _ = try await coordinatorClient.updateUserPermissions(with: request)
    }
    
    public func permissionRequests() -> AsyncStream<PermissionRequest> {
        let requests = AsyncStream(PermissionRequest.self) { [weak self] continuation in
            self?.onPermissionRequestEvent = { event in
                if self?.currentUserCanModifyPermissions(event.permissions, for: event.user.id) == true {
                    continuation.yield(event)
                }
            }
        }
        return requests
    }
    
    public func permissionUpdates() -> AsyncStream<PermissionsUpdated> {
        let requests = AsyncStream(PermissionsUpdated.self) { [weak self] continuation in
            self?.onPermissionsUpdatedEvent = { event in
                continuation.yield(event)
            }
        }
        return requests
    }
}

public struct Permission: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

public extension Permission {
    static let sendAudio: Self = "send-audio"
    static let sendVideo: Self = "send-video"
    static let screenshare: Self = "screenshare"
}
