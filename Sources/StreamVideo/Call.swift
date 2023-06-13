//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// Observable object that provides info about the call state, as well as methods for updating it.
public class Call: @unchecked Sendable, WSEventsSubscriber {
    
    typealias EventHandling = ((Event) -> ())?

    public class State: ObservableObject {
        /// The current participants dictionary.
        @Published public internal(set) var participants = [String: CallParticipant]() {
            didSet {
                log.debug("Participants changed: \(participants)")
            }
        }
        /// The call info published to the participants.
        @Published public internal(set) var callData: CallData?
        /// Indicates the reconnection status..
        @Published public internal(set) var reconnectionStatus = ReconnectionStatus.connected
        /// The call recording state.
        @Published public internal(set) var recordingState: RecordingState = .noRecording
        /// The total number of participants connected to the call.
        @Published public internal(set) var participantCount: UInt32 = 0
    }
    
    public internal(set) var state = Call.State()
    
    /// The id of the current session.
    public internal(set) var sessionId: String = ""
    
    /// The call id.
    public let callId: String
    /// The call type.
    public let callType: String
    
    /// The unique identifier of the call, formatted as `callType.name:callId`.
    public var cId: String {
        callCid(from: callId, callType: callType)
    }
    
    private let coordinatorClient: CoordinatorClient
    internal let callController: CallController
    private let recordingController: RecordingController
    private let permissionsController: PermissionsController
    private let livestreamController: LivestreamController
    private let members: [Member]
    private let videoOptions: VideoOptions
    private var broadcastingTask: Task<Void, Never>?
    private var continuation: AsyncStream<Event>.Continuation?
    private var eventHandlers = [EventHandling]()
    
    internal init(
        callId: String,
        callType: String,
        coordinatorClient: CoordinatorClient,
        callController: CallController,
        recordingController: RecordingController,
        permissionsController: PermissionsController,
        livestreamController: LivestreamController,
        members: [Member],
        videoOptions: VideoOptions
    ) {
        self.callId = callId
        self.callType = callType
        self.coordinatorClient = coordinatorClient
        self.callController = callController
        self.recordingController = recordingController
        self.permissionsController = permissionsController
        self.livestreamController = livestreamController
        self.members = members
        self.videoOptions = videoOptions
        self.callController.call = self
    }
    
    /// Joins the current call.
    /// - Parameters:
    ///  - ring: whether the call should ring, `false` by default.
    ///  - notify: whether the participants should be notified about the call.
    ///  - callSettings: optional call settings.
    /// - Throws: An error if the call could not be joined.
    public func join(
        ring: Bool = false,
        notify: Bool = false,
        callSettings: CallSettings = CallSettings()
    ) async throws {
        try await callController.joinCall(
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
    ) async throws -> CallData {
        try await callController.getCall(
            callId: callId,
            type: callType,
            membersLimit: membersLimit,
            ring: ring,
            notify: notify
        )
    }
    
    /// Rings the call (sends call notification to members).
    /// - Returns: The call's data.
    @discardableResult
    public func ring() async throws -> CallData {
        try await get(ring: true)
    }
    
    /// Notifies the users of the call, by sending push notification.
    /// - Returns: The call's data.
    @discardableResult
    public func notify() async throws -> CallData {
        try await get(notify: true)
    }
    
    /// Gets or creates the call on the backend with the given parameters.
    ///
    /// - Parameters:
    ///  - members: An optional array of User objects to add to the call.
    ///  - startsAt: An optional Date object representing the time the call is scheduled to start.
    ///  - customData: An optional dictionary of custom data to attach to the call.
    ///  - membersLimit: An optional integer specifying the maximum number of members allowed in the call.
    ///  - notify: A boolean value indicating whether members should be notified about the call.
    ///  - ring: A boolean value indicating whether to ring the call.
    /// - Throws: An error if the call creation fails.
    /// - Returns: The call's data.
    public func getOrCreate(
        members: [Member] = [],
        startsAt: Date? = nil,
        customData: [String: RawJSON] = [:],
        membersLimit: Int? = nil,
        notify: Bool = false,
        ring: Bool = false
    ) async throws -> CallData {
        try await callController.getOrCreateCall(
            members: members,
            startsAt: startsAt,
            customData: customData,
            membersLimit: membersLimit,
            ring: ring,
            notify: notify
        )
    }
    
    /// Accepts an incoming call.
    public func accept() async throws {
        _ = try await callController.callCoordinatorController.acceptCall(
            callId: callId,
            type: callType
        )
    }
    
    /// Rejects a call.
    public func reject() async throws {
        _ = try await callController.callCoordinatorController.rejectCall(
            callId: callId,
            type: callType
        )
    }
    
    /// Adds the given user to the list of blocked users for the call.
    /// - Parameter blockedUser: The user to add to the list of blocked users.
    public func add(blockedUser: User) {
        var blockedUsers = state.callData?.blockedUsers ?? []
        if !blockedUsers.contains(blockedUser) {
            blockedUsers.append(blockedUser)
            state.callData?.blockedUsers = blockedUsers
        }
    }
    
    /// Removes the given user from the list of blocked users for the call.
    /// - Parameter blockedUser: The user to remove from the list of blocked users.
    public func remove(blockedUser: User) {
        state.callData?.blockedUsers.removeAll { user in
            user.id == blockedUser.id
        }
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
    
    /// Adds members with the specified `ids` to the current call.
    /// - Parameter ids: An array of `String` values representing the member IDs to add.
    /// - Throws: An error if the members could not be added to the call.
    public func addMembers(ids: [String]) async throws -> [Member] {
        try await callController.addMembersToCall(ids: ids)
    }
    
    /// Remove members with the specified `ids` from the current call.
    /// - Parameter ids: An array of `String` values representing the member IDs to remove.
    /// - Throws: An error if the members could not be removed from the call.
    public func removeMembers(ids: [String]) async throws -> [Member] {
        try await callController.removeMembersFromCall(ids: ids)
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
    
    public func subscribe() -> AsyncStream<Event> {
        AsyncStream(Event.self) { [weak self] continuation in
            self?.continuation = continuation
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
        continuation?.finish()
        continuation = nil
        eventHandlers.removeAll()
        broadcastingTask?.cancel()
        recordingController.cleanUp()
        permissionsController.cleanUp()
        callController.cleanUp()
        livestreamController.cleanUp()
    }
    
    //MARK: - Permissions
    
    /// Checks if the current user can request permissions.
    /// - Parameter permissions: The permissions to request.
    /// - Returns: A Boolean value indicating if the current user can request the permissions.
    public func currentUserCanRequestPermissions(_ permissions: [Permission]) -> Bool {
        permissionsController.currentUserCanRequestPermissions(permissions)
    }
    
    /// Requests permissions for a call.
    /// - Parameters:
    ///   - permissions: The permissions to request.
    /// - Throws: A `ClientError.MissingPermissions` if the current user can't request the permissions.
    public func request(permissions: [Permission]) async throws {
        try await permissionsController.request(permissions: permissions, callId: callId, callType: callType)
    }
    
    /// Checks if the current user has a certain call capability.
    /// - Parameter capability: The capability to check.
    /// - Returns: A Boolean value indicating if the current user has the call capability.
    public func currentUserHasCapability(_ capability: OwnCapability) -> Bool {
        permissionsController.currentUserHasCapability(capability)
    }
    
    /// Grants permissions to a user for a call.
    /// - Parameters:
    ///   - permissions: The permissions to grant.
    ///   - userId: The ID of the user to grant permissions to.
    /// - Throws: An error if the operation fails.
    public func grant(
        permissions: [Permission],
        for userId: String
    ) async throws {
        try await permissionsController.grant(
            permissions: permissions,
            for: userId,
            callId: callId,
            callType: callType
        )
    }
    
    /// Revokes permissions for a user in a call.
    /// - Parameters:
    ///   - permissions: The list of permissions to revoke.
    ///   - userId: The ID of the user to revoke the permissions from.
    /// - Throws: error if the permission update fails.
    public func revoke(
        permissions: [Permission],
        for userId: String
    ) async throws {
        try await permissionsController.revoke(
            permissions: permissions,
            for: userId,
            callId: callId,
            callType: callType
        )
    }
    
    /// Mute users in a call.
    /// - Parameters:
    ///   - request: The mute request.
    /// - Throws: error if muting the users fails.
    public func muteUsers(
        with request: MuteRequest
    ) async throws {
        try await permissionsController.muteUsers(
            with: request,
            callId: callId,
            callType: callType
        )
    }
    
    /// Ends a call.
    /// - Throws: error if ending the call fails.
    public func end() async throws {
        try await permissionsController.endCall(callId: callId, callType: callType)
    }
    
    /// Blocks a user in a call.
    /// - Parameters:
    ///   - userId: The ID of the user to block.
    /// - Throws: error if blocking the user fails.
    public func blockUser(with userId: String) async throws {
        try await permissionsController.blockUser(with: userId, callId: callId, callType: callType)
    }
    
    /// Unblocks a user in a call.
    /// - Parameters:
    ///   - userId: The ID of the user to unblock.
    /// - Throws: error if unblocking the user fails.
    public func unblockUser(with userId: String) async throws {
        try await permissionsController.unblockUser(with: userId, callId: callId, callType: callType)
    }
    
    /// Starts a live call.
    /// - Throws: `ClientError.MissingPermissions` if the current user doesn't have the capability to update the call.
    public func goLive() async throws {
        try await permissionsController.goLive(callId: callId, callType: callType)
    }
    
    /// Stops an ongoing live call.
    /// - Throws: `ClientError.MissingPermissions` if the current user doesn't have the capability to update the call.
    public func stopLive() async throws {
        try await permissionsController.stopLive(callId: callId, callType: callType)
    }
    
    //MARK: - Recording
    
    /// Starts recording for the call.
    public func startRecording() async throws {
        try await recordingController.startRecording(callId: callId, callType: callType)
    }
    
    /// Stops recording a call.
    public func stopRecording() async throws {
        try await recordingController.stopRecording(callId: callId, callType: callType)
    }
    
    /// Lists recordings for the call.
    public func listRecordings() async throws -> [CallRecordingInfo] {
        try await recordingController.listRecordings(
            callId: callId,
            callType: callType,
            session: callId
        )
    }
    
    //MARK: - Broadcasting
    
    /// Starts broadcasting of the call.
    public func startBroadcasting() async throws {
        try await livestreamController.startBroadcasting()
    }
    
    /// Stops broadcasting of the call.
    public func stopBroadcasting() async throws {
        try await livestreamController.stopBroadcasting()
    }
    
    //MARK: - Events
    
    /// Sends a custom event to the call.
    /// - Parameter event: The `SendEventRequest` object representing the custom event to send.
    /// - Throws: An error if the sending fails.
    @discardableResult
    public func send(event: SendEventRequest) async throws -> SendEventResponse {
        return try await coordinatorClient.sendEvent(
            type: callType,
            callId: callId,
            request: event
        )
    }
    
    /// Sends a reaction to the call.
    /// - Parameter reaction: The `SendReactionRequest` object representing the reaction to send.
    /// - Throws: An error if the sending fails.
    @discardableResult
    public func send(reaction: SendReactionRequest) async throws -> SendReactionResponse {
        try await coordinatorClient.sendReaction(
            type: callType,
            callId: callId,
            request: reaction
        )
    }
    
    //MARK: - Internal
    
    internal func update(reconnectionStatus: ReconnectionStatus) {
        if reconnectionStatus != self.state.reconnectionStatus {
            self.state.reconnectionStatus = reconnectionStatus
        }
    }
    
    internal func update(callData: CallData) {
        guard callData.callCid == cId else { return }
        var updated = callData
        let members = self.state.callData?.members ?? []
        if callData.members.isEmpty && !members.isEmpty {
            updated.members = members
        }
        self.state.callData = updated
    }
    
    internal func update(recordingState: RecordingState) {
        self.state.recordingState = recordingState
    }
    
    internal func onEvent(_ event: Event) {
        guard let wsCallEvent = event as? WSCallEvent, wsCallEvent.callCid == cId else {
            return
        }
        if let event = event as? CallAcceptedEvent {
            let callData = event.call.toCallData(
                members: [],
                blockedUsers: event.call.blockedUserIds.map { UserResponse.make(from: $0) }
            )
            update(callData: callData)
        } else if let event = event as? CallRejectedEvent {
            let callData = event.call.toCallData(
                members: [],
                blockedUsers: event.call.blockedUserIds.map { UserResponse.make(from: $0) }
            )
            update(callData: callData)
        } else if let event = event as? CallUpdatedEvent {
            let callData = event.call.toCallData(
                members: [],
                blockedUsers: event.call.blockedUserIds.map { UserResponse.make(from: $0) }
            )
            update(callData: callData)
        } else if event is CallRecordingStartedEvent {
            if self.state.callData?.recording == false {
                self.state.callData?.recording = true
                self.state.recordingState = .recording
            }
        } else if event is CallRecordingStoppedEvent {
            if self.state.callData?.recording == true {
                self.state.callData?.recording = false
                self.state.recordingState = .noRecording
            }
        }
        continuation?.yield(event)
        for eventHandler in eventHandlers {
            eventHandler?(event)
        }
    }
}

public enum ReconnectionStatus {
    case connected
    case reconnecting
    case disconnected
}
