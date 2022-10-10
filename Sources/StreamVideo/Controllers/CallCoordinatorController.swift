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

    func update(token: Token) {
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
        request.callType = callType.name
        request.callID = callId
        request.eventType = type
        _ = try await callCoordinatorService.sendEvent(sendEventRequest: request)
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
            var members = [String: Stream_Video_MemberInput]()
            for participantId in participantIds {
                members[participantId] = Stream_Video_MemberInput()
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
