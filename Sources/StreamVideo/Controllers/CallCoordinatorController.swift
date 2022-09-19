//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

final class CallCoordinatorController: Sendable {
    
    private let latencyService: LatencyService
    private let callCoordinatorService: Stream_Video_CallCoordinatorService
    private let videoConfig: VideoConfig
    private let userInfo: UserInfo
    
    init(
        httpClient: HTTPClient,
        userInfo: UserInfo,
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
        self.userInfo = userInfo
    }
    
    func startCall(
        callType: CallType,
        callId: String,
        videoOptions: VideoOptions,
        participantIds: [String]
    ) async throws -> EdgeServer {
        let createCallResponse = try await createCall(
            callType: callType.name,
            callId: callId,
            participantIds: participantIds
        )
        
        return try await joinCall(
            callType: callType,
            callId: createCallResponse.call.id,
            videoOptions: videoOptions
        )
    }
    
    func joinCall(
        callType: CallType,
        callId: String,
        videoOptions: VideoOptions
    ) async throws -> EdgeServer {
        let joinCallResponse = try await joinCall(
            callId: callId,
            type: callType.name
        )
        
        let latencyByEdge = await measureLatencies(for: joinCallResponse.edges)
        
        let edgeServer = try await selectEdgeServer(
            callId: callId,
            latencyByEdge: latencyByEdge
        )
        
        return edgeServer
    }
    
    func loadParticipants(for call: IncomingCall) async throws -> [CallParticipant] {
        var getCallRequest = Stream_Video_GetCallRequest()
        getCallRequest.id = call.id
        getCallRequest.type = call.type
        let callResponse = try await callCoordinatorService.getCall(getCallRequest: getCallRequest)
        let participants = callResponse.callState.participants
            .map { $0.toCallParticipant() }
            .filter { $0.id != userInfo.id }
        return participants
    }
    
    func update(token: Token) {
        callCoordinatorService.update(userToken: token.rawValue)
    }

    // MARK: - private
    
    private func createCall(
        callType: String,
        callId: String,
        participantIds: [String]
    ) async throws -> Stream_Video_CreateCallResponse {
        var createCallRequest = Stream_Video_CreateCallRequest()
        createCallRequest.id = callId
        createCallRequest.type = callType
        createCallRequest.participantIds = participantIds
        let createCallResponse = try await callCoordinatorService.createCall(createCallRequest: createCallRequest)
        return createCallResponse
    }
    
    private func measureLatencies(
        for edges: [Stream_Video_Edge]
    ) async -> [String: Stream_Video_Latency] {
        await withTaskGroup(of: [String: Stream_Video_Latency].self) { group in
            var result: [String: Stream_Video_Latency] = [:]
            for edge in edges {
                group.addTask {
                    var latency = Stream_Video_Latency()
                    let value = await self.latencyService.measureLatency(for: edge, tries: 3)
                    latency.measurementsSeconds = value
                    return [edge.latencyURL: latency]
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
    
    private func joinCall(callId: String, type: String) async throws -> Stream_Video_JoinCallResponse {
        var joinCallRequest = Stream_Video_JoinCallRequest()
        joinCallRequest.id = callId
        joinCallRequest.type = type
        let joinCallResponse = try await callCoordinatorService.joinCall(joinCallRequest: joinCallRequest)
        return joinCallResponse
    }
    
    private func selectEdgeServer(
        callId: String,
        latencyByEdge: [String: Stream_Video_Latency]
    ) async throws -> EdgeServer {
        var selectEdgeRequest = Stream_Video_SelectEdgeServerRequest()
        selectEdgeRequest.callID = callId
        selectEdgeRequest.latencyByEdge = latencyByEdge
        let response = try await callCoordinatorService.selectEdgeServer(selectEdgeServerRequest: selectEdgeRequest)
        let url = "wss://\(response.edgeServer.url)"
        let token = response.token
        log.debug("Selected edge server \(url)")
        return EdgeServer(url: url, token: token)
    }
}

struct EdgeServer {
    let url: String
    let token: String
}

struct CoordinatorInfo {
    let apiKey: String
    let hostname: String
    let token: String
}
