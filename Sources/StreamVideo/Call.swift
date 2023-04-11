//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// Observable object that provides info about the call state, as well as methods for updating it.
public class Call: ObservableObject, @unchecked Sendable {
    
    /// The current participants dictionary.
    @Published public internal(set) var participants = [String: CallParticipant]() {
        didSet {
            log.debug("Participants changed: \(participants)")
        }
    }
    /// The call info published to the participants.
    @Published public private(set) var callInfo: CallInfo?
    /// Indicates the reconnection status..
    @Published public private(set) var reconnectionStatus = ReconnectionStatus.connected
    /// The call recording state.
    @Published public private(set) var recordingState: RecordingState = .noRecording
    
    /// The id of the current session.
    var sessionId: String = ""
    
    /// The call id.
    public let callId: String
    /// The call type.
    public let callType: CallType
    
    /// The unique identifier of the call, formatted as `callType.name:callId`.
    public var cId: String {
        "\(callType.name):\(callId)"
    }
    
    /// The closure that handles the participant events.
    var onParticipantEvent: ((ParticipantEvent) -> Void)?
    
    internal let callController: CallController
    private let recordingController: RecordingController
    private let eventsController: EventsController
    private let permissionsController: PermissionsController
    private let members: [User]
    private let videoOptions: VideoOptions
    private var allEventsMiddleware: AllEventsMiddleware?
    
    internal init(
        callId: String,
        callType: CallType,
        callController: CallController,
        recordingController: RecordingController,
        eventsController: EventsController,
        permissionsController: PermissionsController,
        members: [User],
        videoOptions: VideoOptions,
        allEventsMiddleWare: AllEventsMiddleware?
    ) {
        self.callId = callId
        self.callType = callType
        self.callController = callController
        self.recordingController = recordingController
        self.eventsController = eventsController
        self.permissionsController = permissionsController
        self.members = members
        self.videoOptions = videoOptions
        self.allEventsMiddleware = allEventsMiddleWare
        self.callController.call = self
    }
    
    /// Joins the current call.
    /// - Parameters:
    ///  - ring: whether the call should ring, `false` by default.
    ///  - callSettings: optional call settings.
    /// - Throws: An error if the call could not be joined.
    public func join(
        ring: Bool = false,
        callSettings: CallSettings = CallSettings()
    ) async throws {
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: callSettings,
            videoOptions: videoOptions,
            participants: members,
            ring: ring
        )
    }
    
    /// Joins a call on the specified `edgeServer`.
    /// - Parameters:
    ///   - edgeServer: The `EdgeServer` to join the call on.
    /// - Throws: An error if the call could not be joined.
    public func join(
        on edgeServer: EdgeServer,
        callSettings: CallSettings = CallSettings()
    ) async throws {
        try await callController.joinCall(
            on: edgeServer,
            callType: callType,
            callId: callId,
            callSettings: callSettings,
            videoOptions: videoOptions
        )
    }

    /// Selects an `EdgeServer` for a call with the specified `participants`.
    /// - Parameters:
    ///   - participants: An array of `User` instances representing the participants in the call.
    /// - Returns: An `EdgeServer` instance representing the selected server.
    /// - Throws: An error if an `EdgeServer` could not be selected.
    public func selectEdgeServer(
        participants: [User]
    ) async throws -> EdgeServer {
        try await callController.selectEdgeServer(
            videoOptions: VideoOptions(),
            participants: participants
        )
    }
    
    /// Async stream that publishes participant events.
    public func participantEvents() -> AsyncStream<ParticipantEvent> {
        let events = AsyncStream(ParticipantEvent.self) { [weak self] continuation in
            self?.onParticipantEvent = { event in
                continuation.yield(event)
            }
        }
        return events
    }
    
    /// Adds the given user to the list of blocked users for the call.
    /// - Parameter blockedUser: The user to add to the list of blocked users.
    public func add(blockedUser: User) {
        var blockedUsers = callInfo?.blockedUsers ?? []
        if !blockedUsers.contains(blockedUser) {
            blockedUsers.append(blockedUser)
            callInfo?.blockedUsers = blockedUsers
        }
    }
    
    /// Removes the given user from the list of blocked users for the call.
    /// - Parameter blockedUser: The user to remove from the list of blocked users.
    public func remove(blockedUser: User) {
        callInfo?.blockedUsers.removeAll { user in
            user.id == blockedUser.id
        }
    }
    
    /// Starts capturing the local video.
    public func startCapturingLocalVideo() {
        callController.startCapturingLocalVideo()
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
    public func addMembers(ids: [String]) async throws -> [User] {
        try await callController.addMembersToCall(ids: ids)
    }
    
    /// Remove members with the specified `ids` from the current call.
    /// - Parameter ids: An array of `String` values representing the member IDs to remove.
    /// - Throws: An error if the members could not be removed from the call.
    public func removeMembers(ids: [String]) async throws -> [User] {
        try await callController.removeMembersFromCall(ids: ids)
    }
    
    /// Sets a `videoFilter` for the current call.
    /// - Parameter videoFilter: A `VideoFilter` instance representing the video filter to set.
    public func setVideoFilter(_ videoFilter: VideoFilter?) {
        callController.setVideoFilter(videoFilter)
    }
    
    /// Leave the current call.
    public func leave() {
        postNotification(with: CallNotification.callEnded)
        recordingController.cleanUp()
        eventsController.cleanUp()
        permissionsController.cleanUp()
        callController.cleanUp()
    }
    
    /// Listen to all raw WS events. The data is provided as a dictionary.
    /// `VideoConfig`'s `listenToAllEvents` needs to be true.
    public func allEvents() -> AsyncStream<PublicWSEvent> {
        AsyncStream(PublicWSEvent.self) { [weak self] continuation in
            self?.allEventsMiddleware?.onEvent = { callEvent in
                continuation.yield(callEvent)
            }
        }
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
        try await permissionsController.request(permissions: permissions, callId: callId, callType: callType.name)
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
            callType: callType.name
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
            callType: callType.name
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
            callType: callType.name
        )
    }
    
    /// Ends a call.
    /// - Throws: error if ending the call fails.
    public func end() async throws {
        try await permissionsController.endCall(callId: callId, callType: callType.name)
    }
    
    /// Blocks a user in a call.
    /// - Parameters:
    ///   - userId: The ID of the user to block.
    /// - Throws: error if blocking the user fails.
    public func blockUser(with userId: String) async throws {
        try await permissionsController.blockUser(with: userId, callId: callId, callType: callType.name)
    }
    
    /// Unblocks a user in a call.
    /// - Parameters:
    ///   - userId: The ID of the user to unblock.
    /// - Throws: error if unblocking the user fails.
    public func unblockUser(with userId: String) async throws {
        try await permissionsController.unblockUser(with: userId, callId: callId, callType: callType.name)
    }
    
    /// Starts a live call.
    /// - Throws: `ClientError.MissingPermissions` if the current user doesn't have the capability to update the call.
    public func goLive() async throws {
        try await permissionsController.goLive(callId: callId, callType: callType.name)
    }
    
    /// Stops an ongoing live call.
    /// - Throws: `ClientError.MissingPermissions` if the current user doesn't have the capability to update the call.
    public func stopLive() async throws {
        try await permissionsController.stopLive(callId: callId, callType: callType.name)
    }
    
    /// Returns an `AsyncStream` of `PermissionRequest` objects that represent the permission requests events.
    /// - Returns: An `AsyncStream` of `PermissionRequest` objects.
    public func permissionRequests() -> AsyncStream<PermissionRequest> {
        permissionsController.permissionRequests()
    }
    
    /// Returns an `AsyncStream` of `PermissionsUpdated` objects that represent the permission updates events.
    /// - Returns: An `AsyncStream` of `PermissionsUpdated` objects.
    public func permissionUpdates() -> AsyncStream<PermissionsUpdated> {
        permissionsController.permissionUpdates()
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
            callType: callType.name,
            session: callId
        )
    }
    
    /// Creates an asynchronous stream of `RecordingEvent` objects.
    public func recordingEvents() -> AsyncStream<RecordingEvent> {
        recordingController.recordingEvents()
    }
    
    //MARK: - Events
    
    /// Sends a custom event to the call.
    /// - Parameter event: The `CustomEventRequest` object representing the custom event to send.
    /// - Throws: An error if the sending fails.
    public func send(event: CustomEventRequest) async throws {
        try await eventsController.send(event: event)
    }
    
    /// Sends a reaction to the call.
    /// - Parameter reaction: The `CallReactionRequest` object representing the reaction to send.
    /// - Throws: An error if the sending fails.
    public func send(reaction: CallReactionRequest) async throws {
        try await eventsController.send(reaction: reaction)
    }
    
    /// Returns an asynchronous stream of custom events received during the call.
    /// - Returns: An `AsyncStream` of `CustomEvent` objects.
    public func customEvents() -> AsyncStream<CustomEvent> {
        eventsController.customEvents()
    }
    
    /// Returns an asynchronous stream of reactions received during the call.
    /// - Returns: An `AsyncStream` of `CallReaction` objects.
    public func reactions() -> AsyncStream<CallReaction> {
        eventsController.reactions()
    }
    
    //MARK: - Internal
    
    internal func update(reconnectionStatus: ReconnectionStatus) {
        if reconnectionStatus != self.reconnectionStatus {
            self.reconnectionStatus = reconnectionStatus
        }
    }
    
    internal func update(callInfo: CallInfo) {
        self.callInfo = callInfo
    }
    
    internal func update(recordingState: RecordingState) {
        self.recordingState = recordingState
    }
    
}

public enum ReconnectionStatus {
    case connected
    case reconnecting
    case disconnected
}
