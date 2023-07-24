//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import Combine

/// Observable object that provides info about the call state, as well as methods for updating it.
public class Call: @unchecked Sendable, WSEventsSubscriber {
    
    @Injected(\.streamVideo) var streamVideo

    @MainActor public internal(set) var state = CallState()
    
    /// The call id.
    public let callId: String
    /// The call type.
    public let callType: String
    
    /// The unique identifier of the call, formatted as `callType.name:callId`.
    public var cId: String {
        callCid(from: callId, callType: callType)
    }
    
    /// Provides access to the microphone.
    public let microphone: MicrophoneManager
    /// Provides access to the camera.
    public let camera: CameraManager
    /// Provides access to the speaker.
    public let speaker: SpeakerManager
    
    internal let callController: CallController
    private let videoOptions: VideoOptions
    private var eventHandlers = [EventHandling]()
    private let coordinatorClient: DefaultAPI
    private var cancellables = Set<AnyCancellable>()
    
    internal init(
        callType: String,
        callId: String,
        coordinatorClient: DefaultAPI,
        callController: CallController,
        videoOptions: VideoOptions = VideoOptions()
    ) {
        self.callId = callId
        self.callType = callType
        self.coordinatorClient = coordinatorClient
        self.callController = callController
        self.videoOptions = videoOptions
        self.microphone = MicrophoneManager(
            callController: callController,
            initialStatus: .enabled
        )
        self.camera = CameraManager(
            callController: callController,
            initialStatus: .enabled,
            initialDirection: .front
        )
        self.speaker = SpeakerManager(
            callController: callController,
            initialSpeakerStatus: .enabled,
            initialAudioOutputStatus: .enabled
        )
        self.callController.call = self
        self.subscribeToLocalCallSettingsChanges()
    }
    
    convenience internal init(
        from response: CallStateResponseFields,
        coordinatorClient: DefaultAPI,
        callController: CallController
    ) {
        self.init(
            callType: response.call.type,
            callId: response.call.id,
            coordinatorClient: coordinatorClient,
            callController: callController
        )
        executeOnMain { [weak self] in
            self?.state.update(from: response)
        }
    }

    /// Joins the current call.
    /// - Parameters:
    ///  - create: whether the call should be created if it doesn't exist.
    ///  - options: configuration options for the call.
    ///  - ring: whether the call should ring, `false` by default.
    ///  - notify: whether the participants should be notified about the call.
    ///  - callSettings: optional call settings.
    /// - Throws: An error if the call could not be joined.
    @discardableResult
    public func join(
        create: Bool = false,
        options: CreateCallOptions? = nil,
        ring: Bool = false,
        notify: Bool = false,
        callSettings: CallSettings? = nil
    ) async throws -> JoinCallResponse {
        try await executeTask(retryPolicy: .fastAndSimple, task: {
            let response = try await callController.joinCall(
                create: create,
                callType: callType,
                callId: callId,
                callSettings: callSettings,
                videoOptions: videoOptions,
                options: options,
                ring: ring,
                notify: notify
            )
            if let callSettings {
                await state.update(callSettings: callSettings)
            }
            await state.update(from: response)
            let updated = await state.callSettings
            updateCallSettingsManagers(with: updated)
            streamVideo.state.activeCall = self
            return response
        })
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
        let response = try await coordinatorClient.getCall(
            type: callType,
            id: callId,
            membersLimit: membersLimit,
            ring: ring,
            notify: notify
        )
        await state.update(from: response)
        if ring {
            streamVideo.state.ringingCall = self
        }
        return response.call
    }
    
    /// Rings the call (sends call notification to members).
    /// - Returns: The call's data.
    @discardableResult
    public func ring() async throws -> CallResponse {
        let response = try await get(ring: true)
        await state.update(from: response)
        return response
    }
    
    /// Notifies the users of the call, by sending push notification.
    /// - Returns: The call's data.
    @discardableResult
    public func notify() async throws -> CallResponse {
        let response = try await get(notify: true)
        await state.update(from: response)
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
                settingsOverride: nil,
                startsAt: startsAt,
                team: team
            ),
            notify: notify,
            ring: ring
        )
        let response = try await coordinatorClient.getOrCreateCall(
            type: callType,
            id: callId,
            getOrCreateCallRequest: request
        )
        await state.update(from: response)
        if ring {
            streamVideo.state.ringingCall = self
        }
        return response.call
    }

    @discardableResult
    public func update(
        custom: [String: RawJSON]? = nil,
        startsAt: Date? = nil
    ) async throws -> UpdateCallResponse {
        let request = UpdateCallRequest(custom: custom, startsAt: startsAt)
        let response = try await coordinatorClient.updateCall(type: callType, id: callId, updateCallRequest: request)
        await state.update(from: response)
        return response
    }

    /// Accepts an incoming call.
    @discardableResult
    public func accept() async throws -> AcceptCallResponse {
        try await coordinatorClient.acceptCall(type: callType, id: callId)
    }
    
    /// Rejects a call.
    @discardableResult
    public func reject() async throws -> RejectCallResponse {
        let response = try await coordinatorClient.rejectCall(type: callType, id: callId)
        if streamVideo.state.ringingCall?.cId == self.cId {
            streamVideo.state.ringingCall = nil
        }
        return response
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
    
    /// Changes the track visibility for a participant (not visible if they go off-screen).
    /// - Parameters:
    ///  - participant: the participant whose track visibility would be changed.
    ///  - isVisible: whether the track should be visible.
    public func changeTrackVisibility(for participant: CallParticipant, isVisible: Bool) async {
        await callController.changeTrackVisibility(for: participant, isVisible: isVisible)
    }
    
    @discardableResult
    public func addMembers(members: [MemberRequest]) async throws -> UpdateCallMembersResponse {
        try await self.updateCallMembers(
            updateMembers: members
        )
    }

    @discardableResult
    public func updateMembers(members: [MemberRequest]) async throws -> UpdateCallMembersResponse {
        try await self.updateCallMembers(
            updateMembers: members
        )
    }

    /// Adds members with the specified `ids` to the current call.
    /// - Parameter ids: An array of `String` values representing the member IDs to add.
    /// - Throws: An error if the members could not be added to the call.
    @discardableResult
    public func addMembers(ids: [String]) async throws -> UpdateCallMembersResponse {
        try await self.updateCallMembers(
            updateMembers: ids.map { MemberRequest(userId: $0) }
        )
    }
    
    /// Remove members with the specified `ids` from the current call.
    /// - Parameter ids: An array of `String` values representing the member IDs to remove.
    /// - Throws: An error if the members could not be removed from the call.
    @discardableResult
    public func removeMembers(ids: [String]) async throws -> UpdateCallMembersResponse {
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
    
    public func startScreensharing(type: ScreensharingType) async throws {
        try await callController.startScreensharing(type: type)
    }
    
    public func stopScreensharing() async throws {
        try await callController.stopScreensharing()
    }
    
    public func subscribe() -> AsyncStream<VideoEvent> {
        AsyncStream(VideoEvent.self) { [weak self] continuation in
            let eventHandler: EventHandling = { event in
                guard case let .coordinatorEvent(event) = event else {
                    return
                }
                continuation.yield(event)
            }
            self?.eventHandlers.append(eventHandler)
        }
    }

    public func subscribe<WSEvent: Event>(for event: WSEvent.Type) -> AsyncStream<WSEvent> {
        return AsyncStream(event) { [weak self] continuation in
            let eventHandler: EventHandling = { event in
                guard case let .coordinatorEvent(event) = event else {
                    return
                }
                if let event = event.rawValue as? WSEvent {
                    continuation.yield(event)
                }
            }
            self?.eventHandlers.append(eventHandler)
        }
    }

    /// Leave the current call.
    public func leave() {
        postNotification(with: CallNotification.callEnded)
        for cancellable in cancellables {
            cancellable.cancel()
        }
        cancellables.removeAll()
        eventHandlers.removeAll()
        callController.cleanUp()
        streamVideo.state.ringingCall = nil
        streamVideo.state.activeCall = nil
    }
    
    //MARK: - Permissions
    
    /// Checks if the current user can request permissions.
    /// - Parameter permissions: The permissions to request.
    /// - Returns: A Boolean value indicating if the current user can request the permissions.
    @MainActor public func currentUserCanRequestPermissions(_ permissions: [Permission]) -> Bool {
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
        if await state.isInitialized == false {
            let response = try await get()
            await state.update(from: response)
        }
        if await !currentUserCanRequestPermissions(permissions) {
            throw ClientError.MissingPermissions()
        }
        let request = RequestPermissionRequest(
            permissions: permissions.map(\.rawValue)
        )
        return try await coordinatorClient.requestPermission(
            type: callType,
            id: callId,
            requestPermissionRequest: request
        )
    }
    
    /// Checks if the current user has a certain call capability.
    /// - Parameter capability: The capability to check.
    /// - Returns: A Boolean value indicating if the current user has the call capability.
    @MainActor public func currentUserHasCapability(_ capability: OwnCapability) -> Bool {
        if !state.isInitialized {
            log.warning("currentUserHasCapability called before the call was initialized using .get .create or .join")
        }
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
            granted: permissions.map(\.rawValue),
            revoked: []
        )
    }
    
    @discardableResult
    public func grant(request: PermissionRequest) async throws -> UpdateUserPermissionsResponse {
        let response = try await updatePermissions(
            for: request.user.id,
            granted: [request.permission],
            revoked: []
        )
        executeOnMain { [weak self] in
            guard let self else { return }
            self.state.removePermissionRequest(request: request)
        }
        return response
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
            revoked: permissions.map(\.rawValue)
        )
    }
    
    @discardableResult
    public func mute(
        userId: String,
        audio: Bool = true,
        video: Bool = true
    ) async throws -> MuteUsersResponse {
        try await coordinatorClient.muteUsers(
            type: callType,
            id: callId,
            muteUsersRequest: MuteUsersRequest(
                audio: audio,
                userIds: [userId],
                video: video
            )
        )
    }

    @discardableResult
    public func muteAllUsers(audio: Bool = true, video: Bool = true) async throws -> MuteUsersResponse {
        try await coordinatorClient.muteUsers(
            type: callType,
            id: callId,
            muteUsersRequest: MuteUsersRequest(
                audio: audio,
                muteAllUsers: true,
                video: video
            )
        )
    }


    /// Ends a call.
    /// - Throws: error if ending the call fails.
    @discardableResult
    public func end() async throws -> EndCallResponse {
        try await coordinatorClient.endCall(type: callType, id: callId)
    }
    
    /// Blocks a user in a call.
    /// - Parameters:
    ///   - userId: The ID of the user to block.
    /// - Throws: error if blocking the user fails.
    @discardableResult
    public func blockUser(with userId: String) async throws -> BlockUserResponse {
        let response = try await coordinatorClient.blockUser(type: callType, id: callId, blockUserRequest: BlockUserRequest(userId: userId))
        await state.blockUser(id: userId)
        return response
    }
    
    /// Unblocks a user in a call.
    /// - Parameters:
    ///   - userId: The ID of the user to unblock.
    /// - Throws: error if unblocking the user fails.
    @discardableResult
    public func unblockUser(with userId: String) async throws -> UnblockUserResponse {
        let response = try await coordinatorClient.unblockUser(type: callType, id: callId, unblockUserRequest: UnblockUserRequest(userId: userId))
        await state.unblockUser(id: userId)
        return response
    }
    
    /// Starts a live call.
    @discardableResult
    public func goLive() async throws -> GoLiveResponse {
        return try await coordinatorClient.goLive(type: callType, id: callId)
    }
    
    /// Stops an ongoing live call.
    @discardableResult
    public func stopLive() async throws -> StopLiveResponse {
        return try await coordinatorClient.stopLive(type: callType, id: callId)
    }
    
    //MARK: - Recording
    
    /// Starts recording for the call.
    @discardableResult
    public func startRecording() async throws -> StartRecordingResponse {
        let response = try await coordinatorClient.startRecording(type: callType, id: callId)
        update(recordingState: .requested)
        return response
    }
    
    /// Stops recording a call.
    @discardableResult
    public func stopRecording() async throws -> StopRecordingResponse {
        try await coordinatorClient.stopRecording(type: callType, id: callId)
    }
    
    /// Lists recordings for the call.
    public func listRecordings() async throws -> [CallRecording] {
        let response = try await coordinatorClient.listRecordingsTypeId0(
            type: callType,
            id: callId
        )
        return response.recordings
    }
    
    //MARK: - Broadcasting
    
    /// Starts broadcasting of the call.
    @discardableResult
    public func startBroadcasting() async throws -> StartBroadcastingResponse {
        return try await coordinatorClient.startBroadcasting(type: callType, id: callId)
    }
    
    /// Stops broadcasting of the call.
    @discardableResult
    public func stopBroadcasting() async throws -> StopBroadcastingResponse {
        try await coordinatorClient.stopBroadcasting(type: callType, id: callId)
    }
    
    //MARK: - Events
    
    /// Sends a custom event to the call.
    /// - Throws: An error if the sending fails.
    @discardableResult
    public func sendCustomEvent(_ data: [String: RawJSON]) async throws -> SendEventResponse {
        try await coordinatorClient.sendEvent(
            type: callType,
            id: callId,
            sendEventRequest: SendEventRequest(custom: data)
        )
    }
    
    /// Sends a reaction to the call.
    /// - Throws: An error if the sending fails.
    @discardableResult
    public func sendReaction(type: String, custom: [String: RawJSON]? = nil, emojiCode: String? = nil) async throws -> SendReactionResponse {
        try await coordinatorClient.sendVideoReaction(
            type: callType,
            id: callId,
            sendReactionRequest: SendReactionRequest(custom: custom, emojiCode: emojiCode, type: type)
        )
    }
    
    //MARK: - Query members methods

    internal func queryMembers(
        filters: [String: RawJSON]? = nil, limit: Int? = nil, next: String? = nil, sort: [SortParamRequest]? = nil
    ) async throws -> QueryMembersResponse {
        let request = QueryMembersRequest(filterConditions: filters, id: callId, limit: limit, next: next, sort: sort, type: callType)
        let response = try await coordinatorClient.queryMembers(queryMembersRequest: request)
        await state.mergeMembers(response.members)
        return response
    }

    public func queryMembers(
        filters: [String : RawJSON]? = nil,
        sort: [SortParamRequest] = [SortParamRequest.descending("created_at")],
        limit: Int = 25
    ) async throws -> QueryMembersResponse {
        try await queryMembers(filters: filters, limit: limit, sort: sort)
    }

    public func queryMembers(next: String) async throws -> QueryMembersResponse {
        try await queryMembers(filters: nil, limit: nil, next: next, sort: nil)
    }
    
    //MARK: - Internal
    
    internal func update(reconnectionStatus: ReconnectionStatus) {
        executeOnMain { [weak self] in
            guard let self else { return }
            if reconnectionStatus != self.state.reconnectionStatus {
                self.state.reconnectionStatus = reconnectionStatus
            }
        }
    }
    
    internal func update(recordingState: RecordingState) {
        executeOnMain { [weak self] in
            self?.state.recordingState = recordingState
        }
    }
    
    internal func onEvent(_ event: WrappedEvent) {
        guard case let .coordinatorEvent(videoEvent) = event else {
            return
        }
        guard videoEvent.forCall(cid: cId) else {
            return
        }
        executeOnMain { [weak self] in
            guard let self else { return }
            self.state.updateState(from: videoEvent)
            self.callController.updateOwnCapabilities(ownCapabilities: self.state.ownCapabilities)
        }
        
        for eventHandler in eventHandlers {
            eventHandler?(event)
        }
    }
    
    //MARK: - private
    private func updatePermissions(
        for userId: String,
        granted: [String],
        revoked: [String]
    ) async throws -> UpdateUserPermissionsResponse {
        if await !currentUserHasCapability(.updateCallPermissions) {
            throw ClientError.MissingPermissions()
        }
        let updatePermissionsRequest = UpdateUserPermissionsRequest(
            grantPermissions: granted,
            revokePermissions: revoked,
            userId: userId
        )
        return try await coordinatorClient.updateUserPermissions(
            type: callType,
            id: callId,
            updateUserPermissionsRequest: updatePermissionsRequest
        )
    }
    
    private func updateCallMembers(
        updateMembers: [MemberRequest] = [],
        removedIds: [String] = []
    ) async throws -> UpdateCallMembersResponse {
        let request = UpdateCallMembersRequest(
            removeMembers: removedIds,
            updateMembers: updateMembers
        )
        let response = try await coordinatorClient.updateCallMembers(
            type: callType,
            id: callId,
            updateCallMembersRequest: request
        )
        await state.mergeMembers(response.members)
        return response
    }
    
    private func subscribeToLocalCallSettingsChanges() {
        speaker.$status.dropFirst().sink { [weak self] status in
            guard let self else { return }
            executeOnMain {
                let newState = self.state.callSettings.withUpdatedSpeakerState(status.boolValue)
                self.state.update(callSettings: newState)
            }
        }
        .store(in: &cancellables)
        
        speaker.$audioOutputStatus.dropFirst().sink { [weak self] status in
            guard let self else { return }
            executeOnMain {
                let newState = self.state.callSettings.withUpdatedAudioOutputState(status.boolValue)
                self.state.update(callSettings: newState)
            }
        }
        .store(in: &cancellables)
        
        camera.$status.dropFirst().sink { [weak self] status in
            guard let self else { return }
            executeOnMain {
                let newState = self.state.callSettings.withUpdatedVideoState(status.boolValue)
                self.state.update(callSettings: newState)
            }
        }
        .store(in: &cancellables)
        
        camera.$direction.dropFirst().sink { [weak self] position in
            guard let self else { return }
            executeOnMain {
                let newState = self.state.callSettings.withUpdatedCameraPosition(position)
                self.state.update(callSettings: newState)
            }
        }
        .store(in: &cancellables)
        
        microphone.$status.dropFirst().sink { [weak self] status in
            guard let self else { return }
            executeOnMain {
                let newState = self.state.callSettings.withUpdatedAudioState(status.boolValue)
                self.state.update(callSettings: newState)
            }
        }
        .store(in: &cancellables)
    }
    
    private func updateCallSettingsManagers(with callSettings: CallSettings) {
        microphone.status = callSettings.audioOn ? .enabled : .disabled
        camera.status = callSettings.videoOn ? .enabled : .disabled
        camera.direction = callSettings.cameraPosition
        speaker.status = callSettings.speakerOn ? .enabled : .disabled
        speaker.audioOutputStatus = callSettings.audioOutputOn ? .enabled : .disabled
    }
}

