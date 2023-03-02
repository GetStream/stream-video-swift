//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

class CoordinatorClient: @unchecked Sendable {
    
    private let httpClient: HTTPClient
    let hostname: String
    var token: String
    let apiKey: String
    let userId: String
    var connectionId = ""
    let syncQueue = DispatchQueue(label: "io.getstream.CoordinatorClient", qos: .userInitiated)
    let pathPrefix: String = "video"
    
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
            request: request.getOrCreateCallRequest,
            path: "/join_call/\(request.type)/\(request.id)"
        )
    }
    
    func getCallEdgeServer(with request: SelectEdgeServerRequestData) async throws -> GetCallEdgeServerResponse {
        try await execute(
            request: request.getCallEdgeServerRequest,
            path: "/call/\(request.type)/\(request.id)/get_edge_server"
        )
    }
    
    func sendEvent(with request: EventRequestData) async throws -> SendEventResponse {
        try await execute(
            request: request.sendEventRequest,
            path: "/call/\(request.type)/\(request.id)/event"
        )
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
    
    func update(userToken: String) {
        syncQueue.async { [weak self] in
            self?.token = userToken
        }
    }
    
    private func execute<Request: Codable, Response: Codable>(request: Request, path: String) async throws -> Response {
        let requestData = try JSONEncoder().encode(request)
        var request = try makeRequest(for: path)
        request.httpBody = requestData
        return try await execute(urlRequest: request)
    }
    
    private func execute<Response: Codable>(urlRequest: URLRequest) async throws -> Response {
        let responseData = try await httpClient.execute(request: urlRequest)
        let response = try JSONDecoder.default.decode(Response.self, from: responseData)
        return response
    }

    private func makeRequest(for path: String) throws -> URLRequest {
        guard !connectionId.isEmpty,
              let queryParams = "?api_key=\(apiKey)&user_id=\(userId)&connection_id=\(connectionId)"
              .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw ClientError.Unexpected()
        }
        let url = hostname + pathPrefix + path + queryParams
        guard let url = URL(string: url) else {
            throw NSError(domain: "stream", code: 123)
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(token)", forHTTPHeaderField: "Authorization")
        request.setValue("jwt", forHTTPHeaderField: "stream-auth-type")
        request.setValue("stream-video-swift", forHTTPHeaderField: "X-Stream-Client")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "x-client-request-id")
        request.httpMethod = "POST"
        return request
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
