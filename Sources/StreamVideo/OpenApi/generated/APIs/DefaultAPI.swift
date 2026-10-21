//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case head = "HEAD"
    case patch = "PATCH"
    case options = "OPTIONS"
    case trace = "TRACE"
    case connect = "CONNECT"

    init(stringValue: String) {
        guard let method = HTTPMethod(rawValue: stringValue.uppercased()) else {
            self = .get
            return
        }
        self = method
    }
}

internal struct Request {
    var url: URL
    var method: HTTPMethod
    var body: Data? = nil
    var queryParams: [URLQueryItem] = []
    var headers: [String: String] = [:]

    func urlRequest() throws -> URLRequest {
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        var existingQueryItems = urlComponents.queryItems ?? []
        existingQueryItems.append(contentsOf: queryParams)
        urlComponents.queryItems = existingQueryItems
        var urlRequest = URLRequest(url: urlComponents.url!)
        headers.forEach { (k, v) in
            urlRequest.setValue(v, forHTTPHeaderField: k)
        }
        urlRequest.httpMethod = method.rawValue
        urlRequest.httpBody = body
        return urlRequest
    }
}

protocol DefaultAPITransport: Sendable {
    func execute(request: Request) async throws -> (Data, URLResponse)
}

protocol DefaultAPIClientMiddleware: Sendable {
    func intercept(
        _ request: Request,
        next: (Request) async throws -> (Data, URLResponse)
    ) async throws -> (Data, URLResponse)
}

struct EmptyResponse: Codable {}

open class DefaultAPI: DefaultAPIEndpoints, @unchecked Sendable {
    internal var transport: DefaultAPITransport
    internal var middlewares: [DefaultAPIClientMiddleware]
    internal var basePath: String
    internal var jsonDecoder: JSONDecoder
    internal var jsonEncoder: JSONEncoder

    init(
        basePath: String,
        transport: DefaultAPITransport,
        middlewares: [DefaultAPIClientMiddleware],
        jsonDecoder: JSONDecoder = JSONDecoder.streamCore,
        jsonEncoder: JSONEncoder = JSONEncoder.streamCore
    ) {
        self.basePath = basePath
        self.transport = transport
        self.middlewares = middlewares
        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = jsonEncoder
    }

    // TODO: make this a bit nicer and create an API error to make it easier to handle stuff
    private static func makeError(_ error: Error) -> Error {
        error
    }

    /// Runs `request` through the middleware chain and returns the raw payload.
    ///
    /// Kept non-generic and never inlined so that the middleware chain is
    /// emitted once, instead of being specialised into every endpoint that
    /// calls `send(request:deserializer:)`.
    @inline(never)
    private func perform(request: Request) async throws -> Data {
        do {
            var next: (Request) async throws -> (Data, URLResponse) = { _request in
                do {
                    return try await self.transport.execute(request: _request)
                } catch {
                    throw Self.makeError(error)
                }
            }
            for middleware in middlewares.reversed() {
                let tmp = next
                next = {
                    try await middleware.intercept(
                        $0,
                        next: tmp
                    )
                }
            }
            let (data, _) = try await next(request)
            return data
        } catch {
            throw Self.makeError(error)
        }
    }

    func send<Response: Codable>(
        request: Request,
        deserializer: (Data) throws -> Response
    ) async throws -> Response {
        let data = try await perform(request: request)
        do {
            return try deserializer(data)
        } catch {
            throw Self.makeError(error)
        }
    }

    func makeRequest(
        uriPath: String,
        queryParams: [URLQueryItem] = [],
        httpMethod: String
    ) throws -> Request {
        let url = URL(string: basePath + uriPath)!
        return Request(
            url: url,
            method: .init(stringValue: httpMethod),
            queryParams: queryParams,
            headers: ["Content-Type": "application/json"]
        )
    }

    /// Replaces the `{name}` placeholder in `path` with the percent-escaped
    /// `value`.
    ///
    /// Kept non-generic and never inlined so that the escaping sequence is
    /// emitted once, instead of once per path parameter across every endpoint.
    @inline(never)
    private static func substitutingPathParameter(
        _ name: String,
        with value: Any,
        in path: String
    ) -> String {
        let escaped = "\(APIHelper.mapValueToPathItem(value))"
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        return path.replacingOccurrences(
            of: "{\(name)}",
            with: escaped,
            options: .literal,
            range: nil
        )
    }

    func makeRequest<T: Encodable>(
        uriPath: String,
        queryParams: [URLQueryItem] = [],
        httpMethod: String,
        request: T
    ) throws -> Request {
        var r = try makeRequest(uriPath: uriPath, queryParams: queryParams, httpMethod: httpMethod)
        r.body = try jsonEncoder.encode(request)
        return r
    }

    open func queryCallMembers(queryMembersRequest: QueryMembersRequest) async throws -> QueryMembersResponse {
        let path = "/video/call/members"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: queryMembersRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(QueryMembersResponse.self, from: $0)
        }
    }

    open func queryCallStats(queryCallStatsRequest: QueryCallStatsRequest) async throws -> QueryCallStatsResponse {
        let path = "/video/call/stats"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: queryCallStatsRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(QueryCallStatsResponse.self, from: $0)
        }
    }

    open func getCall(
        type: String,
        id: String,
        membersLimit: Int?,
        ring: Bool?,
        notify: Bool?,
        video: Bool?
    ) async throws -> GetCallResponse {
        var path = "/video/call/{type}/{id}"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "members_limit": (wrappedValue: membersLimit?.encodeToJSON(), isExplode: true),
            "ring": (wrappedValue: ring?.encodeToJSON(), isExplode: true),
            "notify": (wrappedValue: notify?.encodeToJSON(), isExplode: true),
            "video": (wrappedValue: video?.encodeToJSON(), isExplode: true)
            
        ])
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(GetCallResponse.self, from: $0)
        }
    }

    open func updateCall(type: String, id: String, updateCallRequest: UpdateCallRequest) async throws -> UpdateCallResponse {
        var path = "/video/call/{type}/{id}"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "PATCH",
            request: updateCallRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UpdateCallResponse.self, from: $0)
        }
    }

    open func getOrCreateCall(
        type: String,
        id: String,
        getOrCreateCallRequest: GetOrCreateCallRequest
    ) async throws -> GetOrCreateCallResponse {
        var path = "/video/call/{type}/{id}"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: getOrCreateCallRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(GetOrCreateCallResponse.self, from: $0)
        }
    }

    open func acceptCall(type: String, id: String) async throws -> AcceptCallResponse {
        var path = "/video/call/{type}/{id}/accept"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(AcceptCallResponse.self, from: $0)
        }
    }

    open func blockUser(type: String, id: String, blockUserRequest: BlockUserRequest) async throws -> BlockUserResponse {
        var path = "/video/call/{type}/{id}/block"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: blockUserRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(BlockUserResponse.self, from: $0)
        }
    }

    open func deleteCall(type: String, id: String, deleteCallRequest: DeleteCallRequest) async throws -> DeleteCallResponse {
        var path = "/video/call/{type}/{id}/delete"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: deleteCallRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(DeleteCallResponse.self, from: $0)
        }
    }

    open func sendCallEvent(type: String, id: String, sendEventRequest: SendEventRequest) async throws -> SendEventResponse {
        var path = "/video/call/{type}/{id}/event"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: sendEventRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(SendEventResponse.self, from: $0)
        }
    }
    
    open func collectUserFeedback(
        type: String,
        id: String,
        collectUserFeedbackRequest: CollectUserFeedbackRequest
    ) async throws -> CollectUserFeedbackResponse {
        var path = "/video/call/{type}/{id}/feedback"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: collectUserFeedbackRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(CollectUserFeedbackResponse.self, from: $0)
        }
    }

    open func goLive(type: String, id: String, goLiveRequest: GoLiveRequest) async throws -> GoLiveResponse {
        var path = "/video/call/{type}/{id}/go_live"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: goLiveRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(GoLiveResponse.self, from: $0)
        }
    }

    open func joinCall(type: String, id: String, joinCallRequest: JoinCallRequest) async throws -> JoinCallResponse {
        var path = "/video/call/{type}/{id}/join"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: joinCallRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(JoinCallResponse.self, from: $0)
        }
    }

    open func kickUser(
        type: String,
        id: String,
        kickUserRequest: KickUserRequest
    ) async throws -> KickUserResponse {
        var path = "/video/call/{type}/{id}/kick"

        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: kickUserRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(KickUserResponse.self, from: $0)
        }
    }

    open func endCall(type: String, id: String) async throws -> EndCallResponse {
        var path = "/video/call/{type}/{id}/mark_ended"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(EndCallResponse.self, from: $0)
        }
    }

    open func updateCallMembers(
        type: String,
        id: String,
        updateCallMembersRequest: UpdateCallMembersRequest
    ) async throws -> UpdateCallMembersResponse {
        var path = "/video/call/{type}/{id}/members"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: updateCallMembersRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UpdateCallMembersResponse.self, from: $0)
        }
    }

    open func muteUsers(type: String, id: String, muteUsersRequest: MuteUsersRequest) async throws -> MuteUsersResponse {
        var path = "/video/call/{type}/{id}/mute_users"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: muteUsersRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(MuteUsersResponse.self, from: $0)
        }
    }

    open func queryCallParticipants(
        id: String,
        type: String,
        limit: Int?,
        queryCallParticipantsRequest: QueryCallParticipantsRequest
    ) async throws -> QueryCallParticipantsResponse {
        var path = "/video/call/{type}/{id}/participants"

        path = Self.substitutingPathParameter("id", with: id, in: path)
        path = Self.substitutingPathParameter("type", with: type, in: path)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "limit": (wrappedValue: limit?.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "POST",
            request: queryCallParticipantsRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(QueryCallParticipantsResponse.self, from: $0)
        }
    }

    open func videoPin(type: String, id: String, pinRequest: PinRequest) async throws -> PinResponse {
        var path = "/video/call/{type}/{id}/pin"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: pinRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(PinResponse.self, from: $0)
        }
    }

    open func sendVideoReaction(
        type: String,
        id: String,
        sendReactionRequest: SendReactionRequest
    ) async throws -> SendReactionResponse {
        var path = "/video/call/{type}/{id}/reaction"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: sendReactionRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(SendReactionResponse.self, from: $0)
        }
    }

    open func listRecordings(type: String, id: String) async throws -> ListRecordingsResponse {
        var path = "/video/call/{type}/{id}/recordings"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(ListRecordingsResponse.self, from: $0)
        }
    }

    open func rejectCall(type: String, id: String, rejectCallRequest: RejectCallRequest) async throws -> RejectCallResponse {
        var path = "/video/call/{type}/{id}/reject"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: rejectCallRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(RejectCallResponse.self, from: $0)
        }
    }

    open func requestPermission(
        type: String,
        id: String,
        requestPermissionRequest: RequestPermissionRequest
    ) async throws -> RequestPermissionResponse {
        var path = "/video/call/{type}/{id}/request_permission"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: requestPermissionRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(RequestPermissionResponse.self, from: $0)
        }
    }

    open func startRTMPBroadcasts(
        type: String,
        id: String,
        startRTMPBroadcastsRequest: StartRTMPBroadcastsRequest
    ) async throws -> StartRTMPBroadcastsResponse {
        var path = "/video/call/{type}/{id}/rtmp_broadcasts"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: startRTMPBroadcastsRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StartRTMPBroadcastsResponse.self, from: $0)
        }
    }

    open func stopAllRTMPBroadcasts(type: String, id: String) async throws -> StopAllRTMPBroadcastsResponse {
        var path = "/video/call/{type}/{id}/rtmp_broadcasts/stop"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StopAllRTMPBroadcastsResponse.self, from: $0)
        }
    }

    open func stopRTMPBroadcast(type: String, id: String, name: String) async throws -> StopRTMPBroadcastsResponse {
        var path = "/video/call/{type}/{id}/rtmp_broadcasts/{name}/stop"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        path = Self.substitutingPathParameter("name", with: name, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StopRTMPBroadcastsResponse.self, from: $0)
        }
    }

    open func startHLSBroadcasting(type: String, id: String) async throws -> StartHLSBroadcastingResponse {
        var path = "/video/call/{type}/{id}/start_broadcasting"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StartHLSBroadcastingResponse.self, from: $0)
        }
    }

    open func startClosedCaptions(
        type: String,
        id: String,
        startClosedCaptionsRequest: StartClosedCaptionsRequest
    ) async throws -> StartClosedCaptionsResponse {
        var path = "/video/call/{type}/{id}/start_closed_captions"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: startClosedCaptionsRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StartClosedCaptionsResponse.self, from: $0)
        }
    }

    open func startFrameRecording(
        type: String,
        id: String,
        startFrameRecordingRequest: StartFrameRecordingRequest
    ) async throws -> StartFrameRecordingResponse {
        var path = "/video/call/{type}/{id}/start_frame_recording"

        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: startFrameRecordingRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StartFrameRecordingResponse.self, from: $0)
        }
    }

    open func startRecording(
        type: String,
        id: String,
        recordingType: String,
        startRecordingRequest: StartRecordingRequest
    ) async throws -> StartRecordingResponse {
        var path = "/video/call/{type}/{id}/recordings/{recording_type}/start"

        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        path = Self.substitutingPathParameter("recording_type", with: recordingType, in: path)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: startRecordingRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StartRecordingResponse.self, from: $0)
        }
    }

    open func startTranscription(
        type: String,
        id: String,
        startTranscriptionRequest: StartTranscriptionRequest
    ) async throws -> StartTranscriptionResponse {
        var path = "/video/call/{type}/{id}/start_transcription"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: startTranscriptionRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StartTranscriptionResponse.self, from: $0)
        }
    }

    open func stopHLSBroadcasting(type: String, id: String) async throws -> StopHLSBroadcastingResponse {
        var path = "/video/call/{type}/{id}/stop_broadcasting"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StopHLSBroadcastingResponse.self, from: $0)
        }
    }

    open func stopClosedCaptions(
        type: String,
        id: String,
        stopClosedCaptionsRequest: StopClosedCaptionsRequest
    ) async throws -> StopClosedCaptionsResponse {
        var path = "/video/call/{type}/{id}/stop_closed_captions"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: stopClosedCaptionsRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StopClosedCaptionsResponse.self, from: $0)
        }
    }

    open func stopFrameRecording(type: String, id: String) async throws -> StopFrameRecordingResponse {
        var path = "/video/call/{type}/{id}/stop_frame_recording"

        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StopFrameRecordingResponse.self, from: $0)
        }
    }

    open func stopLive(type: String, id: String, stopLiveRequest: StopLiveRequest) async throws -> StopLiveResponse {
        var path = "/video/call/{type}/{id}/stop_live"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: stopLiveRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StopLiveResponse.self, from: $0)
        }
    }

    open func stopRecording(
        type: String,
        id: String,
        recordingType: String
    ) async throws -> StopRecordingResponse {
        var path = "/video/call/{type}/{id}/recordings/{recording_type}/stop"

        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        path = Self.substitutingPathParameter("recording_type", with: recordingType, in: path)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StopRecordingResponse.self, from: $0)
        }
    }

    open func stopTranscription(
        type: String,
        id: String,
        stopTranscriptionRequest: StopTranscriptionRequest
    ) async throws -> StopTranscriptionResponse {
        var path = "/video/call/{type}/{id}/stop_transcription"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: stopTranscriptionRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StopTranscriptionResponse.self, from: $0)
        }
    }

    open func listTranscriptions(type: String, id: String) async throws -> ListTranscriptionsResponse {
        var path = "/video/call/{type}/{id}/transcriptions"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(ListTranscriptionsResponse.self, from: $0)
        }
    }

    open func unblockUser(type: String, id: String, unblockUserRequest: UnblockUserRequest) async throws -> UnblockUserResponse {
        var path = "/video/call/{type}/{id}/unblock"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: unblockUserRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UnblockUserResponse.self, from: $0)
        }
    }

    open func videoUnpin(type: String, id: String, unpinRequest: UnpinRequest) async throws -> UnpinResponse {
        var path = "/video/call/{type}/{id}/unpin"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: unpinRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UnpinResponse.self, from: $0)
        }
    }

    open func updateUserPermissions(
        type: String,
        id: String,
        updateUserPermissionsRequest: UpdateUserPermissionsRequest
    ) async throws -> UpdateUserPermissionsResponse {
        var path = "/video/call/{type}/{id}/user_permissions"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: updateUserPermissionsRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(UpdateUserPermissionsResponse.self, from: $0)
        }
    }

    open func deleteRecording(type: String, id: String, session: String, filename: String) async throws -> DeleteRecordingResponse {
        var path = "/video/call/{type}/{id}/{session}/recordings/{filename}"
        
        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        path = Self.substitutingPathParameter("session", with: session, in: path)
        path = Self.substitutingPathParameter("filename", with: filename, in: path)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(DeleteRecordingResponse.self, from: $0)
        }
    }

    open func deleteTranscription(
        type: String,
        id: String,
        session: String,
        filename: String
    ) async throws -> DeleteTranscriptionResponse {
        var path = "/video/call/{type}/{id}/{session}/transcriptions/{filename}"

        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        path = Self.substitutingPathParameter("session", with: session, in: path)
        path = Self.substitutingPathParameter("filename", with: filename, in: path)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(DeleteTranscriptionResponse.self, from: $0)
        }
    }

    open func queryCalls(queryCallsRequest: QueryCallsRequest) async throws -> QueryCallsResponse {
        let path = "/video/calls"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: queryCallsRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(QueryCallsResponse.self, from: $0)
        }
    }

    open func deleteDevice(id: String) async throws -> ModelResponse {
        let path = "/video/devices"
        
        let queryParams = APIHelper.mapValuesToQueryItems([
            "id": (wrappedValue: id.encodeToJSON(), isExplode: true)
            
        ])
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(ModelResponse.self, from: $0)
        }
    }

    open func listDevices() async throws -> ListDevicesResponse {
        let path = "/video/devices"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(ListDevicesResponse.self, from: $0)
        }
    }

    open func createDevice(createDeviceRequest: CreateDeviceRequest) async throws -> ModelResponse {
        let path = "/video/devices"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: createDeviceRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(ModelResponse.self, from: $0)
        }
    }

    open func getEdges() async throws -> GetEdgesResponse {
        let path = "/video/edges"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(GetEdgesResponse.self, from: $0)
        }
    }

    open func createGuest(createGuestRequest: CreateGuestRequest) async throws -> CreateGuestResponse {
        let path = "/video/guest"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: createGuestRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(CreateGuestResponse.self, from: $0)
        }
    }

    open func videoConnect() async throws {
        let path = "/video/longpoll"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        _ = try await send(request: urlRequest) {
            try self.jsonDecoder.decode(EmptyResponse.self, from: $0)
        }
    }
    
    open func ringCall(type: String, id: String, ringCallRequest: RingCallRequest) async throws -> RingCallResponse {
        var path = "/video/call/{type}/{id}/ring"

        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: ringCallRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(RingCallResponse.self, from: $0)
        }
    }
    
    open func reportClientCallEvent(reportClientEventRequest: ReportClientEventRequest) async throws -> ReportClientEventResponse {
        let path = "/api/v2/video/call_client_event"

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: reportClientEventRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(ReportClientEventResponse.self, from: $0)
        }
    }
    
    open func getCallRingState(type: String, id: String, callSessionId: String) async throws -> GetCallRingStateResponse {
        var path = "/api/v2/video/call/{type}/{id}/ring_state"

        path = Self.substitutingPathParameter("type", with: type, in: path)
        path = Self.substitutingPathParameter("id", with: id, in: path)
        let queryParams = APIHelper.mapValuesToQueryItems([
            "call_session_id": (wrappedValue: callSessionId.encodeToJSON(), isExplode: true)
        ])

        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(GetCallRingStateResponse.self, from: $0)
        }
    }
}

protocol DefaultAPIEndpoints {
    func queryCallMembers(queryMembersRequest: QueryMembersRequest) async throws -> QueryMembersResponse
        
    func queryCallStats(queryCallStatsRequest: QueryCallStatsRequest) async throws -> QueryCallStatsResponse
        
    func getCall(type: String, id: String, membersLimit: Int?, ring: Bool?, notify: Bool?, video: Bool?) async throws
        -> GetCallResponse
        
    func updateCall(type: String, id: String, updateCallRequest: UpdateCallRequest) async throws -> UpdateCallResponse
        
    func getOrCreateCall(type: String, id: String, getOrCreateCallRequest: GetOrCreateCallRequest) async throws
        -> GetOrCreateCallResponse
        
    func acceptCall(type: String, id: String) async throws -> AcceptCallResponse
        
    func blockUser(type: String, id: String, blockUserRequest: BlockUserRequest) async throws -> BlockUserResponse
        
    func deleteCall(type: String, id: String, deleteCallRequest: DeleteCallRequest) async throws -> DeleteCallResponse
        
    func sendCallEvent(type: String, id: String, sendEventRequest: SendEventRequest) async throws -> SendEventResponse
        
    func collectUserFeedback(
        type: String,
        id: String,
        collectUserFeedbackRequest: CollectUserFeedbackRequest
    ) async throws -> CollectUserFeedbackResponse
        
    func goLive(type: String, id: String, goLiveRequest: GoLiveRequest) async throws -> GoLiveResponse
        
    func joinCall(type: String, id: String, joinCallRequest: JoinCallRequest) async throws -> JoinCallResponse

    func kickUser(type: String, id: String, kickUserRequest: KickUserRequest) async throws -> KickUserResponse

    func endCall(type: String, id: String) async throws -> EndCallResponse
        
    func updateCallMembers(type: String, id: String, updateCallMembersRequest: UpdateCallMembersRequest) async throws
        -> UpdateCallMembersResponse
        
    func muteUsers(type: String, id: String, muteUsersRequest: MuteUsersRequest) async throws -> MuteUsersResponse

    func queryCallParticipants(id: String, type: String, limit: Int?, queryCallParticipantsRequest: QueryCallParticipantsRequest) async throws -> QueryCallParticipantsResponse

    func videoPin(type: String, id: String, pinRequest: PinRequest) async throws -> PinResponse
        
    func sendVideoReaction(type: String, id: String, sendReactionRequest: SendReactionRequest) async throws -> SendReactionResponse
        
    func listRecordings(type: String, id: String) async throws -> ListRecordingsResponse
        
    func rejectCall(type: String, id: String, rejectCallRequest: RejectCallRequest) async throws -> RejectCallResponse
        
    func requestPermission(type: String, id: String, requestPermissionRequest: RequestPermissionRequest) async throws
        -> RequestPermissionResponse
        
    func startRTMPBroadcasts(type: String, id: String, startRTMPBroadcastsRequest: StartRTMPBroadcastsRequest) async throws
        -> StartRTMPBroadcastsResponse
        
    func stopAllRTMPBroadcasts(type: String, id: String) async throws -> StopAllRTMPBroadcastsResponse
        
    func stopRTMPBroadcast(type: String, id: String, name: String) async throws -> StopRTMPBroadcastsResponse
        
    func startHLSBroadcasting(type: String, id: String) async throws -> StartHLSBroadcastingResponse
        
    func startClosedCaptions(type: String, id: String, startClosedCaptionsRequest: StartClosedCaptionsRequest) async throws
        -> StartClosedCaptionsResponse
        
    func startFrameRecording(type: String, id: String, startFrameRecordingRequest: StartFrameRecordingRequest) async throws
        -> StartFrameRecordingResponse
        
    func startRecording(
        type: String,
        id: String,
        recordingType: String,
        startRecordingRequest: StartRecordingRequest
    ) async throws -> StartRecordingResponse
        
    func startTranscription(type: String, id: String, startTranscriptionRequest: StartTranscriptionRequest) async throws
        -> StartTranscriptionResponse
    
    func stopHLSBroadcasting(type: String, id: String) async throws -> StopHLSBroadcastingResponse
        
    func stopClosedCaptions(type: String, id: String, stopClosedCaptionsRequest: StopClosedCaptionsRequest) async throws
        -> StopClosedCaptionsResponse
        
    func stopFrameRecording(type: String, id: String) async throws -> StopFrameRecordingResponse
        
    func stopLive(type: String, id: String, stopLiveRequest: StopLiveRequest) async throws -> StopLiveResponse
        
    func stopRecording(type: String, id: String, recordingType: String) async throws -> StopRecordingResponse
        
    func stopTranscription(type: String, id: String, stopTranscriptionRequest: StopTranscriptionRequest) async throws
        -> StopTranscriptionResponse
        
    func listTranscriptions(type: String, id: String) async throws -> ListTranscriptionsResponse
        
    func unblockUser(type: String, id: String, unblockUserRequest: UnblockUserRequest) async throws -> UnblockUserResponse
        
    func videoUnpin(type: String, id: String, unpinRequest: UnpinRequest) async throws -> UnpinResponse
        
    func updateUserPermissions(type: String, id: String, updateUserPermissionsRequest: UpdateUserPermissionsRequest) async throws
        -> UpdateUserPermissionsResponse
        
    func deleteRecording(type: String, id: String, session: String, filename: String) async throws -> DeleteRecordingResponse

    func deleteTranscription(
        type: String,
        id: String,
        session: String,
        filename: String
    ) async throws -> DeleteTranscriptionResponse

    func queryCalls(queryCallsRequest: QueryCallsRequest) async throws -> QueryCallsResponse
        
    func deleteDevice(id: String) async throws -> ModelResponse
        
    func listDevices() async throws -> ListDevicesResponse
        
    func createDevice(createDeviceRequest: CreateDeviceRequest) async throws -> ModelResponse
        
    func getEdges() async throws -> GetEdgesResponse
        
    func createGuest(createGuestRequest: CreateGuestRequest) async throws -> CreateGuestResponse
        
    func videoConnect() async throws -> Void
    
    func ringCall(type: String, id: String, ringCallRequest: RingCallRequest) async throws -> RingCallResponse
    
    func reportClientCallEvent(reportClientEventRequest: ReportClientEventRequest) async throws -> ReportClientEventResponse
    
    func getCallRingState(type: String, id: String, callSessionId: String) async throws -> GetCallRingStateResponse
}
