//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

/// Handles communication with the Coordinator API for determining the best SFU for a call.
final class CallCoordinatorController: Sendable {
    
    let callCoordinatorService: Stream_Video_CallCoordinatorService
    let coordinatorClient: CoordinatorClient
    private let latencyService: LatencyService
    private let videoConfig: VideoConfig
    private let user: User
    
    init(
        httpClient: HTTPClient,
        user: User,
        coordinatorInfo: CoordinatorInfo,
        videoConfig: VideoConfig
    ) {
        latencyService = LatencyService(httpClient: httpClient)
        callCoordinatorService = Stream_Video_CallCoordinatorService(
            httpClient: httpClient,
            apiKey: coordinatorInfo.apiKey,
            hostname: coordinatorInfo.hostname,
            token: coordinatorInfo.token
        )
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
        callType: CallType,
        callId: String,
        videoOptions: VideoOptions,
        participantIds: [String]
    ) async throws -> EdgeServer {
        let joinCallResponse = try await joinCall(
            callId: callId,
            type: callType.name,
            participantIds: participantIds
        )
        
        let latencyByEdge = await measureLatencies(for: joinCallResponse.edges ?? [])
        
        let edgeServer = try await selectEdgeServer(
            callId: joinCallResponse.call.id!,
            type: callType.name,
            latencyByEdge: latencyByEdge,
            edges: joinCallResponse.edges ?? []
        )
        
        return edgeServer
    }

    func update(token: UserToken) {
        coordinatorClient.update(userToken: token.rawValue)
    }
    
    func update(connectionId: String) {
        coordinatorClient.connectionId = connectionId
    }
    
    func makeVoipNotificationsController() -> VoipNotificationsController {
        VoipNotificationsController(callCoordinatorService: callCoordinatorService)
    }
    
    func sendEvent(
        type: Stream_Video_UserEventType,
        callId: String,
        callType: CallType
    ) async throws {
        var request = Stream_Video_SendEventRequest()
        request.callCid = "\(callType.name):\(callId)"
        request.eventType = type
        _ = try await callCoordinatorService.sendEvent(sendEventRequest: request)
    }
    
    func sendEvent(
        type: EventType,
        callId: String,
        callType: CallType
    ) async throws {
        let sendEventRequest = SendEventRequest(eventType: type.rawValue)
        let request = EventRequest(
            id: callId,
            type: callType.name,
            sendEventRequest: sendEventRequest
        )
        _ = try await coordinatorClient.sendEvent(with: request)
    }
    
    func addMembersToCall(with cid: String, memberIds: [String]) async throws {
        var request = Stream_Video_UpsertCallMembersRequest()
        request.callCid = cid
        request.members = memberIds.map { id in
            var memberInput = Stream_Video_MemberInput()
            memberInput.userID = id
            memberInput.role = "member"
            return memberInput
        }
        request.ring = !videoConfig.joinVideoCallInstantly
        _ = try await callCoordinatorService.upsertCallMembers(upsertCallMembersRequest: request)
    }
    
    func enrichUserData(for id: String) async throws -> EnrichedUserData {
        var request = Stream_Video_Coordinator_ClientV1Rpc_QueryUsersRequest()
        let filter = ["id": ["$in": [id]]]
        let jsonData = try JSONSerialization.data(withJSONObject: filter, options: .prettyPrinted)
        request.mqJson = jsonData
        let response = try await callCoordinatorService.queryUsers(queryUsersRequest: request)
        guard let member = response.users.first else { return .empty }
        return EnrichedUserData(imageUrl: URL(string: member.imageURL), name: member.name, role: member.role)
    }

    // MARK: - private
        
    private func measureLatencies(
        for endpoints: [DatacenterResponse]
    ) async -> [String: [Float]] {
        await withTaskGroup(of: [String: [Float]].self) { group in
            var result: [String: [Float]] = [:]
            for endpoint in endpoints {
                group.addTask {
                    let value = await self.latencyService.measureLatency(for: endpoint, tries: 3)
                    return [endpoint.name!: value]
                }
            }
            
            for await latency in group {
                for (key, value) in latency {
                    result[key] = value
                }
            }
            
            log.debug("Reported latencies for edges: \(result)")
            
            return result
        }
    }
    
    private func joinCall(
        callId: String,
        type: String,
        participantIds: [String]
    ) async throws -> Stream_Video_JoinCallResponse {
        let ring = !videoConfig.joinVideoCallInstantly
        let role = "member" // TODO:
        
        var members = [MemberRequest]()
        for participantId in participantIds {
            let callMemberRequest = MemberRequest(
                role: role,
                userId: participantId
            )
            members.append(callMemberRequest)
        }
        
        let userRequest = UserRequest(
            id: user.id,
            image: user.imageURL?.absoluteString,
            name: user.name,
            role: role,
            teams: nil // TODO:
        )
        let callRequest = CallRequest(
            createdBy: userRequest,
            createdById: user.id,
            members: members,
            settingsOverride: nil,
            team: nil // TODO:
        )
        let paginationParamsRequest = PaginationParamsRequest()
        let getOrCreateCallRequest = GetOrCreateCallRequest(
            data: callRequest,
            members: paginationParamsRequest,
            ring: ring
        )
        let joinCallRequest = JoinCallRequest(id: callId, type: type, getOrCreateCallRequest: getOrCreateCallRequest)
        let joinCallResponse = try await coordinatorClient.joinCall(with: joinCallRequest)
        return joinCallResponse
    }
    
    private func selectEdgeServer(
        callId: String,
        type: String,
        latencyByEdge: [String: [Float]],
        edges: [DatacenterResponse]
    ) async throws -> EdgeServer {
        let getCallEdgeServerRequest = GetCallEdgeServerRequest(
            latencyMeasurements: latencyByEdge
        )
        let selectEdgeRequest = SelectEdgeServerRequest(
            id: callId,
            type: type,
            getCallEdgeServerRequest: getCallEdgeServerRequest
        )
        let response = try await coordinatorClient.getCallEdgeServer(with: selectEdgeRequest)
        let credentials = response.credentials
        let iceServersResponse: [ICEServer] = credentials.iceServers ?? []
        let iceServers = iceServersResponse.map { iceServer in
            IceServer(
                urls: iceServer.urls ?? [],
                username: iceServer.username ?? "",
                password: iceServer.password ?? ""
            )
        }
        let edgeName = response.credentials.server?.edgeName
        let edge = edges.first { $0.name == edgeName }
        var latencyURL: String? = edge.map(\.latencyUrl) ?? nil
        if latencyURL == nil {
            for edge in edges {
                let maxLatency = Float(Int.max)
                if let name = edge.name {
                    let latency = latencyByEdge[name]?.last ?? maxLatency
                    if latency != maxLatency {
                        latencyURL = edge.latencyUrl
                    }
                }
            }
        }
        guard let url = credentials.server?.url, let token = credentials.token else {
            throw ClientError.Unexpected()
        }
        return EdgeServer(
            url: url,
            token: token,
            iceServers: iceServers,
            latencyURL: latencyURL
        )
    }
}

public struct EdgeServer: Sendable {
    let url: String
    let token: String
    let iceServers: [IceServer]
    public let latencyURL: String?
}

public struct IceServer: Sendable {
    let urls: [String]
    let username: String
    let password: String
}

extension Stream_Video_ICEServer {
    func toIceServer() -> IceServer {
        IceServer(
            urls: urls,
            username: username,
            password: password
        )
    }
}

struct CoordinatorInfo {
    let apiKey: String
    let hostname: String
    let token: String
}

struct EnrichedUserData {
    let imageUrl: URL?
    let name: String
    let role: String
}

extension EnrichedUserData {
    static let empty = EnrichedUserData(
        imageUrl: nil,
        name: "",
        role: "member"
    )
}
