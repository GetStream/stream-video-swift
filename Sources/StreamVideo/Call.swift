//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

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
    public var sessionId: String = "" //TODO: check
    
    public let callId: String
    public let callType: CallType
    
    /// The unique identifier of the call, formatted as `callType.name:callId`.
    public var cId: String {
        "\(callType.name):\(callId)"
    }
    
    /// The closure that handles the participant events.
    var onParticipantEvent: ((ParticipantEvent) -> Void)?
    
    private let callController: CallController
    private let members: [User]
    
    internal init(
        callId: String,
        callType: CallType,
        callController: CallController,
        members: [User]
    ) {
        self.callId = callId
        self.callType = callType
        self.callController = callController
        self.members = members
        self.callController.call = self
    }
    
    public func join(ring: Bool = false) async throws {
        try await callController.joinCall(
            callType: callType,
            callId: callId,
            callSettings: CallSettings(), //TODO: update
            videoOptions: VideoOptions(), //TODO: update
            participants: members,
            ring: ring
        )
    }
    
    /// Joins a call on the specified `edgeServer`.
    /// - Parameters:
    ///   - edgeServer: The `EdgeServer` to join the call on.
    /// - Throws: An error if the call could not be joined.
    public func joinCall(
        on edgeServer: EdgeServer
    ) async throws {
        try await callController.joinCall(
            on: edgeServer,
            callType: callType,
            callId: callId,
            callSettings: CallSettings(), //TODO:
            videoOptions: VideoOptions() //TODO:
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
    public func addMembersToCall(ids: [String]) async throws {
        try await callController.addMembersToCall(ids: ids)
    }
    
    /// Sets a `videoFilter` for the current call.
    /// - Parameter videoFilter: A `VideoFilter` instance representing the video filter to set.
    public func setVideoFilter(_ videoFilter: VideoFilter?) {
        callController.setVideoFilter(videoFilter)
    }
    
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
