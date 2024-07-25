//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

final class AuthenticationAdapter {
    
    let apiKey: String

    private var _sessionId: String
    private var _url: URL
    private var _hostname: String
    private var _token: String

    var sessionId: String { queue.sync { _sessionId } }
    var url: URL { queue.sync { _url } }
    var hostname: String { queue.sync { _hostname } }
    var token: String { queue.sync { _token } }

    private let joinCallResponseProvider: () async throws -> JoinCallResponse
    private let queue = UnfairQueue()

    init(
        sessionId: String = UUID().uuidString,
        url: URL,
        hostname: String,
        token: String,
        apiKey: String,
        joinCallResponseProvider: @escaping () async throws -> JoinCallResponse
    ) {
        _sessionId = sessionId
        _url = url
        _hostname = hostname
        _token = token
        self.apiKey = apiKey
        self.joinCallResponseProvider = joinCallResponseProvider
    }

    func authenticate(updateSession: Bool) async throws -> JoinCallResponse {
        let response = try await joinCallResponseProvider()

        try didUpdate(with: response, updateSession: updateSession)

        return response
    }

    private func didUpdate(
        with response: JoinCallResponse,
        updateSession: Bool
    ) throws {
        try queue.sync {
            if let url = URL(string: response.credentials.server.url) {
                _url = url
            } else {
                throw ClientError("Invalid url found \(response.credentials.server.url).")
            }
            if updateSession {
                _sessionId = UUID().uuidString
            }
            _hostname = response.credentials.server.wsEndpoint
            _token = response.credentials.token
        }
    }
}
