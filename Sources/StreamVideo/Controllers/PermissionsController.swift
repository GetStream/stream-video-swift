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
            throw ClientError.MissingPermissions()
        }
        let request = RequestPermissionRequest(
            permissions: permissions.map(\.rawValue)
        )
        let permissionsRequest = RequestPermissionsRequestData(
            id: callId,
            type: callType,
            requestPermissionRequest: request
        )
        _ = try await coordinatorClient.requestPermission(with: permissionsRequest)
    }
    
    public func currentUserHasCapability(_ capability: CallCapability) -> Bool {
        let currentCallCapabilities = callCoordinatorController.currentCallSettings?.callCapabilities
        return currentCallCapabilities?.contains(
            capability.rawValue
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
    
    public func muteUsers(
        with request: MuteRequest,
        callId: String,
        callType: String
    ) async throws {
        let muteRequest = MuteUsersRequest(
            audio: request.audio,
            muteAllUsers: request.muteAllUsers,
            screenshare: request.screenshare,
            userIds: request.userIds,
            video: request.video
        )
        let requestData = MuteUsersRequestData(
            id: callId,
            type: callType,
            muteUsersRequest: muteRequest
        )
        _ = try await coordinatorClient.muteUsers(with: requestData)
    }
    
    public func endCall(callId: String, callType: String) async throws {
        let endCallRequest = EndCallRequestData(id: callId, type: callType)
        _ = try await coordinatorClient.endCall(with: endCallRequest)
    }
    
    public func blockUser(with userId: String, callId: String, callType: String) async throws {
        let blockUserRequest = BlockUserRequest(userId: userId)
        let requestData = BlockUserRequestData(
            id: callId,
            type: callType,
            blockUserRequest: blockUserRequest
        )
        _ = try await coordinatorClient.blockUser(with: requestData)
    }
    
    public func unblockUser(with userId: String, callId: String, callType: String) async throws {
        let unblockUserRequest = UnblockUserRequest(userId: userId)
        let requestData = UnblockUserRequestData(
            id: callId,
            type: callType,
            unblockUserRequest: unblockUserRequest
        )
        _ = try await coordinatorClient.unblockUser(with: requestData)
    }
    
    public func permissionRequests() -> AsyncStream<PermissionRequest> {
        let requests = AsyncStream(PermissionRequest.self) { [weak self] continuation in
            self?.onPermissionRequestEvent = { event in
                if self?.currentUserHasCapability(.updateCallPermissions) == true {
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
    
    // MARK: - private
    
    private func updatePermissions(
        for userId: String,
        callId: String,
        callType: String,
        granted: [Permission],
        revoked: [Permission]
    ) async throws {
        if !currentUserHasCapability(.updateCallPermissions) {
            throw ClientError.MissingPermissions()
        }
        let updatePermissionsRequest = UpdateUserPermissionsRequest(
            grantPermissions: granted.map(\.rawValue),
            revokePermissions: revoked.map(\.rawValue),
            userId: userId
        )
        let request = UpdatePermissionsRequestData(
            id: callId,
            type: callType,
            updateUserPermissionsRequest: updatePermissionsRequest
        )
        _ = try await coordinatorClient.updateUserPermissions(with: request)
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
