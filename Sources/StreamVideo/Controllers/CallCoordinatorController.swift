//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

/// Handles communication with the Coordinator API for determining the best SFU for a call.
final class CallCoordinatorController: Sendable {
    
    private let latencyService: LatencyService
    private let callCoordinatorService: Stream_Video_CallCoordinatorService
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
        
        let latencyByEdge = await measureLatencies(for: joinCallResponse.edges)
        
        let edgeServer = try await selectEdgeServer(
            callId: joinCallResponse.call.call.callCid,
            latencyByEdge: latencyByEdge
        )
        
        return edgeServer
    }

    func update(token: UserToken) {
        callCoordinatorService.update(userToken: token.rawValue)
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
        for endpoints: [Stream_Video_Edge]
    ) async -> [String: Stream_Video_Latency] {
        await withTaskGroup(of: [String: Stream_Video_Latency].self) { group in
            var result: [String: Stream_Video_Latency] = [:]
            for endpoint in endpoints {
                group.addTask {
                    var latency = Stream_Video_Latency()
                    let value = await self.latencyService.measureLatency(for: endpoint, tries: 3)
                    latency.measurementsSeconds = value
                    return [endpoint.name: latency]
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
        var joinCallRequest = Stream_Video_JoinCallRequest()
        joinCallRequest.id = callId
        joinCallRequest.type = type
        if !participantIds.isEmpty {
            var input = Stream_Video_CreateCallInput()
            input.ring = !videoConfig.joinVideoCallInstantly
            var members = [Stream_Video_MemberInput]()
            for participantId in participantIds {
                var memberInput = Stream_Video_MemberInput()
                memberInput.userID = participantId
                memberInput.role = "member"
                members.append(memberInput)
            }
            input.members = members
            joinCallRequest.input = input
        }
        let joinCallResponse = try await callCoordinatorService.joinCall(joinCallRequest: joinCallRequest)
        return joinCallResponse
    }
    
    private func selectEdgeServer(
        callId: String,
        latencyByEdge: [String: Stream_Video_Latency]
    ) async throws -> EdgeServer {
        var selectEdgeRequest = Stream_Video_SelectEdgeServerRequest()
        selectEdgeRequest.callCid = callId
        var measurements = Stream_Video_LatencyMeasurements()
        measurements.measurements = latencyByEdge
        selectEdgeRequest.measurements = measurements
        let response = try await callCoordinatorService.getCallEdgeServer(getCallEdgeServerRequest: selectEdgeRequest)
        let url = response.credentials.server.url
        let token = response.credentials.token
        log.debug("Selected edge server \(url)")
        return EdgeServer(
            url: url,
            token: token,
            iceServers: response.credentials.iceServers
        )
    }
}

struct EdgeServer {
    let url: String
    let token: String
    let iceServers: [Stream_Video_ICEServer]
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
