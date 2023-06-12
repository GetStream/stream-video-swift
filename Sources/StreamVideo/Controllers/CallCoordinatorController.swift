//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

/// Handles communication with the Coordinator API for determining the best SFU for a call.
class CallCoordinatorController: @unchecked Sendable {
    
    let coordinatorClient: CoordinatorClient
    var currentCallSettings: CallSettingsInfo?
    private let videoConfig: VideoConfig
    private var user: User
    
    init(
        httpClient: HTTPClient,
        user: User,
        coordinatorInfo: CoordinatorInfo,
        videoConfig: VideoConfig
    ) {
        coordinatorClient = CoordinatorClient(
            httpClient: httpClient,
            apiKey: coordinatorInfo.apiKey,
            hostname: coordinatorInfo.hostname,
            token: coordinatorInfo.token,
            userId: user.id
        )
        self.videoConfig = videoConfig
        self.user = user
    }
    
    func joinCall(
        callType: String,
        callId: String,
        videoOptions: VideoOptions,
        members: [User],
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

    func update(token: UserToken) {
        coordinatorClient.update(userToken: token)
    }
    
    func update(connectionId: String) {
        coordinatorClient.connectionId = connectionId
    }
    
    func update(user: User) {
        self.user = user
        coordinatorClient.userId = user.id
    }

    func sendEvent(
        callId: String,
        callType: String,
        customData: [String: AnyCodable]? = nil
    ) async throws {
        let sendEventRequest = SendEventRequest(
            custom: customData
        )
        let request = EventRequestData(
            id: callId,
            type: callType,
            sendEventRequest: sendEventRequest
        )
        _ = try await coordinatorClient.sendEvent(with: request)
    }
    
    func acceptCall(callId: String, type: String) async throws -> AcceptCallResponse {
        try await coordinatorClient.acceptCall(callId: callId, type: type)
    }
    
    func rejectCall(callId: String, type: String) async throws -> RejectCallResponse {
        try await coordinatorClient.rejectCall(callId: callId, type: type)
    }
    
    func createGuestUser(with id: String) async throws -> CreateGuestResponse {
        let request = CreateGuestRequest(user: .init(id: id, name: id))
        return try await coordinatorClient.createGuestUser(request: request)
    }
    
    func updateCallMembers(
        callId: String,
        callType: String,
        updateMembers: [MemberRequest],
        removedIds: [String]
    ) async throws -> [User] {
        let request = UpdateCallMembersRequest(
            removeMembers: removedIds,
            updateMembers: updateMembers
        )
        let response = try await coordinatorClient.updateCallMembers(
            request: request,
            callId: callId,
            callType: callType
        )
        return response.members.map { member in
            User(
                id: member.userId,
                name: member.user.name,
                imageURL: URL(string: member.user.image ?? ""),
                role: member.user.role
            )
        }
    }

    // MARK: - private

    private func getLocation() async throws -> String {
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
        participants: [User],
        ring: Bool,
        notify: Bool
    ) async throws -> JoinCallResponse {
        var members = [MemberRequest]()
        for participant in participants {
            let callMemberRequest = MemberRequest(
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
        // TODO: this needs to be moved to the method signature
        let create = true
        let joinCall = JoinCallRequest(
            create: create,
            data: callRequest,
            location: location,
            notify: notify,
            ring: ring
        )
        let joinCallRequest = JoinCallRequestData(
            id: callId,
            type: type,
            joinCallRequest: joinCall
        )
        let joinCallResponse = try await coordinatorClient.joinCall(with: joinCallRequest)
        return joinCallResponse
    }
}

public struct EdgeServer: Sendable {
    let url: String
    let webSocketURL: String
    let token: String
    let iceServers: [IceServer]
    let callSettings: CallSettingsInfo
    public let latencyURL: String?
}

struct CallSettingsInfo: Sendable {
    let callCapabilities: [String]
    let callSettings: CallSettingsResponse
    let state: CallData
    let recording: Bool
}

extension CallSettingsResponse: @unchecked Sendable {}

public struct IceServer: Sendable {
    let urls: [String]
    let username: String
    let password: String
}

struct CoordinatorInfo {
    let apiKey: String
    let hostname: String
    let token: String
}

public struct FetchingLocationError: Error {}
