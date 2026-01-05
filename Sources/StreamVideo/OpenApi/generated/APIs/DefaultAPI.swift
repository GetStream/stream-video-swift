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
        jsonDecoder: JSONDecoder = JSONDecoder.default,
        jsonEncoder: JSONEncoder = JSONEncoder.default
    ) {
        self.basePath = basePath
        self.transport = transport
        self.middlewares = middlewares
        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = jsonEncoder
    }

    func send<Response: Codable>(
        request: Request,
        deserializer: (Data) throws -> Response
    ) async throws -> Response {

        // TODO: make this a bit nicer and create an API error to make it easier to handle stuff
        func makeError(_ error: Error) -> Error {
            error
        }

        func wrappingErrors<R>(
            work: () async throws -> R,
            mapError: (Error) -> Error
        ) async throws -> R {
            do {
                return try await work()
            } catch {
                throw mapError(error)
            }
        }

        let (data, _) = try await wrappingErrors {
            var next: (Request) async throws -> (Data, URLResponse) = { _request in
                try await wrappingErrors {
                    try await self.transport.execute(request: _request)
                } mapError: { error in
                    makeError(error)
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
            return try await next(request)
        } mapError: { error in
            makeError(error)
        }

        return try await wrappingErrors {
            try deserializer(data)
        } mapError: { error in
            makeError(error)
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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

        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let namePreEscape = "\(APIHelper.mapValueToPathItem(name))"
        let namePostEscape = namePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "name"), with: namePostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

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
        startRecordingRequest: StartRecordingRequest
    ) async throws -> StartRecordingResponse {
        var path = "/video/call/{type}/{id}/start_recording"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: stopLiveRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(StopLiveResponse.self, from: $0)
        }
    }

    open func stopRecording(type: String, id: String) async throws -> StopRecordingResponse {
        var path = "/video/call/{type}/{id}/stop_recording"
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        
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
        
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let sessionPreEscape = "\(APIHelper.mapValueToPathItem(session))"
        let sessionPostEscape = sessionPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(
            of: String(format: "{%@}", "session"),
            with: sessionPostEscape,
            options: .literal,
            range: nil
        )
        let filenamePreEscape = "\(APIHelper.mapValueToPathItem(filename))"
        let filenamePostEscape = filenamePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(
            of: String(format: "{%@}", "filename"),
            with: filenamePostEscape,
            options: .literal,
            range: nil
        )
        
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

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)
        let sessionPreEscape = "\(APIHelper.mapValueToPathItem(session))"
        let sessionPostEscape = sessionPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "session"), with: sessionPostEscape, options: .literal, range: nil)
        let filenamePreEscape = "\(APIHelper.mapValueToPathItem(filename))"
        let filenamePostEscape = filenamePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "filename"), with: filenamePostEscape, options: .literal, range: nil)

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

        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "type"), with: typePostEscape, options: .literal, range: nil)
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(of: String(format: "{%@}", "id"), with: idPostEscape, options: .literal, range: nil)

        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: ringCallRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(RingCallResponse.self, from: $0)
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
        
    func startRecording(type: String, id: String, startRecordingRequest: StartRecordingRequest) async throws
        -> StartRecordingResponse
        
    func startTranscription(type: String, id: String, startTranscriptionRequest: StartTranscriptionRequest) async throws
        -> StartTranscriptionResponse
    
    func stopHLSBroadcasting(type: String, id: String) async throws -> StopHLSBroadcastingResponse
        
    func stopClosedCaptions(type: String, id: String, stopClosedCaptionsRequest: StopClosedCaptionsRequest) async throws
        -> StopClosedCaptionsResponse
        
    func stopLive(type: String, id: String, stopLiveRequest: StopLiveRequest) async throws -> StopLiveResponse
        
    func stopRecording(type: String, id: String) async throws -> StopRecordingResponse
        
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
}
