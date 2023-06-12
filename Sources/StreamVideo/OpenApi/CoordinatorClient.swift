//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

class CoordinatorClient: @unchecked Sendable {
    
    private let httpClient: HTTPClient
    let hostname: String
    var token: String
    let apiKey: String
    var userId: String
    var connectionId = ""
    let syncQueue = DispatchQueue(label: "io.getstream.CoordinatorClient", qos: .userInitiated)
    let pathPrefix: String = "video"
    
    // TODO: this needs to be fixed
    private var isAnonymous: Bool {
        false
    }
    
    private var connectionQueryParams: [String: String] {
        [
            "api_key": apiKey,
            "user_id": userId,
            "connection_id": connectionId
        ]
    }
    
    private var defaultQueryParams: [String: String] {
        [
            "api_key": apiKey,
            "user_id": userId
        ]
    }
    
    init(
        httpClient: HTTPClient,
        apiKey: String,
        hostname: String,
        token: String,
        userId: String
    ) {
        self.httpClient = httpClient
        self.hostname = hostname
        self.token = token
        self.apiKey = apiKey
        self.userId = userId
    }
    
    func joinCall(with request: JoinCallRequestData) async throws -> JoinCallResponse {
        try await execute(
            request: request.joinCallRequest,
            path: "/call/\(request.type)/\(request.id)/join"
        )
    }
    
    func getCall(
        callId: String,
        type: String,
        membersLimit: Int?,
        ring: Bool,
        notify: Bool
    ) async throws -> GetCallResponse {
        var queryParams = connectionQueryParams
        if let membersLimit {
            queryParams["membersLimit"] = "\(membersLimit)"
        }
        queryParams["ring"] = "\(ring)"
        queryParams["notify"] = "\(notify)"
        let path = "/call/\(type)/\(callId)"
        let request = try makeRequest(for: path, httpMethod: "GET", queryParams: queryParams)
        return try await execute(urlRequest: request)
    }
    
    func getOrCreateCall(
        with request: GetOrCreateCallRequest,
        callId: String,
        callType: String
    ) async throws -> GetOrCreateCallResponse {
        try await execute(request: request, path: "/call/\(callType)/\(callId)")
    }
    
    func sendEvent(with request: EventRequestData) async throws -> SendEventResponse {
        try await execute(
            request: request.sendEventRequest,
            path: "/call/\(request.type)/\(request.id)/event"
        )
    }
    
    func acceptCall(callId: String, type: String) async throws -> AcceptCallResponse {
        let request = try makeRequest(for: "/call/\(type)/\(callId)/accept")
        return try await execute(urlRequest: request)
    }
    
    func rejectCall(callId: String, type: String) async throws -> RejectCallResponse {
        let request = try makeRequest(for: "/call/\(type)/\(callId)/reject")
        return try await execute(urlRequest: request)
    }
    
    func endCall(with request: EndCallRequestData) async throws -> EndCallResponse {
        let request = try makeRequest(for: "/call/\(request.type)/\(request.id)/mark_ended")
        return try await execute(urlRequest: request)
    }
    
    func requestPermission(with request: RequestPermissionsRequestData) async throws -> RequestPermissionResponse {
        try await execute(
            request: request.requestPermissionRequest,
            path: "/call/\(request.type)/\(request.id)/request_permission"
        )
    }
    
    func updateUserPermissions(with request: UpdatePermissionsRequestData) async throws -> UpdateUserPermissionsResponse {
        try await execute(
            request: request.updateUserPermissionsRequest,
            path: "/call/\(request.type)/\(request.id)/user_permissions"
        )
    }
    
    func muteUsers(with request: MuteUsersRequestData) async throws -> MuteUsersResponse {
        try await execute(
            request: request.muteUsersRequest,
            path: "/call/\(request.type)/\(request.id)/mute_users"
        )
    }
    
    func queryMembers(with request: QueryMembersRequest) async throws -> QueryMembersResponse {
        try await execute(request: request, path: "/call/members")
    }
    
    func blockUser(with request: BlockUserRequestData) async throws -> BlockUserResponse {
        try await execute(
            request: request.blockUserRequest,
            path: "/call/\(request.type)/\(request.id)/block"
        )
    }
    
    func unblockUser(with request: UnblockUserRequestData) async throws -> UnblockUserResponse {
        try await execute(
            request: request.unblockUserRequest,
            path: "/call/\(request.type)/\(request.id)/unblock"
        )
    }
    
    func sendReaction(with request: SendReactionRequestData) async throws -> SendReactionResponse {
        try await execute(
            request: request.sendReactionRequest,
            path: "/call/\(request.type)/\(request.id)/reaction"
        )
    }
    
    func startRecording(callId: String, callType: String) async throws {
        let request = try makeRequest(for: "/call/\(callType)/\(callId)/start_recording")
        _ = try await httpClient.execute(request: request)
    }
    
    func stopRecording(callId: String, callType: String) async throws {
        let request = try makeRequest(for: "/call/\(callType)/\(callId)/stop_recording")
        _ = try await httpClient.execute(request: request)
    }
    
    func listRecordings(callId: String, callType: String, session: String) async throws -> ListRecordingsResponse {
        let request = try makeRequest(
            for: "/call/\(callType)/\(callId)/\(session)/recordings",
            httpMethod: "GET"
        )
        return try await execute(urlRequest: request)
    }
    
    func goLive(callId: String, callType: String) async throws -> GoLiveResponse {
        let request = try makeRequest(for: "/call/\(callType)/\(callId)/go_live")
        return try await execute(urlRequest: request)
    }
    
    func stopLive(callId: String, callType: String) async throws -> StopLiveResponse {
        let request = try makeRequest(for: "/call/\(callType)/\(callId)/stop_live")
        return try await execute(urlRequest: request)
    }
    
    func updateCall(
        request: UpdateCallRequest,
        callType: String,
        callId: String
    ) async throws -> UpdateCallResponse {
        var r = try makeRequest(for: "/call/\(callType)/\(callId)", httpMethod: "PATCH")
        r.httpBody = try JSONEncoder().encode(request)
        return try await execute(urlRequest: r)
    }

    func updateCallMembers(
        request: UpdateCallMembersRequest,
        callId: String,
        callType: String
    ) async throws -> UpdateCallMembersResponse {
        try await execute(
            request: request,
            path: "/call/\(callType)/\(callId)/members"
        )
    }
    
    func createGuestUser(request: CreateGuestRequest) async throws -> CreateGuestResponse {
        try await execute(
            request: request,
            path: "/guest",
            asGuest: true
        )
    }
    
    func queryCalls(request: QueryCallsRequest) async throws -> QueryCallsResponse {
        try await execute(request: request, path: "/calls")
    }
    
    func listDevices() async throws -> ListDevicesResponse {
        let urlRequest = try makeRequest(
            for: "/devices",
            httpMethod: "GET",
            queryParams: defaultQueryParams
        )
        return try await execute(urlRequest: urlRequest)
    }
    
    func createDevice(request: CreateDeviceRequest) async throws {
        var urlRequest = try makeRequest(
            for: "/devices",
            queryParams: defaultQueryParams
        )
        urlRequest.httpBody = try JSONEncoder().encode(request)
        _ = try await httpClient.execute(request: urlRequest)
    }
    
    func startBroadcasting(callId: String, callType: String) async throws {
        let urlRequest = try makeRequest(for: "/call/\(callType)/\(callId)/start_broadcasting")
        _ = try await httpClient.execute(request: urlRequest)
    }
    
    func stopBroadcasting(callId: String, callType: String) async throws {
        let urlRequest = try makeRequest(for: "/call/\(callType)/\(callId)/stop_broadcasting")
        _ = try await httpClient.execute(request: urlRequest)
    }
    
    func deleteDevice(with id: String) async throws {
        var queryParams = defaultQueryParams
        queryParams["id"] = id
        let urlRequest = try makeRequest(
            for: "/devices",
            httpMethod: "DELETE",
            queryParams: queryParams
        )
        _ = try await httpClient.execute(request: urlRequest)
    }
    
    func update(userToken: String) {
        syncQueue.async { [weak self] in
            self?.token = userToken
        }
    }
    
    private func execute<Request: Codable, Response: Codable>(
        request: Request,
        path: String,
        asGuest: Bool = false
    ) async throws -> Response {
        let requestData = try JSONEncoder().encode(request)
        var request: URLRequest
        if asGuest || isAnonymous {
            request = try makeGuestRequest(for: path)
        } else {
            request = try makeRequest(for: path)
        }
        request.httpBody = requestData
        return try await execute(urlRequest: request)
    }
    
    private func execute<Response: Codable>(urlRequest: URLRequest) async throws -> Response {
        let responseData = try await httpClient.execute(request: urlRequest)
        do {
            let response = try JSONDecoder.default.decode(Response.self, from: responseData)
            return response
        } catch {
            log.error("Error decoding response \(error.localizedDescription)")
            throw error
        }
    }
    
    private func makeGuestRequest(for path: String, httpMethod: String = "POST") throws -> URLRequest {
        let queryParams = "?api_key=\(apiKey)"
        let url = hostname + pathPrefix + path + queryParams
        guard let url = URL(string: url) else {
            throw ClientError.InvalidURL()
        }
        var request = URLRequest(url: url)
        if isAnonymous {
            request.setValue("\(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("anonymous", forHTTPHeaderField: "stream-auth-type")
        request.setValue("stream-video-swift", forHTTPHeaderField: "X-Stream-Client")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "x-client-request-id")
        request.httpMethod = httpMethod
        return request
    }

    private func makeRequest(
        for path: String,
        httpMethod: String = "POST"
    ) throws -> URLRequest {
        let url = try makeURLRequiringConnectionId(with: path)
        return makeURLRequest(url: url, httpMethod: httpMethod)
    }
    
    private func makeRequest(
        for path: String,
        httpMethod: String = "POST",
        queryParams: [String: String]
    ) throws -> URLRequest {
        let url = try makeURL(with: path, queryItems: queryParams)
        return makeURLRequest(url: url, httpMethod: httpMethod)
    }
    
    private func makeURLRequest(url: URL, httpMethod: String = "POST") -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(token)", forHTTPHeaderField: "Authorization")
        request.setValue("jwt", forHTTPHeaderField: "stream-auth-type")
        request.setValue("stream-video-swift", forHTTPHeaderField: "X-Stream-Client")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "x-client-request-id")
        request.httpMethod = httpMethod
        return request
    }
    
    private func makeURLRequiringConnectionId(with path: String) throws -> URL {
        guard !connectionId.isEmpty else { throw ClientError.Unexpected() }
        let urlString = hostname + pathPrefix + path
        return try self.url(string: urlString, queryItems: connectionQueryParams)
    }
    
    private func makeURL(with path: String, queryItems: [String: String]) throws -> URL {
        let urlString = hostname + pathPrefix + path
        return try self.url(string: urlString, queryItems: queryItems)
    }
    
    private func url(string: String, queryItems: [String: String]) throws -> URL {
        guard let url = URL(string: string) else {
            throw ClientError.InvalidURL()
        }
        return try url.appendingQueryItems(queryItems)
    }
}

extension URLRequest {

    /**
     Returns a cURL command representation of this URL request.
     */
    public var curlString: String {
        guard let url = url else { return "" }
        var baseCommand = #"curl "\#(url.absoluteString)""#

        if httpMethod == "HEAD" {
            baseCommand += " --head"
        }

        var command = [baseCommand]

        if let method = httpMethod, method != "GET" && method != "HEAD" {
            command.append("-X \(method)")
        }

        if let headers = allHTTPHeaderFields {
            for (key, value) in headers where key != "Cookie" {
                command.append("-H '\(key): \(value)'")
            }
        }

        if let data = httpBody, let body = String(data: data, encoding: .utf8) {
            command.append("-d '\(body)'")
        }

        return command.joined(separator: " \\\n\t")
    }
}
