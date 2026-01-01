//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockDefaultAPIEndpoints: DefaultAPIEndpoints, Mockable, @unchecked Sendable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = FunctionKey
        .allCases
        .reduce(into: [FunctionKey: [FunctionInputKey]]()) { $0[$1] = [] }

    func stub<T>(for keyPath: KeyPath<MockDefaultAPIEndpoints, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    enum MockFunctionKey: Hashable, CaseIterable {
        case queryCallMembers
        case queryCallStats
        case getCall
        case updateCall
        case getOrCreateCall
        case acceptCall
        case blockUser
        case deleteCall
        case sendCallEvent
        case collectUserFeedback
        case goLive
        case joinCall
        case kickUser
        case endCall
        case updateCallMembers
        case muteUsers
        case queryCallParticipants
        case videoPin
        case sendVideoReaction
        case listRecordings
        case rejectCall
        case requestPermission
        case startRTMPBroadcasts
        case stopAllRTMPBroadcasts
        case stopRTMPBroadcast
        case startHLSBroadcasting
        case startClosedCaptions
        case startRecording
        case startTranscription
        case stopHLSBroadcasting
        case stopClosedCaptions
        case stopLive
        case stopRecording
        case stopTranscription
        case listTranscriptions
        case unblockUser
        case videoUnpin
        case updateUserPermissions
        case deleteRecording
        case deleteTranscription
        case queryCalls
        case deleteDevice
        case listDevices
        case createDevice
        case getEdges
        case createGuest
        case videoConnect
        case ringCall
    }

    enum MockFunctionInputKey: Payloadable {
        case queryCallMembers(query: QueryMembersRequest)
        case queryCallStats(query: QueryCallStatsRequest)
        case getCall(type: String, id: String, membersLimit: Int?, ring: Bool?, notify: Bool?, video: Bool?)
        case updateCall(type: String, id: String, request: UpdateCallRequest)
        case getOrCreateCall(type: String, id: String, request: GetOrCreateCallRequest)
        case acceptCall(type: String, id: String)
        case blockUser(type: String, id: String, request: BlockUserRequest)
        case deleteCall(type: String, id: String, request: DeleteCallRequest)
        case sendCallEvent(type: String, id: String, request: SendEventRequest)
        case collectUserFeedback(type: String, id: String, request: CollectUserFeedbackRequest)
        case goLive(type: String, id: String, request: GoLiveRequest)
        case joinCall(type: String, id: String, request: JoinCallRequest)
        case kickUser(type: String, id: String, request: KickUserRequest)
        case endCall(type: String, id: String)
        case updateCallMembers(type: String, id: String, request: UpdateCallMembersRequest)
        case muteUsers(type: String, id: String, request: MuteUsersRequest)
        case queryCallParticipants(id: String, type: String, limit: Int?, request: QueryCallParticipantsRequest)
        case videoPin(type: String, id: String, request: PinRequest)
        case sendVideoReaction(type: String, id: String, request: SendReactionRequest)
        case listRecordings(type: String, id: String)
        case rejectCall(type: String, id: String, request: RejectCallRequest)
        case requestPermission(type: String, id: String, request: RequestPermissionRequest)
        case startRTMPBroadcasts(type: String, id: String, request: StartRTMPBroadcastsRequest)
        case stopAllRTMPBroadcasts(type: String, id: String)
        case stopRTMPBroadcast(type: String, id: String, name: String)
        case startHLSBroadcasting(type: String, id: String)
        case startClosedCaptions(type: String, id: String, request: StartClosedCaptionsRequest)
        case startRecording(type: String, id: String, request: StartRecordingRequest)
        case startTranscription(type: String, id: String, request: StartTranscriptionRequest)
        case stopHLSBroadcasting(type: String, id: String)
        case stopClosedCaptions(type: String, id: String, request: StopClosedCaptionsRequest)
        case stopLive(type: String, id: String, request: StopLiveRequest)
        case stopRecording(type: String, id: String)
        case stopTranscription(type: String, id: String, request: StopTranscriptionRequest)
        case listTranscriptions(type: String, id: String)
        case unblockUser(type: String, id: String, request: UnblockUserRequest)
        case videoUnpin(type: String, id: String, request: UnpinRequest)
        case updateUserPermissions(type: String, id: String, request: UpdateUserPermissionsRequest)
        case deleteRecording(type: String, id: String, session: String, filename: String)
        case deleteTranscription(type: String, id: String, session: String, filename: String)
        case queryCalls(request: QueryCallsRequest)
        case deleteDevice(id: String)
        case listDevices
        case createDevice(request: CreateDeviceRequest)
        case getEdges
        case createGuest(request: CreateGuestRequest)
        case videoConnect
        case ringCall(request: RingCallRequest)

        var payload: Any {
            switch self {
            case let .queryCallMembers(query):
                return query
            case let .queryCallStats(query):
                return query
            case let .getCall(type, id, membersLimit, ring, notify, video):
                return (type, id, membersLimit as Any, ring as Any, notify as Any, video as Any)
            case let .updateCall(type, id, request):
                return (type, id, request)
            case let .getOrCreateCall(type, id, request):
                return (type, id, request)
            case let .acceptCall(type, id):
                return (type, id)
            case let .blockUser(type, id, request):
                return (type, id, request)
            case let .deleteCall(type, id, request):
                return (type, id, request)
            case let .sendCallEvent(type, id, request):
                return (type, id, request)
            case let .collectUserFeedback(type, id, request):
                return (type, id, request)
            case let .goLive(type, id, request):
                return (type, id, request)
            case let .joinCall(type, id, request):
                return (type, id, request)
            case let .kickUser(type, id, request):
                return (type, id, request)
            case let .endCall(type, id):
                return (type, id)
            case let .updateCallMembers(type, id, request):
                return (type, id, request)
            case let .muteUsers(type, id, request):
                return (type, id, request)
            case let .queryCallParticipants(id, type, limit, request):
                return (id, type, limit as Any, request)
            case let .videoPin(type, id, request):
                return (type, id, request)
            case let .sendVideoReaction(type, id, request):
                return (type, id, request)
            case let .listRecordings(type, id):
                return (type, id)
            case let .rejectCall(type, id, request):
                return (type, id, request)
            case let .requestPermission(type, id, request):
                return (type, id, request)
            case let .startRTMPBroadcasts(type, id, request):
                return (type, id, request)
            case let .stopAllRTMPBroadcasts(type, id):
                return (type, id)
            case let .stopRTMPBroadcast(type, id, name):
                return (type, id, name)
            case let .startHLSBroadcasting(type, id):
                return (type, id)
            case let .startClosedCaptions(type, id, request):
                return (type, id, request)
            case let .startRecording(type, id, request):
                return (type, id, request)
            case let .startTranscription(type, id, request):
                return (type, id, request)
            case let .stopHLSBroadcasting(type, id):
                return (type, id)
            case let .stopClosedCaptions(type, id, request):
                return (type, id, request)
            case let .stopLive(type, id, request):
                return (type, id, request)
            case let .stopRecording(type, id):
                return (type, id)
            case let .stopTranscription(type, id, request):
                return (type, id, request)
            case let .listTranscriptions(type, id):
                return (type, id)
            case let .unblockUser(type, id, request):
                return (type, id, request)
            case let .videoUnpin(type, id, request):
                return (type, id, request)
            case let .updateUserPermissions(type, id, request):
                return (type, id, request)
            case let .deleteRecording(type, id, session, filename):
                return (type, id, session, filename)
            case let .deleteTranscription(type, id, session, filename):
                return (type, id, session, filename)
            case let .queryCalls(request):
                return request
            case let .deleteDevice(id):
                return id
            case .listDevices:
                return ()
            case let .createDevice(request):
                return request
            case .getEdges:
                return ()
            case let .createGuest(request):
                return request
            case .videoConnect:
                return ()
            case let .ringCall(request: request):
                return request
            }
        }
    }

    // MARK: - Helpers

    private func stubbedResult<T>(for key: FunctionKey) throws -> T {
        if let value = stubbedFunction[key] as? T {
            return value
        }
        if let error = stubbedFunction[key] as? Error {
            throw error
        }
        throw ClientError("Not stubbed function.")
    }

    // MARK: - DefaultAPIEndpoints

    func queryCallMembers(queryMembersRequest: QueryMembersRequest) async throws -> QueryMembersResponse {
        stubbedFunctionInput[.queryCallMembers]?.append(.queryCallMembers(query: queryMembersRequest))
        return try stubbedResult(for: .queryCallMembers)
    }

    func queryCallStats(queryCallStatsRequest: QueryCallStatsRequest) async throws -> QueryCallStatsResponse {
        stubbedFunctionInput[.queryCallStats]?.append(.queryCallStats(query: queryCallStatsRequest))
        return try stubbedResult(for: .queryCallStats)
    }

    func getCall(
        type: String,
        id: String,
        membersLimit: Int?,
        ring: Bool?,
        notify: Bool?,
        video: Bool?
    ) async throws -> GetCallResponse {
        stubbedFunctionInput[.getCall]?.append(
            .getCall(
                type: type,
                id: id,
                membersLimit: membersLimit,
                ring: ring,
                notify: notify,
                video: video
            )
        )
        return try stubbedResult(for: .getCall)
    }

    func updateCall(type: String, id: String, updateCallRequest: UpdateCallRequest) async throws -> UpdateCallResponse {
        stubbedFunctionInput[.updateCall]?.append(.updateCall(type: type, id: id, request: updateCallRequest))
        return try stubbedResult(for: .updateCall)
    }

    func getOrCreateCall(
        type: String,
        id: String,
        getOrCreateCallRequest: GetOrCreateCallRequest
    ) async throws -> GetOrCreateCallResponse {
        stubbedFunctionInput[.getOrCreateCall]?.append(
            .getOrCreateCall(type: type, id: id, request: getOrCreateCallRequest)
        )
        return try stubbedResult(for: .getOrCreateCall)
    }

    func acceptCall(type: String, id: String) async throws -> AcceptCallResponse {
        stubbedFunctionInput[.acceptCall]?.append(.acceptCall(type: type, id: id))
        return try stubbedResult(for: .acceptCall)
    }

    func blockUser(type: String, id: String, blockUserRequest: BlockUserRequest) async throws -> BlockUserResponse {
        stubbedFunctionInput[.blockUser]?.append(.blockUser(type: type, id: id, request: blockUserRequest))
        return try stubbedResult(for: .blockUser)
    }

    func deleteCall(type: String, id: String, deleteCallRequest: DeleteCallRequest) async throws -> DeleteCallResponse {
        stubbedFunctionInput[.deleteCall]?.append(.deleteCall(type: type, id: id, request: deleteCallRequest))
        return try stubbedResult(for: .deleteCall)
    }

    func sendCallEvent(type: String, id: String, sendEventRequest: SendEventRequest) async throws -> SendEventResponse {
        stubbedFunctionInput[.sendCallEvent]?.append(.sendCallEvent(type: type, id: id, request: sendEventRequest))
        return try stubbedResult(for: .sendCallEvent)
    }

    func collectUserFeedback(
        type: String,
        id: String,
        collectUserFeedbackRequest: CollectUserFeedbackRequest
    ) async throws -> CollectUserFeedbackResponse {
        stubbedFunctionInput[.collectUserFeedback]?.append(
            .collectUserFeedback(type: type, id: id, request: collectUserFeedbackRequest)
        )
        return try stubbedResult(for: .collectUserFeedback)
    }

    func goLive(type: String, id: String, goLiveRequest: GoLiveRequest) async throws -> GoLiveResponse {
        stubbedFunctionInput[.goLive]?.append(.goLive(type: type, id: id, request: goLiveRequest))
        return try stubbedResult(for: .goLive)
    }

    func joinCall(type: String, id: String, joinCallRequest: JoinCallRequest) async throws -> JoinCallResponse {
        stubbedFunctionInput[.joinCall]?.append(.joinCall(type: type, id: id, request: joinCallRequest))
        return try stubbedResult(for: .joinCall)
    }

    func kickUser(type: String, id: String, kickUserRequest: KickUserRequest) async throws -> KickUserResponse {
        stubbedFunctionInput[.kickUser]?.append(.kickUser(type: type, id: id, request: kickUserRequest))
        return try stubbedResult(for: .kickUser)
    }

    func endCall(type: String, id: String) async throws -> EndCallResponse {
        stubbedFunctionInput[.endCall]?.append(.endCall(type: type, id: id))
        return try stubbedResult(for: .endCall)
    }

    func updateCallMembers(
        type: String,
        id: String,
        updateCallMembersRequest: UpdateCallMembersRequest
    ) async throws -> UpdateCallMembersResponse {
        stubbedFunctionInput[.updateCallMembers]?.append(
            .updateCallMembers(type: type, id: id, request: updateCallMembersRequest)
        )
        return try stubbedResult(for: .updateCallMembers)
    }

    func muteUsers(type: String, id: String, muteUsersRequest: MuteUsersRequest) async throws -> MuteUsersResponse {
        stubbedFunctionInput[.muteUsers]?.append(.muteUsers(type: type, id: id, request: muteUsersRequest))
        return try stubbedResult(for: .muteUsers)
    }

    func queryCallParticipants(
        id: String,
        type: String,
        limit: Int?,
        queryCallParticipantsRequest: QueryCallParticipantsRequest
    ) async throws -> QueryCallParticipantsResponse {
        stubbedFunctionInput[.queryCallParticipants]?.append(
            .queryCallParticipants(id: id, type: type, limit: limit, request: queryCallParticipantsRequest)
        )
        return try stubbedResult(for: .queryCallParticipants)
    }

    func videoPin(type: String, id: String, pinRequest: PinRequest) async throws -> PinResponse {
        stubbedFunctionInput[.videoPin]?.append(.videoPin(type: type, id: id, request: pinRequest))
        return try stubbedResult(for: .videoPin)
    }

    func sendVideoReaction(
        type: String,
        id: String,
        sendReactionRequest: SendReactionRequest
    ) async throws -> SendReactionResponse {
        stubbedFunctionInput[.sendVideoReaction]?.append(.sendVideoReaction(type: type, id: id, request: sendReactionRequest))
        return try stubbedResult(for: .sendVideoReaction)
    }

    func listRecordings(type: String, id: String) async throws -> ListRecordingsResponse {
        stubbedFunctionInput[.listRecordings]?.append(.listRecordings(type: type, id: id))
        return try stubbedResult(for: .listRecordings)
    }

    func rejectCall(type: String, id: String, rejectCallRequest: RejectCallRequest) async throws -> RejectCallResponse {
        stubbedFunctionInput[.rejectCall]?.append(.rejectCall(type: type, id: id, request: rejectCallRequest))
        return try stubbedResult(for: .rejectCall)
    }

    func requestPermission(
        type: String,
        id: String,
        requestPermissionRequest: RequestPermissionRequest
    ) async throws -> RequestPermissionResponse {
        stubbedFunctionInput[.requestPermission]?.append(
            .requestPermission(type: type, id: id, request: requestPermissionRequest)
        )
        return try stubbedResult(for: .requestPermission)
    }

    func startRTMPBroadcasts(
        type: String,
        id: String,
        startRTMPBroadcastsRequest: StartRTMPBroadcastsRequest
    ) async throws -> StartRTMPBroadcastsResponse {
        stubbedFunctionInput[.startRTMPBroadcasts]?.append(
            .startRTMPBroadcasts(type: type, id: id, request: startRTMPBroadcastsRequest)
        )
        return try stubbedResult(for: .startRTMPBroadcasts)
    }

    func stopAllRTMPBroadcasts(type: String, id: String) async throws -> StopAllRTMPBroadcastsResponse {
        stubbedFunctionInput[.stopAllRTMPBroadcasts]?.append(.stopAllRTMPBroadcasts(type: type, id: id))
        return try stubbedResult(for: .stopAllRTMPBroadcasts)
    }

    func stopRTMPBroadcast(type: String, id: String, name: String) async throws -> StopRTMPBroadcastsResponse {
        stubbedFunctionInput[.stopRTMPBroadcast]?.append(.stopRTMPBroadcast(type: type, id: id, name: name))
        return try stubbedResult(for: .stopRTMPBroadcast)
    }

    func startHLSBroadcasting(type: String, id: String) async throws -> StartHLSBroadcastingResponse {
        stubbedFunctionInput[.startHLSBroadcasting]?.append(.startHLSBroadcasting(type: type, id: id))
        return try stubbedResult(for: .startHLSBroadcasting)
    }

    func startClosedCaptions(
        type: String,
        id: String,
        startClosedCaptionsRequest: StartClosedCaptionsRequest
    ) async throws -> StartClosedCaptionsResponse {
        stubbedFunctionInput[.startClosedCaptions]?.append(
            .startClosedCaptions(type: type, id: id, request: startClosedCaptionsRequest)
        )
        return try stubbedResult(for: .startClosedCaptions)
    }

    func startRecording(
        type: String,
        id: String,
        startRecordingRequest: StartRecordingRequest
    ) async throws -> StartRecordingResponse {
        stubbedFunctionInput[.startRecording]?.append(
            .startRecording(type: type, id: id, request: startRecordingRequest)
        )
        return try stubbedResult(for: .startRecording)
    }

    func startTranscription(
        type: String,
        id: String,
        startTranscriptionRequest: StartTranscriptionRequest
    ) async throws -> StartTranscriptionResponse {
        stubbedFunctionInput[.startTranscription]?.append(
            .startTranscription(type: type, id: id, request: startTranscriptionRequest)
        )
        return try stubbedResult(for: .startTranscription)
    }

    func stopHLSBroadcasting(type: String, id: String) async throws -> StopHLSBroadcastingResponse {
        stubbedFunctionInput[.stopHLSBroadcasting]?.append(.stopHLSBroadcasting(type: type, id: id))
        return try stubbedResult(for: .stopHLSBroadcasting)
    }

    func stopClosedCaptions(
        type: String,
        id: String,
        stopClosedCaptionsRequest: StopClosedCaptionsRequest
    ) async throws -> StopClosedCaptionsResponse {
        stubbedFunctionInput[.stopClosedCaptions]?.append(
            .stopClosedCaptions(type: type, id: id, request: stopClosedCaptionsRequest)
        )
        return try stubbedResult(for: .stopClosedCaptions)
    }

    func stopLive(type: String, id: String, stopLiveRequest: StopLiveRequest) async throws -> StopLiveResponse {
        stubbedFunctionInput[.stopLive]?.append(.stopLive(type: type, id: id, request: stopLiveRequest))
        return try stubbedResult(for: .stopLive)
    }

    func stopRecording(type: String, id: String) async throws -> StopRecordingResponse {
        stubbedFunctionInput[.stopRecording]?.append(.stopRecording(type: type, id: id))
        return try stubbedResult(for: .stopRecording)
    }

    func stopTranscription(
        type: String,
        id: String,
        stopTranscriptionRequest: StopTranscriptionRequest
    ) async throws -> StopTranscriptionResponse {
        stubbedFunctionInput[.stopTranscription]?.append(
            .stopTranscription(type: type, id: id, request: stopTranscriptionRequest)
        )
        return try stubbedResult(for: .stopTranscription)
    }

    func listTranscriptions(type: String, id: String) async throws -> ListTranscriptionsResponse {
        stubbedFunctionInput[.listTranscriptions]?.append(.listTranscriptions(type: type, id: id))
        return try stubbedResult(for: .listTranscriptions)
    }

    func unblockUser(type: String, id: String, unblockUserRequest: UnblockUserRequest) async throws -> UnblockUserResponse {
        stubbedFunctionInput[.unblockUser]?.append(.unblockUser(type: type, id: id, request: unblockUserRequest))
        return try stubbedResult(for: .unblockUser)
    }

    func videoUnpin(type: String, id: String, unpinRequest: UnpinRequest) async throws -> UnpinResponse {
        stubbedFunctionInput[.videoUnpin]?.append(.videoUnpin(type: type, id: id, request: unpinRequest))
        return try stubbedResult(for: .videoUnpin)
    }

    func updateUserPermissions(
        type: String,
        id: String,
        updateUserPermissionsRequest: UpdateUserPermissionsRequest
    ) async throws -> UpdateUserPermissionsResponse {
        stubbedFunctionInput[.updateUserPermissions]?.append(
            .updateUserPermissions(type: type, id: id, request: updateUserPermissionsRequest)
        )
        return try stubbedResult(for: .updateUserPermissions)
    }

    func deleteRecording(type: String, id: String, session: String, filename: String) async throws -> DeleteRecordingResponse {
        stubbedFunctionInput[.deleteRecording]?.append(
            .deleteRecording(type: type, id: id, session: session, filename: filename)
        )
        return try stubbedResult(for: .deleteRecording)
    }

    func deleteTranscription(
        type: String,
        id: String,
        session: String,
        filename: String
    ) async throws -> DeleteTranscriptionResponse {
        stubbedFunctionInput[.deleteTranscription]?.append(
            .deleteTranscription(type: type, id: id, session: session, filename: filename)
        )
        return try stubbedResult(for: .deleteTranscription)
    }

    func queryCalls(queryCallsRequest: QueryCallsRequest) async throws -> QueryCallsResponse {
        stubbedFunctionInput[.queryCalls]?.append(.queryCalls(request: queryCallsRequest))
        return try stubbedResult(for: .queryCalls)
    }

    func deleteDevice(id: String) async throws -> ModelResponse {
        stubbedFunctionInput[.deleteDevice]?.append(.deleteDevice(id: id))
        return try stubbedResult(for: .deleteDevice)
    }

    func listDevices() async throws -> ListDevicesResponse {
        stubbedFunctionInput[.listDevices]?.append(.listDevices)
        return try stubbedResult(for: .listDevices)
    }

    func createDevice(createDeviceRequest: CreateDeviceRequest) async throws -> ModelResponse {
        stubbedFunctionInput[.createDevice]?.append(.createDevice(request: createDeviceRequest))
        return try stubbedResult(for: .createDevice)
    }

    func getEdges() async throws -> GetEdgesResponse {
        stubbedFunctionInput[.getEdges]?.append(.getEdges)
        return try stubbedResult(for: .getEdges)
    }

    func createGuest(createGuestRequest: CreateGuestRequest) async throws -> CreateGuestResponse {
        stubbedFunctionInput[.createGuest]?.append(.createGuest(request: createGuestRequest))
        return try stubbedResult(for: .createGuest)
    }

    func videoConnect() async throws {
        stubbedFunctionInput[.videoConnect]?.append(.videoConnect)
        if let error = stubbedFunction[.videoConnect] as? Error { throw error }
        guard stubbedFunction[.videoConnect] != nil else { throw ClientError("Not stubbed function.") }
        return ()
    }
    
    func ringCall(type: String, id: String, ringCallRequest: RingCallRequest) async throws -> RingCallResponse {
        stubbedFunctionInput[.ringCall]?.append(.ringCall(request: ringCallRequest))
        return try stubbedResult(for: .ringCall)
    }
}
