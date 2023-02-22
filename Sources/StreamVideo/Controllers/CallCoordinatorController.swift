//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

/// Handles communication with the Coordinator API for determining the best SFU for a call.
final class CallCoordinatorController: @unchecked Sendable {
    
    let coordinatorClient: CoordinatorClient
    private(set) var currentCallSettings: CallSettingsInfo?
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
        participants: [User],
        ring: Bool
    ) async throws -> EdgeServer {
        let joinCallResponse = try await joinCall(
            callId: callId,
            type: callType.name,
            participants: participants,
            ring: ring
        )
        
        let latencyByEdge = await measureLatencies(for: joinCallResponse.edges)
        
        let edgeServer = try await selectEdgeServer(
            callId: joinCallResponse.call.id,
            type: callType.name,
            latencyByEdge: latencyByEdge,
            edges: joinCallResponse.edges
        )
        
        currentCallSettings = edgeServer.callSettings
        
        return edgeServer
    }

    func update(token: UserToken) {
        coordinatorClient.update(userToken: token.rawValue)
    }
    
    func update(connectionId: String) {
        coordinatorClient.connectionId = connectionId
    }
    
    func makeVoipNotificationsController() -> VoipNotificationsController {
        VoipNotificationsController(coordinatorClient: coordinatorClient)
    }
    
    func sendEvent(
        type: EventType,
        callId: String,
        callType: CallType,
        customData: [String: AnyCodable]? = nil
    ) async throws {
        let sendEventRequest = SendEventRequest(
            custom: customData,
            type: type.rawValue
        )
        let request = EventRequestData(
            id: callId,
            type: callType.name,
            sendEventRequest: sendEventRequest
        )
        _ = try await coordinatorClient.sendEvent(with: request)
    }
    
    func addMembersToCall(with cid: String, memberIds: [String]) async throws {
        throw ClientError.Unexpected("Not implemented")
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
                    return [endpoint.name: value]
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
        participants: [User],
        ring: Bool
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
            role: currentUserRole,
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
        let joinCallRequest = JoinCallRequestData(
            id: callId,
            type: type,
            getOrCreateCallRequest: getOrCreateCallRequest
        )
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
        let selectEdgeRequest = SelectEdgeServerRequestData(
            id: callId,
            type: type,
            getCallEdgeServerRequest: getCallEdgeServerRequest
        )
        let response = try await coordinatorClient.getCallEdgeServer(with: selectEdgeRequest)
        let credentials = response.credentials
        let iceServersResponse: [ICEServer] = credentials.iceServers
        let iceServers = iceServersResponse.map { iceServer in
            IceServer(
                urls: iceServer.urls,
                username: iceServer.username,
                password: iceServer.password
            )
        }
        let edgeName = response.credentials.server.edgeName
        let edge = edges.first { $0.name == edgeName }
        var latencyURL: String? = edge.map(\.latencyUrl) ?? nil
        if latencyURL == nil {
            for edge in edges {
                let maxLatency = Float(Int.max)
                let name = edge.name
                let latency = latencyByEdge[name]?.last ?? maxLatency
                if latency != maxLatency {
                    latencyURL = edge.latencyUrl
                }
            }
        }
        let callSettings = CallSettingsInfo(
            callCapabilities: response.call.ownCapabilities,
            callSettings: response.call.settings
        )
        return EdgeServer(
            url: credentials.server.url,
            token: credentials.token,
            iceServers: iceServers,
            callSettings: callSettings,
            latencyURL: latencyURL
        )
    }
}

public struct EdgeServer: Sendable {
    let url: String
    let token: String
    let iceServers: [IceServer]
    let callSettings: CallSettingsInfo
    public let latencyURL: String?
}

struct CallSettingsInfo: Sendable {
    let callCapabilities: [String]
    let callSettings: CallSettingsResponse
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
