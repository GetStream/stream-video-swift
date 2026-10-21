//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Adds the coordinator connection ID and prevents ringing without one.
///
/// This middleware must be first in the client's middleware array. It
/// resolves connection readiness and rejects invalid or cancelled ring
/// requests before request enrichment, authentication, or transport runs.
/// Later middleware receives the resolved connection ID when available.
struct CoordinatorConnectionMiddleware: @unchecked Sendable, DefaultAPIClientMiddleware {
    private let connectionIdProvider: () async throws -> String

    init(connectionIdProvider: @escaping () async throws -> String) {
        self.connectionIdProvider = connectionIdProvider
    }

    func intercept(
        _ request: Request,
        next: (Request) async throws -> (Data, URLResponse)
    ) async throws -> (Data, URLResponse) {
        let connectionId = try await connectionIdProvider()
        if startsRinging(request) {
            try Task.checkCancellation()
            guard !connectionId.isEmpty else {
                throw ClientError("Cannot ring a call without a connection id.")
            }
        }

        var modifiedRequest = request
        if !connectionId.isEmpty {
            modifiedRequest.queryParams.append(.init(name: "connection_id", value: connectionId))
        }
        return try await next(modifiedRequest)
    }

    /// Identifies requests that can start an outgoing ring on the server.
    ///
    /// Unlike ordinary REST requests, an outgoing ring needs a coordinator
    /// connection so the caller can receive acceptance and rejection events.
    /// This classification limits the connection requirement to ring requests
    /// and preserves disconnected access to other REST and notify operations.
    ///
    /// The generated API passes an encoded request to middleware, rather than
    /// its typed operation. Inspecting that request here keeps the policy out
    /// of generated files, where API regeneration could remove it.
    ///
    /// The supported operations express ringing in three ways:
    /// - Get-call requests use the `ring=true` query parameter.
    /// - Get-or-create and join requests use a top-level `ring` Boolean.
    /// - The explicit ring action always starts ringing.
    ///
    /// Route suffixes allow custom base-path prefixes. Checking the route
    /// shape also distinguishes a call whose ID is `ring` from a ring action.
    /// Only the top-level body flag counts; nested custom data and query
    /// filters must not turn an unrelated request into a ring operation.
    ///
    /// - Parameter request: The request produced by the generated API.
    /// - Returns: Whether a recognized operation requests ringing. Other
    ///   routes, missing flags, and undecodable bodies return `false`.
    private func startsRinging(_ request: Request) -> Bool {
        let path = request.url.pathComponents
        let isCall = path.suffix(4).starts(with: ["video", "call"])
        let isCallAction = path.suffix(5).starts(with: ["video", "call"])

        switch request.method {
        case .get where isCall:
            return request.queryParams.contains { $0.name == "ring" && $0.value == "true" }
        case .post:
            if isCallAction, path.last == "ring" { return true }
            guard isCall || (isCallAction && path.last == "join"),
                  let body = request.body else { return false }
            return (try? JSONDecoder().decode(RingOptions.self, from: body))?.ring == true
        default:
            return false
        }
    }

    private struct RingOptions: Decodable {
        let ring: Bool?
    }
}
