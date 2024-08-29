//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamWebRTC

/// Observable object that provides info about the call state, as well as methods for updating it.
public class Call: @unchecked Sendable, WSEventsSubscriber {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.callCache) var callCache

    private lazy var stateMachine: StreamCallStateMachine = .init(self)

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
    internal let coordinatorClient: DefaultAPI
    private var eventHandlers = [EventHandler]()
    private var cancellables = DisposableBag()

    internal init(
        callType: String,
        callId: String,
        coordinatorClient: DefaultAPI,
        callController: CallController,
        callSettings: CallSettings? = nil
    ) {
        self.callId = callId
        self.callType = callType
        self.coordinatorClient = coordinatorClient
        self.callController = callController
        microphone = MicrophoneManager(
            callController: callController,
            initialStatus: .enabled
        )
        camera = CameraManager(
            callController: callController,
            initialStatus: .enabled,
            initialDirection: .front
        )
        speaker = SpeakerManager(
            callController: callController,
            initialSpeakerStatus: .enabled,
            initialAudioOutputStatus: .enabled
        )

        /// If we received a non-nil initial callSettings, we updated them here.
        if let callSettings {
            Task { @MainActor [weak self] in
                self?.state.update(callSettings: callSettings)
            }
        }

        self.callController.call = self
        // It's important to instantiate the stateMachine as soon as possible
        // to ensure it's uniqueness.
        _ = stateMachine
        subscribeToOwnCapabilitiesChanges()
        subscribeToLocalCallSettingsChanges()
        subscribeToNoiseCancellationSettingsChanges()
        subscribeToTranscriptionSettingsChanges()
    }

    internal convenience init(
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

    deinit {
        cancellables.removeAll()
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
        let currentStage = stateMachine.currentStage
        switch currentStage.id {
        case .joining:
            break
        case .joined where currentStage is StreamCallStateMachine.Stage.JoinedStage:
            let stage = currentStage as! StreamCallStateMachine.Stage.JoinedStage
            return stage.response
        default:
            try stateMachine.transition(
                .joining(
                    self,
                    actionBlock: { [weak self] in
                        guard let self else { throw ClientError.Unexpected() }
                        return try await executeTask(retryPolicy: .fastAndSimple, task: { [weak self] in
                            guard let self else { throw ClientError.Unexpected() }
                            let response = try await callController.joinCall(
                                create: create,
                                callType: callType,
                                callId: callId,
                                callSettings: callSettings,
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
                            Task { @MainActor [weak self] in
                                self?.streamVideo.state.activeCall = self
                            }
                            return response
                        })
                    }
                )
            )
        }

        return try await stateMachine
            .nextStageShouldBe(
                StreamCallStateMachine.Stage.JoinedStage.self,
                dropFirst: 1
            )
            .response
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
    ) async throws -> GetCallResponse {
        let response = try await coordinatorClient.getCall(
            type: callType,
            id: callId,
            membersLimit: membersLimit,
            ring: ring,
            notify: notify
        )
        await state.update(from: response)
        if ring {
            Task { @MainActor in
                streamVideo.state.ringingCall = self
            }
        }
        return response
    }

    /// Rings the call (sends call notification to members).
    /// - Returns: The call's data.
    @discardableResult
    public func ring() async throws -> CallResponse {
        let response = try await get(ring: true)
        await state.update(from: response)
        return response.call
    }

    /// Notifies the users of the call, by sending push notification.
    /// - Returns: The call's data.
    @discardableResult
    public func notify() async throws -> CallResponse {
        let response = try await get(notify: true)
        await state.update(from: response)
        return response.call
    }

    /// Creates a call with the specified parameters.
    /// - Parameters:
    ///   - members: An optional array of `MemberRequest` objects to add to the call.
    ///   - memberIds: An optional array of member IDs to add to the call.
    ///   - custom: An optional dictionary of custom data to include in the call request.
    ///   - startsAt: An optional `Date` indicating when the call should start.
    ///   - team: An optional string representing the team for the call.
    ///   - ring: A boolean indicating whether to ring the call. Default is `false`.
    ///   - notify: A boolean indicating whether to send notifications. Default is `false`.
    ///   - maxDuration: An optional integer representing the maximum duration of the call in seconds.
    ///   - maxParticipants: An optional integer representing the maximum number of participants allowed in the call.
    ///   - backstage: An optional backstage request.
    /// - Returns: A `CallResponse` object representing the created call.
    /// - Throws: An error if the call creation fails.
    @discardableResult
    public func create(
        members: [MemberRequest]? = nil,
        memberIds: [String]? = nil,
        custom: [String: RawJSON]? = nil,
        startsAt: Date? = nil,
        team: String? = nil,
        ring: Bool = false,
        notify: Bool = false,
        maxDuration: Int? = nil,
        maxParticipants: Int? = nil,
        backstage: BackstageSettingsRequest? = nil
    ) async throws -> CallResponse {
        var membersRequest = [MemberRequest]()
        memberIds?.forEach {
            membersRequest.append(.init(userId: $0))
        }
        members?.forEach {
            membersRequest.append($0)
        }
        
        var settingsOverride: CallSettingsRequest?
        var limits: LimitsSettingsRequest?
        if maxDuration != nil || maxParticipants != nil {
            limits = .init(
                maxDurationSeconds: maxDuration,
                maxParticipants: maxParticipants
            )
        }

        settingsOverride = CallSettingsRequest(
            backstage: backstage,
            limits: limits
        )
        
        let request = GetOrCreateCallRequest(
            data: CallRequest(
                custom: custom,
                members: membersRequest,
                settingsOverride: settingsOverride,
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
            Task { @MainActor in
                streamVideo.state.ringingCall = self
            }
        }
        return response.call
    }

    /// Updates an existing call with the specified parameters.
    /// - Parameters:
    ///   - custom: An optional dictionary of custom data to include in the update request.
    ///   - settingsOverride: An optional `CallSettingsRequest` object to override the call settings.
    ///   - startsAt: An optional `Date` indicating when the call should start.
    /// - Returns: An `UpdateCallResponse` object representing the updated call.
    /// - Throws: An error if the call update fails.
    @discardableResult
    public func update(
        custom: [String: RawJSON]? = nil,
        settingsOverride: CallSettingsRequest? = nil,
        startsAt: Date? = nil
    ) async throws -> UpdateCallResponse {
        let request = UpdateCallRequest(
            custom: custom,
            settingsOverride: settingsOverride,
            startsAt: startsAt
        )
        let response = try await coordinatorClient.updateCall(
            type: callType,
            id: callId,
            updateCallRequest: request
        )
        await state.update(from: response)
        return response
    }

    /// Accepts an incoming call.
    @discardableResult
    public func accept() async throws -> AcceptCallResponse {
        let currentStage = stateMachine.currentStage
        switch currentStage.id {
        case .accepting:
            break
        case .accepted where currentStage is StreamCallStateMachine.Stage.AcceptedStage:
            let stage = currentStage as! StreamCallStateMachine.Stage.AcceptedStage
            return stage.response
        default:
            try stateMachine.transition(.accepting(self, actionBlock: { [coordinatorClient, callType, callId] in
                try await coordinatorClient.acceptCall(type: callType, id: callId)
            }))
        }

        return try await stateMachine
            .nextStageShouldBe(
                StreamCallStateMachine.Stage.AcceptedStage.self,
                dropFirst: 1
            )
            .response
    }

    /// Rejects a call with an optional reason.
    /// - Parameters:
    ///   - reason: An optional `String` providing the reason for the rejection. Default is `nil`.
    /// - Returns: A `RejectCallResponse` object indicating the result of the rejection.
    /// - Throws: An error if the rejection fails.
    @discardableResult
    public func reject(reason: String? = nil) async throws -> RejectCallResponse {
        let currentStage = stateMachine.currentStage
        switch currentStage.id {
        case .rejecting:
            break
        case .rejected where currentStage is StreamCallStateMachine.Stage.RejectedStage:
            let stage = currentStage as! StreamCallStateMachine.Stage.RejectedStage
            return stage.response
        default:
            try stateMachine.transition(.rejecting(self, actionBlock: { [coordinatorClient, callType, callId, streamVideo, cId] in
                let response = try await coordinatorClient.rejectCall(
                    type: callType,
                    id: callId,
                    rejectCallRequest: .init(reason: reason)
                )
                if streamVideo.state.ringingCall?.cId == cId {
                    Task { @MainActor in
                        streamVideo.state.ringingCall = nil
                    }
                }
                return response
            }))
        }

        return try await stateMachine
            .nextStageShouldBe(
                StreamCallStateMachine.Stage.RejectedStage.self,
                dropFirst: 1
            )
            .response
    }

    /// Adds the given user to the list of blocked users for the call.
    /// - Parameter blockedUser: The user to add to the list of blocked users.
    @discardableResult
    public func block(user: User) async throws -> BlockUserResponse {
        try await blockUser(with: user.id)
    }

    /// Removes the given user from the list of blocked users for the call.
    /// - Parameter blockedUser: The user to remove from the list of blocked users.
    @discardableResult
    public func unblock(user: User) async throws -> UnblockUserResponse {
        try await unblockUser(with: user.id)
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
        try await updateCallMembers(
            updateMembers: members
        )
    }

    @discardableResult
    public func updateMembers(members: [MemberRequest]) async throws -> UpdateCallMembersResponse {
        try await updateCallMembers(
            updateMembers: members
        )
    }

    /// Adds members with the specified `ids` to the current call.
    /// - Parameter ids: An array of `String` values representing the member IDs to add.
    /// - Throws: An error if the members could not be added to the call.
    @discardableResult
    public func addMembers(ids: [String]) async throws -> UpdateCallMembersResponse {
        try await updateCallMembers(
            updateMembers: ids.map { MemberRequest(userId: $0) }
        )
    }

    /// Remove members with the specified `ids` from the current call.
    /// - Parameter ids: An array of `String` values representing the member IDs to remove.
    /// - Throws: An error if the members could not be removed from the call.
    @discardableResult
    public func removeMembers(ids: [String]) async throws -> UpdateCallMembersResponse {
        try await updateCallMembers(
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

    /// Sets an`audioFilter` for the current call.
    /// - Parameter audioFilter: An `AudioFilter` instance representing the audio filter to set.
    public func setAudioFilter(_ audioFilter: AudioFilter?) {
        streamVideo.videoConfig.audioProcessingModule.setAudioFilter(audioFilter)
    }

    /// Starts screensharing from the device.
    /// - Parameter type: The screensharing type (in-app or broadcasting).
    public func startScreensharing(type: ScreensharingType) async throws {
        try await callController.startScreensharing(type: type)
    }

    /// Stops screensharing from the current device.
    public func stopScreensharing() async throws {
        try await callController.stopScreensharing()
    }

    /// Subscribes to video events.
    /// - Returns: `AsyncStream` of `VideoEvent`s.
    public func subscribe() -> AsyncStream<VideoEvent> {
        AsyncStream(VideoEvent.self) { [weak self] continuation in
            let eventHandler = EventHandler(handler: { event in
                guard case let .coordinatorEvent(event) = event else {
                    return
                }
                continuation.yield(event)
            }, cancel: { continuation.finish() })
            self?.eventHandlers.append(eventHandler)
        }
    }

    /// Subscribes to a particular web socket event.
    /// - Parameter event: the type of the event you are subscribing to.
    /// - Returns: `AsyncStream` of web socket events from the provided type.
    public func subscribe<WSEvent: Event>(for event: WSEvent.Type) -> AsyncStream<WSEvent> {
        AsyncStream(event) { [weak self] continuation in
            let eventHandler = EventHandler(handler: { event in
                guard case let .coordinatorEvent(event) = event else {
                    return
                }
                if let event = event.rawValue as? WSEvent {
                    continuation.yield(event)
                }
            }, cancel: { continuation.finish() })

            self?.eventHandlers.append(eventHandler)
        }
    }

    /// Leave the current call.
    public func leave() {
        postNotification(with: CallNotification.callEnded, object: self)
        eventHandlers.forEach { $0.cancel() }

        cancellables.removeAll()
        eventHandlers.removeAll()
        callController.cleanUp()
        try? stateMachine.transition(.idle(self))
        /// Upon `Call.leave` we remove the call from the cache. Any further actions that are required
        /// to happen on the call object (e.g. rejoin) will need to fetch a new instance from `StreamVideo`
        /// client.
        callCache.remove(for: cId)
        Task { @MainActor in
            if streamVideo.state.ringingCall?.cId == cId {
                streamVideo.state.ringingCall = nil
            }
            if streamVideo.state.activeCall?.cId == cId {
                streamVideo.state.activeCall = nil
            }
        }
    }

    /// Starts noise cancellation asynchronously.
    /// - Throws: `ClientError.MissingPermissions` if the current user does not have the
    /// capability to enable noise cancellation.
    /// - Throws: An error if starting noise cancellation fails.
    public func startNoiseCancellation() async throws {
        guard await currentUserHasCapability(.enableNoiseCancellation) else {
            throw ClientError.MissingPermissions()
        }
        try await callController.startNoiseCancellation(state.sessionId)
    }

    /// Stops noise cancellation asynchronously.
    /// - Throws: An error if stopping noise cancellation fails.
    public func stopNoiseCancellation() async throws {
        try await callController.stopNoiseCancellation(state.sessionId)
    }

    // MARK: - Permissions

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
        let response = try await coordinatorClient.blockUser(
            type: callType,
            id: callId,
            blockUserRequest: BlockUserRequest(userId: userId)
        )
        await state.blockUser(id: userId)
        return response
    }

    /// Unblocks a user in a call.
    /// - Parameters:
    ///   - userId: The ID of the user to unblock.
    /// - Throws: error if unblocking the user fails.
    @discardableResult
    public func unblockUser(with userId: String) async throws -> UnblockUserResponse {
        let response = try await coordinatorClient.unblockUser(
            type: callType,
            id: callId,
            unblockUserRequest: UnblockUserRequest(userId: userId)
        )
        await state.unblockUser(id: userId)
        return response
    }

    /// Starts a live call.
    /// - Parameters:
    ///  - startsHls: whether hls streaming should be started.
    ///  - startRecording: whether recording should be started.
    ///  - startTranscription: whether transcription should be started.
    /// - Returns: `GoLiveResponse`.
    @discardableResult
    public func goLive(
        startHls: Bool? = nil,
        startRecording: Bool? = nil,
        startTranscription: Bool? = nil
    ) async throws -> GoLiveResponse {
        let goLiveRequest = GoLiveRequest(
            startHls: startHls,
            startRecording: startRecording,
            startTranscription: startTranscription
        )
        return try await coordinatorClient.goLive(
            type: callType,
            id: callId,
            goLiveRequest: goLiveRequest
        )
    }

    /// Stops an ongoing live call.
    @discardableResult
    public func stopLive() async throws -> StopLiveResponse {
        try await coordinatorClient.stopLive(type: callType, id: callId)
    }

    // MARK: - Recording

    /// Starts recording for the call.
    @discardableResult
    public func startRecording() async throws -> StartRecordingResponse {
        let response = try await coordinatorClient.startRecording(
            type: callType,
            id: callId,
            startRecordingRequest: StartRecordingRequest()
        )
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
        let response = try await coordinatorClient.listRecordings(
            type: callType,
            id: callId
        )
        return response.recordings
    }

    // MARK: - Broadcasting

    /// Starts HLS broadcasting of the call.
    @discardableResult
    public func startHLS() async throws -> StartHLSBroadcastingResponse {
        try await coordinatorClient.startHLSBroadcasting(type: callType, id: callId)
    }

    /// Stops HLS broadcasting of the call.
    @discardableResult
    public func stopHLS() async throws -> StopHLSBroadcastingResponse {
        try await coordinatorClient.stopHLSBroadcasting(type: callType, id: callId)
    }

    // MARK: - Events

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
    public func sendReaction(
        type: String,
        custom: [String: RawJSON]? = nil,
        emojiCode: String? = nil
    ) async throws -> SendReactionResponse {
        try await coordinatorClient.sendVideoReaction(
            type: callType,
            id: callId,
            sendReactionRequest: SendReactionRequest(custom: custom, emojiCode: emojiCode, type: type)
        )
    }

    // MARK: - Query members methods

    internal func queryMembers(
        filters: [String: RawJSON]? = nil, limit: Int? = nil, next: String? = nil, sort: [SortParamRequest]? = nil
    ) async throws -> QueryMembersResponse {
        let request = QueryMembersRequest(
            filterConditions: filters,
            id: callId,
            limit: limit,
            next: next,
            sort: sort,
            type: callType
        )
        let response = try await coordinatorClient.queryMembers(queryMembersRequest: request)
        await state.mergeMembers(response.members)
        return response
    }

    public func queryMembers(
        filters: [String: RawJSON]? = nil,
        sort: [SortParamRequest] = [SortParamRequest.descending("created_at")],
        limit: Int = 25
    ) async throws -> QueryMembersResponse {
        try await queryMembers(filters: filters, limit: limit, sort: sort)
    }

    public func queryMembers(next: String) async throws -> QueryMembersResponse {
        try await queryMembers(filters: nil, limit: nil, next: next, sort: nil)
    }

    // MARK: - Pinning

    /// Pins the user with the provided session id locally.
    /// - Parameter sessionId: the user's session id.
    public func pin(
        sessionId: String
    ) async throws {
        try await callController.changePinState(
            isEnabled: true,
            sessionId: sessionId
        )
    }

    /// Unpins the user with the provided session id locally.
    /// - Parameter sessionId: the user's session id.
    public func unpin(
        sessionId: String
    ) async throws {
        try await callController.changePinState(
            isEnabled: false,
            sessionId: sessionId
        )
    }

    /// Pins the user with the provided session id for everyone in the call.
    /// - Parameters:
    ///  - userId: the user's id.
    ///  - sessionId: the user's session id.
    /// - Returns: `PinResponse`
    public func pinForEveryone(
        userId: String,
        sessionId: String
    ) async throws -> PinResponse {
        if await !currentUserHasCapability(.pinForEveryone) {
            throw ClientError.MissingPermissions()
        }
        let pinRequest = PinRequest(sessionId: sessionId, userId: userId)
        return try await coordinatorClient.videoPin(
            type: callType,
            id: callId,
            pinRequest: pinRequest
        )
    }

    /// Unpins the user with the provided session id for everyone in the call.
    /// - Parameters:
    ///  - userId: the user's id.
    ///  - sessionId: the user's session id.
    /// - Returns: `UnpinResponse`
    public func unpinForEveryone(
        userId: String,
        sessionId: String
    ) async throws -> UnpinResponse {
        if await !currentUserHasCapability(.pinForEveryone) {
            throw ClientError.MissingPermissions()
        }
        let unpinRequest = UnpinRequest(sessionId: sessionId, userId: userId)
        return try await coordinatorClient.videoUnpin(
            type: callType,
            id: callId,
            unpinRequest: unpinRequest
        )
    }

    /// Tries to focus the camera at the specified point within the view.
    ///
    /// The method delegates the focus action to the `callController`'s `focus(at:)`
    /// method, which is expected to handle the camera focus logic. If an error occurs during the process,
    /// it throws an exception.
    ///
    /// - Parameter point: A `CGPoint` value representing the location within the view where the
    /// camera should focus. The point (0, 0) is at the top-left corner of the view, and the point (1, 1) is at
    /// the bottom-right corner.
    /// - Throws: An error if the focus operation cannot be completed. The type of error depends on
    /// the underlying implementation in the `callController`.
    ///
    /// - Note: Ensure that the device supports tap to focus and that it is enabled before calling this
    /// method. Otherwise, it might result in an error.
    public func focus(at point: CGPoint) throws {
        try callController.focus(at: point)
    }

    /// Adds the `AVCapturePhotoOutput` on the `CameraVideoCapturer` to enable photo
    /// capturing capabilities.
    ///
    /// This method configures the local user's `CameraVideoCapturer` with an
    /// `AVCapturePhotoOutput` for capturing photos. This enhancement allows applications to capture
    /// still images while video capturing is ongoing.
    ///
    /// - Parameter capturePhotoOutput: The `AVCapturePhotoOutput` instance to be added
    /// to the `CameraVideoCapturer`. This output enables the capture of photos alongside video
    /// capturing.
    ///
    /// - Throws: An error if the `CameraVideoCapturer` does not support adding an `AVCapturePhotoOutput`.
    /// This method is specifically designed for `RTCCameraVideoCapturer` instances. If the
    /// `CameraVideoCapturer` in use does not support photo output functionality, an appropriate error
    /// will be thrown to indicate that the operation is not supported.
    ///
    /// - Warning: A maximum of one output of each type may be added.
    public func addCapturePhotoOutput(_ capturePhotoOutput: AVCapturePhotoOutput) throws {
        try callController.addCapturePhotoOutput(capturePhotoOutput)
    }

    /// Removes the `AVCapturePhotoOutput` from the `CameraVideoCapturer` to disable photo
    /// capturing capabilities.
    ///
    /// This method configures the local user's `CameraVideoCapturer` by removing an
    /// `AVCapturePhotoOutput` previously added for capturing photos. This action is necessary when
    /// the application needs to stop capturing still images or when adjusting the capturing setup. It ensures
    /// that the video capturing process can continue without the overhead or interference of photo
    /// capturing capabilities.
    ///
    /// - Parameter capturePhotoOutput: The `AVCapturePhotoOutput` instance to be removed
    /// from the `CameraVideoCapturer`. Removing this output disables the capture of photos alongside
    /// video capturing.
    ///
    /// - Throws: An error if the `CameraVideoCapturer` does not support removing an
    /// `AVCapturePhotoOutput`.
    /// This method is specifically designed for `RTCCameraVideoCapturer` instances. If the
    /// `CameraVideoCapturer` in use does not support the removal of photo output functionality, an
    /// appropriate error will be thrown to indicate that the operation is not supported.
    ///
    /// - Note: Ensure that the `AVCapturePhotoOutput` being removed was previously added to the
    /// `CameraVideoCapturer`. Attempting to remove an output that is not currently added will not
    /// affect the capture session but may result in unnecessary processing.
    public func removeCapturePhotoOutput(_ capturePhotoOutput: AVCapturePhotoOutput) throws {
        try callController.removeCapturePhotoOutput(capturePhotoOutput)
    }

    /// Adds an `AVCaptureVideoDataOutput` to the `CameraVideoCapturer` for video frame
    /// processing capabilities.
    ///
    /// This method configures the local user's `CameraVideoCapturer` with an
    /// `AVCaptureVideoDataOutput`, enabling the processing of video frames. This is particularly
    /// useful for applications that require access to raw video data for analysis, filtering, or other processing
    /// tasks while video capturing is in progress.
    ///
    /// - Parameter videoOutput: The `AVCaptureVideoDataOutput` instance to be added to
    /// the `CameraVideoCapturer`. This output facilitates the capture and processing of live video
    /// frames.
    ///
    /// - Throws: An error if the `CameraVideoCapturer` does not support adding an
    /// `AVCaptureVideoDataOutput`. This functionality is specific to `RTCCameraVideoCapturer`
    /// instances. If the current `CameraVideoCapturer` does not accommodate video output, an error
    /// will be thrown to signify the unsupported operation.
    ///
    /// - Warning: A maximum of one output of each type may be added. For applications linked on or
    /// after iOS 16.0, this restriction no longer applies to AVCaptureVideoDataOutputs. When adding more
    /// than one AVCaptureVideoDataOutput, AVCaptureSession **hardwareCost must be taken into
    /// account as it can result in delayed fames delivery**. Given that WebRTC adds a videoOutput
    /// for frame processing, we cannot accept videoOutputs on versions prior to iOS 16.0.
    @available(iOS 16.0, *)
    public func addVideoOutput(_ videoOutput: AVCaptureVideoDataOutput) throws {
        try callController.addVideoOutput(videoOutput)
    }

    /// Removes an `AVCaptureVideoDataOutput` from the `CameraVideoCapturer` to disable
    /// video frame processing capabilities.
    ///
    /// This method reconfigures the local user's `CameraVideoCapturer` by removing an
    /// `AVCaptureVideoDataOutput` that was previously added. This change is essential when the
    /// application no longer requires access to raw video data for analysis, filtering, or other processing
    /// tasks, or when adjusting the video capturing setup for different operational requirements. It ensures t
    /// hat video capturing can proceed without the additional processing overhead associated with
    /// handling video frame outputs.
    ///
    /// - Parameter videoOutput: The `AVCaptureVideoDataOutput` instance to be removed
    /// from the `CameraVideoCapturer`. Removing this output stops the capture and processing of live video
    /// frames through the specified output, simplifying the capture session.
    ///
    /// - Throws: An error if the `CameraVideoCapturer` does not support removing an
    /// `AVCaptureVideoDataOutput`. This functionality is tailored for `RTCCameraVideoCapturer`
    /// instances. If the `CameraVideoCapturer` being used does not permit the removal of video outputs,
    /// an error will be thrown to indicate the unsupported operation.
    ///
    /// - Note: It is crucial to ensure that the `AVCaptureVideoDataOutput` intended for removal
    /// has been previously added to the `CameraVideoCapturer`. Trying to remove an output that is
    /// not part of the capture session will have no negative impact but could lead to unnecessary processing
    /// and confusion.
    @available(iOS 16.0, *)
    public func removeVideoOutput(_ videoOutput: AVCaptureVideoDataOutput) throws {
        try callController.removeVideoOutput(videoOutput)
    }

    /// Zooms the camera video by the specified factor.
    ///
    /// This method attempts to zoom the camera's video feed by adjusting the `videoZoomFactor` of
    /// the camera's active device. It first checks if the video capturer is of type `RTCCameraVideoCapturer`
    /// and if the current camera device supports zoom by verifying that the `videoMaxZoomFactor` of
    /// the active format is greater than 1.0. If these conditions are met, it proceeds to apply the requested
    /// zoom factor, clamping it within the supported range to avoid exceeding the device's capabilities.
    ///
    /// - Parameter factor: The desired zoom factor. A value of 1.0 represents no zoom, while values
    /// greater than 1.0 increase the zoom level. The factor is clamped to the maximum zoom factor supported
    /// by the device to ensure it remains within valid bounds.
    ///
    /// - Throws: `ClientError.Unexpected` if the video capturer is not of type
    /// `RTCCameraVideoCapturer`, or if the device does not support zoom. Also, throws an error if
    /// locking the device for configuration fails.
    ///
    /// - Note: This method should be used cautiously, as setting a zoom factor significantly beyond the
    /// optimal range can degrade video quality.
    public func zoom(by factor: CGFloat) throws {
        try callController.zoom(by: factor)
    }

    /// Starts transcribing a conversation, optionally specifying an external storage location.
    ///
    /// - Parameter transcriptionExternalStorage: The external storage location for the
    ///  transcription (optional).
    @discardableResult
    public func startTranscription(
        transcriptionExternalStorage: String? = nil
    ) async throws -> StartTranscriptionResponse {
        try await coordinatorClient.startTranscription(
            type: callType,
            id: callId,
            startTranscriptionRequest: .init(
                transcriptionExternalStorage: transcriptionExternalStorage
            )
        )
    }

    /// Stops a conversation from being transcribed and returns whether the stop request was successful
    /// or not.
    ///
    /// - Returns: A StopTranscriptionResponse indicating whether the stop request was successful
    /// or not.
    @discardableResult
    public func stopTranscription() async throws -> StopTranscriptionResponse {
        try await coordinatorClient.stopTranscription(
            type: callType,
            id: callId
        )
    }

    /// Collects user feedback asynchronously.
    ///
    /// - Parameters:
    ///   - custom: Optional custom data in the form of a dictionary of String keys and RawJSON values.
    ///   - rating: Optional rating provided by the user.
    ///   - reason: Optional reason for the user's feedback.
    /// - Returns: An instance of `CollectUserFeedbackResponse` representing the result of \
    /// collecting feedback.
    /// - Throws: An error if the feedback collection process encounters an issue.
    @discardableResult
    @MainActor
    public func collectUserFeedback(
        rating: Int? = nil,
        reason: String? = nil,
        custom: [String: RawJSON]? = nil
    ) async throws -> CollectUserFeedbackResponse {
        try await callController.collectUserFeedback(
            sessionID: state.sessionId,
            custom: custom,
            rating: rating,
            reason: reason
        )
    }
    
    // MARK: - Sorting
    
    /// Updates the sorting of call participants with the provided sort comparators.
    ///
    /// - Parameters:
    ///   - sortComparators: An array of `StreamSortComparator` objects for `CallParticipant`.
    @MainActor
    public func updateParticipantsSorting(
        with sortComparators: [StreamSortComparator<CallParticipant>]
    ) {
        state.sortComparators = sortComparators
    }

    // MARK: - Internal

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
        }

        // Get a copy of eventHandlers to avoid crashes when `leave` call is being
        // triggered, during event processing.
        let eventHandlers = self.eventHandlers
        for eventHandler in eventHandlers {
            eventHandler.handler(event)
        }
    }

    // MARK: - private

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

    private func subscribeToOwnCapabilitiesChanges() {
        executeOnMain { [weak self] in
            guard let self else { return }
            self
                .state
                .$ownCapabilities
                .removeDuplicates()
                .sink { [weak self] in self?.callController.updateOwnCapabilities(ownCapabilities: $0) }
                .store(in: cancellables)
        }
    }

    private func subscribeToLocalCallSettingsChanges() {
        speaker.$status.dropFirst().sink { [weak self] status in
            guard let self else { return }
            executeOnMain {
                let newState = self.state.callSettings.withUpdatedSpeakerState(status.boolValue)
                self.state.update(callSettings: newState)
            }
        }
        .store(in: cancellables)

        speaker.$audioOutputStatus.dropFirst().sink { [weak self] status in
            guard let self else { return }
            executeOnMain {
                let newState = self.state.callSettings.withUpdatedAudioOutputState(status.boolValue)
                self.state.update(callSettings: newState)
            }
        }
        .store(in: cancellables)

        camera.$status.dropFirst().sink { [weak self] status in
            guard let self else { return }
            executeOnMain {
                let newState = self.state.callSettings.withUpdatedVideoState(status.boolValue)
                self.state.update(callSettings: newState)
            }
        }
        .store(in: cancellables)

        camera.$direction.dropFirst().sink { [weak self] position in
            guard let self else { return }
            executeOnMain {
                let newState = self.state.callSettings.withUpdatedCameraPosition(position)
                self.state.update(callSettings: newState)
            }
        }
        .store(in: cancellables)

        microphone.$status.dropFirst().sink { [weak self] status in
            guard let self else { return }
            executeOnMain {
                let newState = self.state.callSettings.withUpdatedAudioState(status.boolValue)
                self.state.update(callSettings: newState)
            }
        }
        .store(in: cancellables)
    }

    private func subscribeToNoiseCancellationSettingsChanges() {
        executeOnMain { [weak self] in
            guard let self else { return }
            self
                .state
                .$settings
                .map(\.?.audio.noiseCancellation)
                .removeDuplicates()
                .sink { [weak self] in self?.didUpdate($0) }
                .store(in: cancellables)
        }
    }

    private func subscribeToTranscriptionSettingsChanges() {
        executeOnMain { [weak self] in
            guard let self else { return }
            self
                .state
                .$settings
                .map(\.?.transcription)
                .removeDuplicates()
                .sink { [weak self] in self?.didUpdate($0) }
                .store(in: cancellables)
        }
    }

    private func updateCallSettingsManagers(with callSettings: CallSettings) {
        microphone.status = callSettings.audioOn ? .enabled : .disabled
        camera.status = callSettings.videoOn ? .enabled : .disabled
        camera.direction = callSettings.cameraPosition
        speaker.status = callSettings.speakerOn ? .enabled : .disabled
        speaker.audioOutputStatus = callSettings.audioOutputOn ? .enabled : .disabled
    }

    /// Handles updates to noise cancellation settings.
    /// - Parameter value: The updated `NoiseCancellationSettings` value.
    private func didUpdate(_ value: NoiseCancellationSettings?) {
        guard let noiseCancellationFilter = streamVideo.videoConfig.noiseCancellationFilter else {
            log
                .warning(
                    "Unable to handle NoiseCancellationSettings. Please refer to the docs to see how to react on those updates."
                )
            return
        }

        let audioProcessingModule = streamVideo.videoConfig.audioProcessingModule

        if let value {
            switch value.mode {
            case .available:
                log.debug("NoiseCancellationSettings updated with mode:\(value.mode).")
            case .disabled where audioProcessingModule.activeAudioFilter?.id == noiseCancellationFilter.id:
                /// Deactivate noiseCancellationFilter if mode is disabled and the noiseCancellation
                /// audioFilter is currently active.
                log
                    .debug(
                        "NoiseCancellationSettings updated with mode:\(value.mode). Will deactivate noiseCancellationFilter:\(noiseCancellationFilter.id)"
                    )
                setAudioFilter(nil)
            case .autoOn
                where audioProcessingModule.activeAudioFilter?.id != noiseCancellationFilter.id && streamVideo
                .isHardwareAccelerationAvailable:
                /// Activate noiseCancellationFilter if mode is autoOn,  hardwareAcceleration is
                /// available and the noiseCancellation audioFilter isn't already enabled.
                log
                    .debug(
                        "NoiseCancellationSettings updated with mode:\(value.mode). Will activate noiseCancellationFilter:\(noiseCancellationFilter.id)"
                    )
                setAudioFilter(noiseCancellationFilter)
            default:
                /// Log a debug message for other cases where no action is required.
                log
                    .debug(
                        "NoiseCancellationSettings updated with mode:\(value.mode) isHardwareAccelerationAvailable:\(streamVideo.isHardwareAccelerationAvailable). No action!"
                    )
            }
        } else {
            log.debug("NoiseCancellationSettings updated. No action!")
        }
    }

    /// Handles updates to transcription settings.
    /// - Parameter value: The updated `TranscriptionSettings` value.
    private func didUpdate(_ value: TranscriptionSettings?) {
        guard let value else {
            log.debug("TranscriptionSettings updated. No action!")
            return
        }

        Task { @MainActor in
            do {
                switch value.mode {
                case .disabled where state.transcribing == true:
                    log.debug("TranscriptionSettings updated with mode:\(value.mode). Will deactivate transcriptions.")
                    try await stopTranscription()
                case .autoOn where state.transcribing == false:
                    log.debug("TranscriptionSettings updated with mode:\(value.mode). Will activate transcriptions.")
                    try await startTranscription()
                default:
                    log.debug("TranscriptionSettings updated with mode:\(value.mode). No action required.")
                }
            } catch {
                log.error(error)
            }
        }
    }
}
