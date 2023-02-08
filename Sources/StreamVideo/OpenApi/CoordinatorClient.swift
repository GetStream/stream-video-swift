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
    
    func joinCall(with request: JoinCallRequest) async throws -> JoinCallResponse {
        try await execute(
            request: request.getOrCreateCallRequest,
            path: "/join_call/\(request.type)/\(request.id)"
        )
    }
    
    func getCallEdgeServer(with request: SelectEdgeServerRequest) async throws -> GetCallEdgeServerResponse {
        try await execute(
            request: request.getCallEdgeServerRequest,
            path: "/get_call_edge_server/\(request.type)/\(request.id)"
        )
    }
    
    func sendEvent(with request: EventRequest) async throws -> SendEventResponse {
        try await execute(
            request: request.sendEventRequest,
            path: "/call/\(request.type)/\(request.id)/event"
        )
    }
    
    func endCall(with request: EndCallRequest) async throws -> EndCallResponse {
        let request = try makeRequest(for: "/call/\(request.type)/\(request.id)/mark_ended")
        return try await execute(urlRequest: request)
    }
    
    func requestPermission(with request: PermissionsRequest) async throws -> RequestPermissionRequest {
        try await execute(
            request: request.requestPermissionRequest,
            path: "/call/\(request.type)/\(request.id)/request_permission"
        )
    }
    
    func updateUserPermissions(with request: UpdatePermissionsRequest) async throws -> UpdateUserPermissionsResponse {
        try await execute(
            request: request.updateUserPermissionsRequest,
            path: "/call/\(request.type)/\(request.id)/user_permissions"
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
