//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// Observable object that provides info about the call state, as well as methods for updating it.
public class Call: @unchecked Sendable, WSEventsSubscriber {
    
    @Injected(\.streamVideo) var streamVideo
    
    typealias EventHandling = ((Event) -> ())?

    public internal(set) var state = CallState()
    
    /// The id of the current session.
    /// When a call is started, a unique session identifier is assigned to the user in the call.
    public internal(set) var sessionId: String = ""
    
    /// The call id.
    public let callId: String
    /// The call type.
    public let callType: String
    
    /// The unique identifier of the call, formatted as `callType.name:callId`.
    public var cId: String {
        callCid(from: callId, callType: callType)
    }
    
    internal let callController: CallController
    private let videoOptions: VideoOptions
    private var eventHandlers = [EventHandling]()
    // TODO: rename this into coordinatorClient
    private let defaultAPI: DefaultAPI

    internal init(
        callType: String,
        callId: String,
        defaultAPI: DefaultAPI,
        callController: CallController,
        videoOptions: VideoOptions
    ) {
        self.callId = callId
        self.callType = callType
        self.defaultAPI = defaultAPI
        self.callController = callController
        self.videoOptions = videoOptions
        self.callController.call = self
    }
    
    /// Joins the current call.
    /// - Parameters:
    ///  - create: whether the call should be created if it doesn't exist.
    ///  - members: the members of the call.
    ///  - ring: whether the call should ring, `false` by default.
    ///  - notify: whether the participants should be notified about the call.
    ///  - callSettings: optional call settings.
    /// - Throws: An error if the call could not be joined.
    public func join(
        create: Bool = false,
        // TODO: replace members with a CreateCallOptions struct that contains memberIds, [Members], custom, settings, startsAt and team
        // TODO: sync state using the response from this method
        members: [Member] = [],
        ring: Bool = false,
        notify: Bool = false,
        callSettings: CallSettings = CallSettings()
    ) async throws {
        try await callController.joinCall(
            create: create,
            callType: callType,
            callId: callId,
            callSettings: callSettings,
            videoOptions: videoOptions,
            members: members,
            ring: ring,
            notify: notify
        )
    }
    
    /// Gets the call on the backend with the given parameters.
    ///
    /// - Parameters:
    ///  - membersLimit: An optional integer specifying the maximum number of members allowed in the call.
    ///  - notify: A boolean value indicating whether members should be notified about the call.
    ///  - ring: A boolean value indicating whether to ring the call.
    /// - Throws: An error if the call doesn't exist.
    /// - Returns: The call's data.
    public func get(
        membersLimit: Int? = nil,
        ring: Bool = false,
        notify: Bool = false
    ) async throws -> CallResponse {
        let response = try await defaultAPI.getCall(type: callType, id: callId, membersLimit: membersLimit, ring: ring, notify: notify)
        state.update(from: response.call)
        return response.call
    }
    
    /// Rings the call (sends call notification to members).
    /// - Returns: The call's data.
    @discardableResult
    public func ring() async throws -> CallResponse {
        let response = try await get(ring: true)
        state.update(from: response)
        return response
    }
    
    /// Notifies the users of the call, by sending push notification.
    /// - Returns: The call's data.
    @discardableResult
    public func notify() async throws -> CallResponse {
        let response = try await get(notify: true)
        state.update(from: response)
        return response
    }

    @discardableResult
    public func create(
        members: [MemberRequest]? = nil,
        memberIds: [String]? = nil,
        custom: [String: RawJSON]? = nil,
        startsAt: Date? = nil,
        team: String? = nil,
        ring: Bool = false,
        notify: Bool = false
    ) async throws -> CallResponse {
        var membersRequest = [MemberRequest]()
        memberIds?.forEach {
            membersRequest.append(.init(userId: $0))
        }
        members?.forEach {
            membersRequest.append($0)
        }
        let request = GetOrCreateCallRequest(
            data: CallRequest(
                custom: custom,
                members: membersRequest,
                startsAt: startsAt
            ),
            notify: notify,
            ring: ring
        )
        let response = try await defaultAPI.getOrCreateCall(
            type: callType,
            id: callId,
            getOrCreateCallRequest: request
        )
        state.update(from: response)
        return response.call
    }

    @discardableResult
    public func update(
        custom: [String: RawJSON]? = nil,
        startsAt: Date? = nil
    ) async throws -> UpdateCallResponse {
        let request = UpdateCallRequest(custom: custom, startsAt: startsAt)
        let response = try await defaultAPI.updateCall(type: callType, id: callId, updateCallRequest: request)
        state.update(from: response.call)
        return response
    }

    /// Accepts an incoming call.
    @discardableResult
    // TODO: sync state using the response from this method
    public func accept() async throws -> AcceptCallResponse {
        try await defaultAPI.acceptCall(type: callType, id: callId)
    }
    
    /// Rejects a call.
    @discardableResult
    // TODO: sync state using the response from this method
    public func reject() async throws -> RejectCallResponse {
        try await defaultAPI.rejectCall(type: callType, id: callId)
    }
    
    /// Adds the given user to the list of blocked users for the call.
    /// - Parameter blockedUser: The user to add to the list of blocked users.
    @discardableResult
    public func block(user: User) async throws -> BlockUserResponse {
        return try await blockUser(with: user.id)
    }
    
    /// Removes the given user from the list of blocked users for the call.
    /// - Parameter blockedUser: The user to remove from the list of blocked users.
    @discardableResult
    public func unblock(user: User) async throws -> UnblockUserResponse{
        return try await unblockUser(with: user.id)
    }
    
    /// Changes the audio state for the current user.
    /// - Parameter isEnabled: whether audio should be enabled.
    public func changeAudioState(isEnabled: Bool) async throws {
        try await callController.changeAudioState(isEnabled: isEnabled)
    }
    
    /// Changes the video state for the current user.
    /// - Parameter isEnabled: whether video should be enabled.
    public func changeVideoState(isEnabled: Bool) async throws {
        try await callController.changeVideoState(isEnabled: isEnabled)
    }
    
    /// Changes the availability of sound during the call.
    /// - Parameter isEnabled: whether the sound should be enabled.
    public func changeSoundState(isEnabled: Bool) async throws {
        try await callController.changeSoundState(isEnabled: isEnabled)
    }
    
    /// Changes the camera position (front/back) for the current user.
    /// - Parameters:
    ///  - position: the new camera position.
    ///  - completion: called when the camera position is changed.
    public func changeCameraMode(position: CameraPosition, completion: @escaping () -> ()) {
        callController.changeCameraMode(position: position, completion: completion)
    }
    
    /// Changes the track visibility for a participant (not visible if they go off-screen).
    /// - Parameters:
    ///  - participant: the participant whose track visibility would be changed.
    ///  - isVisible: whether the track should be visible.
    public func changeTrackVisibility(for participant: CallParticipant, isVisible: Bool) async {
        await callController.changeTrackVisibility(for: participant, isVisible: isVisible)
    }
    
    // TODO: return the response object instead of members
    @discardableResult
    public func addMembers(members: [MemberRequest]) async throws -> [Member] {
        try await self.updateCallMembers(
            updateMembers: members
        )
    }

    // TODO: return the response object instead of members
    @discardableResult
    public func updateMembers(members: [MemberRequest]) async throws -> [Member] {
        try await self.updateCallMembers(
            updateMembers: members
        )
    }

    /// Adds members with the specified `ids` to the current call.
    /// - Parameter ids: An array of `String` values representing the member IDs to add.
    /// - Throws: An error if the members could not be added to the call.
    // TODO: return the response object instead of members
    // TODO: update state object directly here
    @discardableResult
    public func addMembers(ids: [String]) async throws -> [Member] {
        try await self.updateCallMembers(
            updateMembers: ids.map { MemberRequest(userId: $0) }
        )
    }
    
    /// Remove members with the specified `ids` from the current call.
    /// - Parameter ids: An array of `String` values representing the member IDs to remove.
    /// - Throws: An error if the members could not be removed from the call.
    // TODO: return the response object instead of members
    @discardableResult
    public func removeMembers(ids: [String]) async throws -> [Member] {
        try await self.updateCallMembers(
            removedIds: ids
        )
    }
    
    /// Updates the track size for the provided participant.
    /// - Parameters:
    ///  - trackSize: the size of the track.
    ///  - participant: the call participant.
    public func updateTrackSize(_ trackSize: CGSize, for participant: CallParticipant) async {
        await callController.updateTrackSize(trackSize, for: participant)
    }
    
    /// Sets a `videoFilter` for the current call.
    /// - Parameter videoFilter: A `VideoFilter` instance representing the video filter to set.
    public func setVideoFilter(_ videoFilter: VideoFilter?) {
        callController.setVideoFilter(videoFilter)
    }
    
    // TODO: ideally handlers receive a VideoEvent event instead of the Event container
    public func subscribe() -> AsyncStream<Event> {
        AsyncStream(Event.self) { [weak self] continuation in
            let eventHandler: EventHandling = { event in
                continuation.yield(event)
            }
            self?.eventHandlers.append(eventHandler)
        }
    }

    public func subscribe<WSEvent: Event>(for event: WSEvent.Type) -> AsyncStream<WSEvent> {
        return AsyncStream(event) { [weak self] continuation in
            let eventHandler: EventHandling = { event in
                if let event = event as? WSEvent {
                    continuation.yield(event)
                }
            }
            self?.eventHandlers.append(eventHandler)
        }
    }
        
    /// Leave the current call.
    public func leave() {
        postNotification(with: CallNotification.callEnded)
        eventHandlers.removeAll()
        callController.cleanUp()
    }
    
    //MARK: - Permissions
    
    /// Checks if the current user can request permissions.
    /// - Parameter permissions: The permissions to request.
    /// - Returns: A Boolean value indicating if the current user can request the permissions.
    public func currentUserCanRequestPermissions(_ permissions: [Permission]) -> Bool {
        guard let callSettings = state.settings else {
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
    /// - Throws: A `ClientError.MissingPermissions` if the current user can't request the permissions.
    @discardableResult
    public func request(permissions: [Permission]) async throws -> RequestPermissionResponse {
        guard currentUserCanRequestPermissions(permissions) else {
            throw ClientError.MissingPermissions()
        }
        let request = RequestPermissionRequest(
            permissions: permissions.map(\.rawValue)
        )
        
        return try await defaultAPI.requestPermission(
            type: callType,
            id: callId,
            requestPermissionRequest: request
        )
    }
    
    /// Checks if the current user has a certain call capability.
    /// - Parameter capability: The capability to check.
    /// - Returns: A Boolean value indicating if the current user has the call capability.
    public func currentUserHasCapability(_ capability: OwnCapability) -> Bool {
        return state.ownCapabilities.contains(capability)
    }
    
    /// Grants permissions to a user for a call.
    /// - Parameters:
    ///   - permissions: The permissions to grant.
    ///   - userId: The ID of the user to grant permissions to.
    /// - Throws: An error if the operation fails.
    @discardableResult
    public func grant(
        permissions: [Permission],
        for userId: String
    ) async throws -> UpdateUserPermissionsResponse {
        try await updatePermissions(
            for: userId,
            granted: permissions,
            revoked: []
        )
    }
    
    /// Revokes permissions for a user in a call.
    /// - Parameters:
    ///   - permissions: The list of permissions to revoke.
    ///   - userId: The ID of the user to revoke the permissions from.
    /// - Throws: error if the permission update fails.
    @discardableResult
    public func revoke(
        permissions: [Permission],
        for userId: String
    ) async throws -> UpdateUserPermissionsResponse {
        try await updatePermissions(
            for: userId,
            granted: [],
            revoked: permissions
        )
    }
    
    /// Mute users in a call.
    /// - Parameters:
    ///   - request: The mute request.
    /// - Throws: error if muting the users fails.
    @discardableResult
    public func muteUsers(
        with request: MuteUsersRequest
    ) async throws -> MuteUsersResponse {
        try await defaultAPI.muteUsers(
            type: callType,
            id: callId,
            muteUsersRequest: request
        )
    }
    
    /// Ends a call.
    /// - Throws: error if ending the call fails.
    @discardableResult
    public func end() async throws -> EndCallResponse {
        try await defaultAPI.endCall(type: callType, id: callId)
    }
    
    /// Blocks a user in a call.
    /// - Parameters:
    ///   - userId: The ID of the user to block.
    /// - Throws: error if blocking the user fails.
    @discardableResult
    public func blockUser(with userId: String) async throws -> BlockUserResponse {
        let response = try await defaultAPI.blockUser(type: callType, id: callId, blockUserRequest: BlockUserRequest(userId: userId))
        state.blockUser(id: userId)
        return response
    }
    
    /// Unblocks a user in a call.
    /// - Parameters:
    ///   - userId: The ID of the user to unblock.
    /// - Throws: error if unblocking the user fails.
    @discardableResult
    public func unblockUser(with userId: String) async throws -> UnblockUserResponse {
        let response = try await defaultAPI.unblockUser(type: callType, id: callId, unblockUserRequest: UnblockUserRequest(userId: userId))
        state.unblockUser(id: userId)
        return response
    }
    
    /// Starts a live call.
    @discardableResult
    public func goLive() async throws -> GoLiveResponse {
        return try await defaultAPI.goLive(type: callType, id: callId)
    }
    
    /// Stops an ongoing live call.
    @discardableResult
    public func stopLive() async throws -> StopLiveResponse {
        return try await defaultAPI.stopLive(type: callType, id: callId)
    }
    
    //MARK: - Recording
    
    /// Starts recording for the call.
    @discardableResult
    public func startRecording() async throws -> StartRecordingResponse {
        let response = try await defaultAPI.startRecording(type: callType, id: callId)
        update(recordingState: .requested)
        return response
    }
    
    /// Stops recording a call.
    @discardableResult
    public func stopRecording() async throws -> StopRecordingResponse {
        try await defaultAPI.stopRecording(type: callType, id: callId)
    }
    
    /// Lists recordings for the call.
    public func listRecordings() async throws -> [CallRecording] {
        let response = try await defaultAPI.listRecordingsTypeId0(
            type: callType,
            id: callId
        )
        return response.recordings
    }
    
    //MARK: - Broadcasting
    
    /// Starts broadcasting of the call.
    @discardableResult
    public func startBroadcasting() async throws -> StartBroadcastingResponse {
        return try await defaultAPI.startBroadcasting(type: callType, id: callId)
    }
    
    /// Stops broadcasting of the call.
    @discardableResult
    public func stopBroadcasting() async throws -> StopBroadcastingResponse {
        try await defaultAPI.stopBroadcasting(type: callType, id: callId)
    }
    
    //MARK: - Events
    
    /// Sends a custom event to the call.
    /// - Parameter event: The `SendEventRequest` object representing the custom event to send.
    /// - Throws: An error if the sending fails.
    @discardableResult
    public func send(event: SendEventRequest) async throws -> SendEventResponse {
        try await defaultAPI.sendEvent(
            type: callType,
            id: callId,
            sendEventRequest: event
        )
    }
    
    /// Sends a reaction to the call.
    /// - Parameter reaction: The `SendReactionRequest` object representing the reaction to send.
    /// - Throws: An error if the sending fails.
    @discardableResult
    public func send(reaction: SendReactionRequest) async throws -> SendReactionResponse {
        try await defaultAPI.sendVideoReaction(
            type: callType,
            id: callId,
            sendReactionRequest: reaction
        )
    }
    
    //MARK: - Internal
    
    internal func update(reconnectionStatus: ReconnectionStatus) {
        if reconnectionStatus != self.state.reconnectionStatus {
            self.state.reconnectionStatus = reconnectionStatus
        }
    }
    
    internal func update(recordingState: RecordingState) {
        self.state.recordingState = recordingState
    }
    
    internal func onEvent(_ event: Event) {
        guard let wsCallEvent = event as? WSCallEvent, wsCallEvent.callCid == cId else {
            return
        }
        state.updateState(from: event)
        callController.updateOwnCapabilities(ownCapabilities: state.ownCapabilities)
        for eventHandler in eventHandlers {
            eventHandler?(event)
        }
    }    
    
    //MARK: - private
    // TODO: update state object with response
    private func updatePermissions(
        for userId: String,
        granted: [Permission],
        revoked: [Permission]
    ) async throws -> UpdateUserPermissionsResponse {
        if !currentUserHasCapability(.updateCallPermissions) {
            throw ClientError.MissingPermissions()
        }
        let updatePermissionsRequest = UpdateUserPermissionsRequest(
            grantPermissions: granted.map(\.rawValue),
            revokePermissions: revoked.map(\.rawValue),
            userId: userId
        )
        return try await defaultAPI.updateUserPermissions(
            type: callType,
            id: callId,
            updateUserPermissionsRequest: updatePermissionsRequest
        )        
    }
    
    // TODO: update state object with response
    private func updateCallMembers(
        updateMembers: [MemberRequest] = [],
        removedIds: [String] = []
    ) async throws -> [Member] {
        let request = UpdateCallMembersRequest(
            removeMembers: removedIds,
            updateMembers: updateMembers
        )
        let response = try await defaultAPI.updateCallMembers(
            type: callType,
            id: callId,
            updateCallMembersRequest: request
        )
        // TODO: create an map function to convert MemberResponse into Member so we avoid duplicated code and bugs
        return response.members.map { member in
            let user = User(
                id: member.userId,
                name: member.user.name,
                imageURL: URL(string: member.user.image ?? ""),
                role: member.user.role
            )
            return Member(
                user: user,
                role: member.role ?? member.user.role,
                customData: member.custom,
                updatedAt: member.updatedAt
            )
        }
    }
}
