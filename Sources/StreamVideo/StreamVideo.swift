//
//  StreamVideo.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 7.7.22.
//

import Foundation

public typealias TokenProvider = (@escaping (Result<Token, Error>) -> Void) -> Void
public typealias TokenUpdater = (Token) -> ()

public class StreamVideo {
    
    // Temporarly storing user in memory.
    private var userInfo: UserInfo
    private var token: Token {
        didSet {
            callCoordinatorService.update(userToken: token.rawValue)
        }
    }
    private let tokenProvider: TokenProvider
    
    // Change it to your local IP address.
    private let hostname = "http://192.168.0.132:26991"
    
    private let httpClient: HTTPClient
    
    var callCoordinatorService: Stream_Video_CallCoordinatorService
    
    let apiKey: String
    let videoService = VideoService()
    let latencyService: LatencyService
    
    public init(
        apiKey: String,
        user: UserInfo,
        token: Token,
        tokenProvider: @escaping TokenProvider
    ) {
        self.apiKey = apiKey
        self.userInfo = user
        self.token = token
        self.tokenProvider = tokenProvider
        self.httpClient = URLSessionClient(
            urlSession: Self.makeURLSession(),
            tokenProvider: tokenProvider
        )
        self.callCoordinatorService = Stream_Video_CallCoordinatorService(
            httpClient: httpClient,
            hostname: hostname,
            token: token.rawValue
        )
        self.latencyService = LatencyService(httpClient: httpClient)
        self.httpClient.setTokenUpdater { [weak self] token in
            self?.token = token
        }
        StreamVideoProviderKey.currentValue = self
    }

    public func joinCall(
        callType: CallType,
        callId: String,
        videoOptions: VideoOptions
    ) async throws -> VideoRoom {
        let createCallResponse = try await createCall(callType: callType.name, callId: callId)
        
        let edges = try await joinCall(
            callId: createCallResponse.call.id,
            type: createCallResponse.call.type
        )
        
        let latencyByEdge = await measureLatencies(for: edges)
        
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
    
    private func createCall(callType: String, callId: String) async throws -> Stream_Video_CreateCallResponse {
        var createCallRequest = Stream_Video_CreateCallRequest()
        createCallRequest.id = callId
        createCallRequest.type = callType
        let createCallResponse = try await callCoordinatorService.createCall(createCallRequest: createCallRequest)
        return createCallResponse
    }
    
    private func measureLatencies(
        for edges: [Stream_Video_Edge]
    ) async -> [String: Stream_Video_Latency] {
        return await withTaskGroup(of: [String: Stream_Video_Latency].self) { group in
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
        log.debug("Selected edge server \(url)")
        return (url: url, token: token)
    }
    
    private static func makeURLSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let urlSession = URLSession(configuration: config)
        return urlSession
    }
    
}

/// Returns the current value for the `StreamVideo` instance.
internal struct StreamVideoProviderKey: InjectionKey {
    static var currentValue: StreamVideo?
}
