//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

class PermissionsController {
    
    private let callCoordinatorController: CallCoordinatorController
    private let currentUser: User
    private let callId: String
    private let callType: CallType
    
    /// Event that fires when a permission is requested.
    var onPermissionRequestEvent: ((PermissionRequest) -> Void)?
    /// Event that fires when a permission is updated.
    var onPermissionsUpdatedEvent: ((PermissionsUpdated) -> Void)?
    
    private var coordinatorClient: CoordinatorClient {
        callCoordinatorController.coordinatorClient
    }
    
    /// Initializes a new `PermissionsController` object.
    /// - Parameters:
    ///   - callCoordinatorController: The call coordinator controller.
    ///   - currentUser: The current user.
    ///   - callId: The id of the call.
    ///   - callType: The call type.
    init(
        callCoordinatorController: CallCoordinatorController,
        currentUser: User,
        callId: String,
        callType: CallType
    ) {
        self.callCoordinatorController = callCoordinatorController
        self.currentUser = currentUser
        self.callId = callId
        self.callType = callType
    }
    
    /// Checks if the current user can request permissions.
    /// - Parameter permissions: The permissions to request.
    /// - Returns: A Boolean value indicating if the current user can request the permissions.
    func currentUserCanRequestPermissions(_ permissions: [Permission]) -> Bool {
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
    
    /// Requests permissions for a call.
    /// - Parameters:
    ///   - permissions: The permissions to request.
    ///   - callId: The ID of the call.
    ///   - callType: The type of the call.
    /// - Throws: A `ClientError.MissingPermissions` if the current user can't request the permissions.
    func request(
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
    
    /// Checks if the current user has a certain call capability.
    /// - Parameter capability: The capability to check.
    /// - Returns: A Boolean value indicating if the current user has the call capability.
    func currentUserHasCapability(_ capability: OwnCapability) -> Bool {
        let currentCallCapabilities = callCoordinatorController.currentCallSettings?.callCapabilities
        return currentCallCapabilities?.contains(
            capability.rawValue
        ) == true
    }
    
    /// Grants permissions to a user for a call.
    /// - Parameters:
    ///   - permissions: The permissions to grant.
    ///   - userId: The ID of the user to grant permissions to.
    ///   - callId: The ID of the call.
    ///   - callType: The type of the call.
    /// - Throws: An error if the operation fails.
    func grant(
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
    
    /// Revokes permissions for a user in a call.
    /// - Parameters:
    ///   - permissions: The list of permissions to revoke.
    ///   - userId: The ID of the user to revoke the permissions from.
    ///   - callId: The ID of the call.
    ///   - callType: The type of the call.
    /// - Throws: error if the permission update fails.
    func revoke(
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
    
    /// Mute users in a call.
    /// - Parameters:
    ///   - request: The mute request.
    ///   - callId: The ID of the call.
    ///   - callType: The type of the call.
    /// - Throws: error if muting the users fails.
    func muteUsers(
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
    
    /// Ends a call.
    /// - Parameters:
    ///   - callId: The ID of the call.
    ///   - callType: The type of the call.
    /// - Throws: error if ending the call fails.
    func endCall(callId: String, callType: String) async throws {
        let endCallRequest = EndCallRequestData(id: callId, type: callType)
        _ = try await coordinatorClient.endCall(with: endCallRequest)
    }
    
    /// Blocks a user in a call.
    /// - Parameters:
    ///   - userId: The ID of the user to block.
    ///   - callId: The ID of the call.
    ///   - callType: The type of the call.
    /// - Throws: error if blocking the user fails.
    func blockUser(with userId: String, callId: String, callType: String) async throws {
        let blockUserRequest = BlockUserRequest(userId: userId)
        let requestData = BlockUserRequestData(
            id: callId,
            type: callType,
            blockUserRequest: blockUserRequest
        )
        _ = try await coordinatorClient.blockUser(with: requestData)
    }
    
    /// Unblocks a user in a call.
    /// - Parameters:
    ///   - userId: The ID of the user to unblock.
    ///   - callId: The ID of the call.
    ///   - callType: The type of the call.
    /// - Throws: error if unblocking the user fails.
    func unblockUser(with userId: String, callId: String, callType: String) async throws {
        let unblockUserRequest = UnblockUserRequest(userId: userId)
        let requestData = UnblockUserRequestData(
            id: callId,
            type: callType,
            unblockUserRequest: unblockUserRequest
        )
        _ = try await coordinatorClient.unblockUser(with: requestData)
    }
    
    /// Starts a live call with the given call ID and call type.
    /// - Parameters:
    ///   - callId: The ID of the call to go live.
    ///   - callType: The type of the call to go live.
    /// - Throws: `ClientError.MissingPermissions` if the current user doesn't have the capability to update the call.
    func goLive(callId: String, callType: String) async throws {
        guard currentUserHasCapability(.updateCall) else {
            throw ClientError.MissingPermissions()
        }
        _ = try await coordinatorClient.goLive(callId: callId, callType: callType)
    }
    
    /// Stops an ongoing live call with the given call ID and call type.
    /// - Parameters:
    ///   - callId: The ID of the call to stop.
    ///   - callType: The type of the call to stop.
    /// - Throws: `ClientError.MissingPermissions` if the current user doesn't have the capability to update the call.
    func stopLive(callId: String, callType: String) async throws {
        guard currentUserHasCapability(.updateCall) else {
            throw ClientError.MissingPermissions()
        }
        _ = try await coordinatorClient.stopLive(callId: callId, callType: callType)
    }
    
    /// Returns an `AsyncStream` of `PermissionRequest` objects that represent the permission requests events.
    /// - Returns: An `AsyncStream` of `PermissionRequest` objects.
    func permissionRequests() -> AsyncStream<PermissionRequest> {
        let callCid = callCid(from: callId, callType: callType)
        let requests = AsyncStream(PermissionRequest.self) { [weak self] continuation in
            self?.onPermissionRequestEvent = { event in
                if event.callCid == callCid && self?.currentUserHasCapability(.updateCallPermissions) == true {
                    continuation.yield(event)
                }
            }
        }
        return requests
    }
    
    /// Returns an `AsyncStream` of `PermissionsUpdated` objects that represent the permission updates events.
    /// - Returns: An `AsyncStream` of `PermissionsUpdated` objects.
    func permissionUpdates() -> AsyncStream<PermissionsUpdated> {
        let callCid = callCid(from: callId, callType: callType)
        let requests = AsyncStream(PermissionsUpdated.self) { [weak self] continuation in
            self?.onPermissionsUpdatedEvent = { event in
                if event.callCid == callCid {
                    continuation.yield(event)
                }
            }
        }
        return requests
    }
    
    func cleanUp() {
        self.onPermissionRequestEvent = nil
        self.onPermissionsUpdatedEvent = nil
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
