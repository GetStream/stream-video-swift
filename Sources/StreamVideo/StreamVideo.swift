//
//  StreamVideo.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 7.7.22.
//

import Foundation

public class StreamVideo {
    
    // Temporarly storing user in memory.
    private var userInfo: UserInfo?
    private var token: Token? {
        didSet {
            if let token = token {
                callCoordinatorService.update(userToken: token.rawValue)
            }
        }
    }
    // Change it to your local IP address.
    private let hostname = "http://192.168.0.132:26991"
    
    var callCoordinatorService: Stream_Video_CallCoordinatorService
    
    let apiKey: String
    let videoService = VideoService()
    let latencyService = LatencyService()
    
    public init(apiKey: String) {
        self.apiKey = apiKey
        self.callCoordinatorService = Stream_Video_CallCoordinatorService(
            hostname: hostname,
            token: ""
        )
        StreamVideoProviderKey.currentValue = self
    }
    
    public func connectUser(
        userInfo: UserInfo,
        token: Token
    ) async throws {
        self.userInfo = userInfo
        self.token = token
    }
    
    public func joinCall(
        callType: CallType,
        callId: String,
        videoOptions: VideoOptions
    ) async throws -> VideoRoom {
        let createCallResponse = try await createCall()
        
        let edges = try await joinCall(
            callId: createCallResponse.call.id,
            type: createCallResponse.call.type
        )
        
        let latencyByEdge = try await measureLatencies(for: edges)
        
        let edgeServer = try await selectEdgeServer(
            callId: createCallResponse.call.id,
            latencyByEdge: latencyByEdge
        )
        
        return try await videoService.connect(
            url: edgeServer.url,
            token: edgeServer.token,
            options: videoOptions
        )
    }
    
    private func createCall() async throws -> Stream_Video_CreateCallResponse {
        let createCallRequest = Stream_Video_CreateCallRequest()
        let createCallResponse = try await callCoordinatorService.createCall(createCallRequest: createCallRequest)
        return createCallResponse
    }
    
    private func measureLatencies(
        for edges: [Stream_Video_Edge]
    ) async throws -> [String: Stream_Video_Latency] {
        var result: [String: Stream_Video_Latency] = [:]
        for edge in edges {
            var latency = Stream_Video_Latency()
            let value = await latencyService.measureLatency(for: edge)
            latency.measurements = value
            result[edge.name] = latency
        }
        return result
    }
    
    private func joinCall(callId: String, type: String) async throws -> [Stream_Video_Edge] {
        var joinCallRequest = Stream_Video_JoinCallRequest()
        joinCallRequest.id = callId
        joinCallRequest.type = type
        let joinCallResponse = try await callCoordinatorService.joinCall(joinCallRequest: joinCallRequest)
        let edges = joinCallResponse.edges
        return edges
    }
    
    private func selectEdgeServer(
        callId: String,
        latencyByEdge: [String: Stream_Video_Latency]
    ) async throws -> (url: String, token: String) {
        var selectEdgeRequest = Stream_Video_SelectEdgeServerRequest()
        selectEdgeRequest.callID = callId
        selectEdgeRequest.latencyByEdge = latencyByEdge
        let response = try await callCoordinatorService.selectEdgeServer(selectEdgeServerRequest: selectEdgeRequest)
        let url = "wss://\(response.edgeServer.url)"
        let token = response.token
        return (url: url, token: token)
    }
    
}

/// Returns the current value for the `StreamVideo` instance.
internal struct StreamVideoProviderKey: InjectionKey {
    static var currentValue: StreamVideo?
}
