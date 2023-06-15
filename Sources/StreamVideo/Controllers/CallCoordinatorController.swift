//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

/// Handles communication with the Coordinator API for determining the best SFU for a call.
class CallCoordinatorController: @unchecked Sendable {
    
    var currentCallSettings: CallSettingsInfo?
    private let videoConfig: VideoConfig
    private var user: User
    private var cachedLocation: String?
    private let defaultAPI: DefaultAPI
    
    init(
        defaultAPI: DefaultAPI,
        user: User,
        coordinatorInfo: CoordinatorInfo,
        videoConfig: VideoConfig
    ) {
        self.defaultAPI = defaultAPI
        self.videoConfig = videoConfig
        self.user = user
        self.prefetchLocation()
    }
    
    func joinCall(
        callType: String,
        callId: String,
        videoOptions: VideoOptions,
        members: [Member],
        ring: Bool,
        notify: Bool
    ) async throws -> EdgeServer {
        let location = try await getLocation()
        let response = try await joinCall(
            callId: callId,
            type: callType,
            location: location,
            participants: members,
            ring: ring,
            notify: notify
        )
        let iceServersResponse: [ICEServer] = response.credentials.iceServers
        let iceServers = iceServersResponse.map { iceServer in
            IceServer(
                urls: iceServer.urls,
                username: iceServer.username,
                password: iceServer.password
            )
        }
        let callSettings = CallSettingsInfo(
            callCapabilities: response.ownCapabilities.map(\.rawValue),
            callSettings: response.call.settings,
            state: response.call.toCallData(
                members: response.members,
                blockedUsers: response.blockedUsers
            ),
            recording: response.call.recording
        )
        let edgeServer = EdgeServer(
            url: response.credentials.server.url,
            webSocketURL: response.credentials.server.wsEndpoint,
            token: response.credentials.token,
            iceServers: iceServers,
            callSettings: callSettings,
            latencyURL: nil
        )
        currentCallSettings = edgeServer.callSettings
        return edgeServer
    }
    
    func acceptCall(callId: String, type: String) async throws -> AcceptCallResponse {
        try await defaultAPI.acceptCall(type: type, id: callId)
    }
    
    func rejectCall(callId: String, type: String) async throws -> RejectCallResponse {
        try await defaultAPI.rejectCall(type: type, id: callId)
    }
    
    func createGuestUser(with id: String) async throws -> CreateGuestResponse {
        let request = CreateGuestRequest(user: .init(id: id, name: id))
        return try await defaultAPI.createGuest(createGuestRequest: request)
    }
    
    func updateCallMembers(
        callId: String,
        callType: String,
        updateMembers: [MemberRequest],
        removedIds: [String]
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
                customData: member.custom
            )
        }
    }

    // MARK: - private
    
    private func prefetchLocation() {
        Task {
            self.cachedLocation = try await getLocation()
        }
    }

    private func getLocation() async throws -> String {
        if let cachedLocation {
            return cachedLocation
        }
        guard let url = URL(string: "https://hint.stream-io-video.com/") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let (_, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse {
            let headerKey = "X-Amz-Cf-Pop"
            if let prefix = response.value(forHTTPHeaderField: headerKey)?.prefix(3) {
                return String(prefix)
            }
        }
        throw FetchingLocationError()
    }

    private func joinCall(
        callId: String,
        type: String,
        location: String,
        participants: [Member],
        ring: Bool,
        notify: Bool
    ) async throws -> JoinCallResponse {
        var members = [MemberRequest]()
        for participant in participants {
            let callMemberRequest = MemberRequest(
                custom: participant.customData,
                role: participant.role,
                userId: participant.id
            )
            members.append(callMemberRequest)
        }
        
        let currentUserRole = participants.filter { user.id == $0.id }.first?.role ?? user.role
        let userRequest = UserRequest(
            id: user.id,
            image: user.imageURL?.absoluteString,
            name: user.name,
            role: currentUserRole
        )
        let callRequest = CallRequest(
            createdBy: userRequest,
            createdById: user.id,
            members: members,
            settingsOverride: nil
        )
        //TODO: make it parameter
        let create = user.type != .anonymous
        let joinCall = JoinCallRequest(
            create: create,
            data: callRequest,
            location: location,
            notify: notify,
            ring: ring
        )
        let joinCallResponse = try await defaultAPI.joinCall(
            type: type,
            id: callId,
            joinCallRequest: joinCall
        )
        return joinCallResponse
    }
}
