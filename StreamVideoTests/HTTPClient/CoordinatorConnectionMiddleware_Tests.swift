//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class CoordinatorConnectionMiddleware_Tests: XCTestCase, @unchecked Sendable {
    func test_ringRequests_prefixedBasePath_requiresConnectionId() async throws {
        for endpoint in Endpoint.ringing {
            let transport = try RecordingTransport(response: endpoint.response())
            let subject = makeSubject(transport: transport, connectionId: { "" })
            subject.basePath += "/proxy"

            do {
                _ = try await endpoint.execute(on: subject, ring: true)
                XCTFail("A URL prefix must not bypass connection readiness for \(endpoint).")
            } catch {
                XCTAssertTrue(error is ClientError)
            }

            XCTAssertTrue(transport.requests.isEmpty)
        }
    }

    func test_ringRequests_emptyConnectionId_throwClientErrorWithoutSending() async throws {
        for endpoint in Endpoint.ringing {
            let transport = try RecordingTransport(response: endpoint.response())
            var tokenRequests = 0
            let subject = makeSubject(
                transport: transport,
                tokenProvider: {
                    tokenRequests += 1
                    return "user-token"
                },
                connectionId: { "" }
            )

            do {
                _ = try await endpoint.execute(on: subject, ring: true)
                XCTFail("Expected a missing connection id error for \(endpoint)")
            } catch {
                XCTAssertEqual(
                    error as? ClientError,
                    ClientError("Cannot ring a call without a connection id."),
                    "\(endpoint): \(error)"
                )
            }
            XCTAssertTrue(transport.requests.isEmpty, "\(endpoint) must not reach transport")
            XCTAssertEqual(tokenRequests, 0, "\(endpoint) must fail before authentication")
        }
    }

    func test_requests_validConnectionId_sendWithConnectionIdAndAuth() async throws {
        let connectionId = "connection +/&?"
        for endpoint in Endpoint.ringing + [.query] {
            let transport = try RecordingTransport(response: endpoint.response())
            var connectionIdRequests = 0
            let subject = makeSubject(transport: transport) {
                connectionIdRequests += 1
                return connectionId
            }

            let duration = try await endpoint.execute(on: subject, ring: true)

            XCTAssertEqual(duration, "1.0", "\(endpoint)")
            XCTAssertEqual(connectionIdRequests, 1, "\(endpoint) must resolve the connection id once")
            XCTAssertEqual(transport.requests.count, 1, "\(endpoint)")
            let request = try XCTUnwrap(transport.requests.first)
            let query = try XCTUnwrap(URLComponents(url: XCTUnwrap(request.url), resolvingAgainstBaseURL: false))
            XCTAssertEqual(
                query.queryItems?.filter { $0.name == "connection_id" },
                [URLQueryItem(name: "connection_id", value: connectionId)],
                "\(endpoint)"
            )
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "user-token")
            XCTAssertEqual(request.value(forHTTPHeaderField: "stream-auth-type"), "jwt")
        }
    }

    func test_nonRingingRequests_emptyConnectionId_preserveRESTAndNotify() async throws {
        let cases: [(id: String, ring: Bool?, notify: Bool?)] = [
            ("call-id", nil, nil),
            ("call-id", false, nil),
            ("call-id", nil, true),
            ("call-id", false, true),
            ("ring", nil, nil),
            ("ring", false, true)
        ]
        for endpoint in [Endpoint.get, .getOrCreate, .join, .query] {
            for testCase in endpoint == .query ? Array(cases.prefix(1)) : cases {
                let transport = try RecordingTransport(response: endpoint.response())
                let subject = makeSubject(transport: transport, connectionId: { "" })
                let context = "\(endpoint), id: \(testCase.id), ring: \(String(describing: testCase.ring))"

                let duration = try await endpoint.execute(
                    on: subject,
                    id: testCase.id,
                    ring: testCase.ring,
                    notify: testCase.notify
                )

                XCTAssertEqual(duration, "1.0", context)
                XCTAssertEqual(transport.requests.count, 1, context)
                let request = try XCTUnwrap(transport.requests.first)
                let query = try XCTUnwrap(URLComponents(url: XCTUnwrap(request.url), resolvingAgainstBaseURL: false))
                XCTAssertFalse(query.queryItems?.contains { $0.name == "connection_id" } ?? false, context)
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "user-token", context)
                XCTAssertEqual(request.value(forHTTPHeaderField: "stream-auth-type"), "jwt", context)
                if endpoint == .get {
                    XCTAssertEqual(
                        query.queryItems?.first { $0.name == "notify" }?.value,
                        testCase.notify.map { String($0) },
                        context
                    )
                } else if endpoint != .query {
                    let body = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
                    XCTAssertEqual(body["notify"] as? Bool, testCase.notify, context)
                }
            }
        }
    }

    func test_ringRequests_connectionIdProviderThrows_preserveErrorWithoutSending() async throws {
        for endpoint in Endpoint.ringing {
            let transport = try RecordingTransport(response: endpoint.response())
            let subject = makeSubject(transport: transport, connectionId: { throw ProviderError.unavailable })

            do {
                _ = try await endpoint.execute(on: subject, ring: true)
                XCTFail("Expected the provider error for \(endpoint)")
            } catch {
                XCTAssertEqual(error as? ProviderError, .unavailable, "\(endpoint): \(error)")
            }
            XCTAssertTrue(transport.requests.isEmpty, "\(endpoint) must not reach transport")
        }
    }

    func test_ringRequests_cancelledDuringConnectionIdLookup_doNotSend() async throws {
        for endpoint in Endpoint.ringing {
            let transport = try RecordingTransport(response: endpoint.response())
            let subject = makeSubject(transport: transport) {
                withUnsafeCurrentTask { $0?.cancel() }
                return "connection-id"
            }
            let task = Task { try await endpoint.execute(on: subject, ring: true) }

            switch await task.result {
            case .success:
                XCTFail("Expected cancellation for \(endpoint)")
            case let .failure(error):
                XCTAssertTrue(error is CancellationError, "\(endpoint): \(error)")
            }
            XCTAssertTrue(transport.requests.isEmpty, "\(endpoint) must not reach transport")
        }
    }

    private func makeSubject(
        transport: RecordingTransport,
        tokenProvider: @escaping () -> String = { "user-token" },
        connectionId: @escaping () async throws -> String
    ) -> DefaultAPI {
        DefaultAPI(
            basePath: "https://example.invalid",
            transport: transport,
            middlewares: [
                CoordinatorConnectionMiddleware(connectionIdProvider: connectionId),
                UserAuth(tokenProvider: tokenProvider)
            ]
        )
    }
}

private enum ProviderError: Error {
    case unavailable
}

private enum Endpoint: Sendable {
    case get, getOrCreate, join, ring, query

    static let ringing: [Self] = [.get, .getOrCreate, .join, .ring]

    func execute(
        on subject: DefaultAPI,
        id: String = "call-id",
        ring: Bool? = nil,
        notify: Bool? = nil
    ) async throws -> String {
        switch self {
        case .get:
            return try await subject.getCall(
                type: "default", id: id, membersLimit: nil,
                ring: ring, notify: notify, video: nil
            ).duration
        case .getOrCreate:
            return try await subject.getOrCreateCall(
                type: "default", id: id,
                getOrCreateCallRequest: .init(notify: notify, ring: ring)
            ).duration
        case .join:
            return try await subject.joinCall(
                type: "default", id: id,
                joinCallRequest: .init(location: "test", notify: notify, ring: ring)
            ).duration
        case .ring:
            return try await subject.ringCall(
                type: "default", id: id, ringCallRequest: .init()
            ).duration
        case .query:
            return try await subject.queryCalls(queryCallsRequest: .init(filterConditions: ["ring": .bool(true)])).duration
        }
    }

    func response() throws -> Data {
        let builder = MockResponseBuilder()
        let encoder = JSONEncoder.streamCore
        switch self {
        case .get:
            return try encoder.encode(GetCallResponse(
                call: builder.makeCallResponse(cid: "default:call-id"),
                duration: "1.0", members: [], ownCapabilities: []
            ))
        case .getOrCreate:
            return try encoder.encode(GetOrCreateCallResponse(
                call: builder.makeCallResponse(cid: "default:call-id"),
                created: true, duration: "1.0", members: [], ownCapabilities: []
            ))
        case .join:
            return try encoder.encode(builder.makeJoinCallResponse(cid: "default:call-id"))
        case .ring:
            return try encoder.encode(RingCallResponse(duration: "1.0", membersIds: []))
        case .query:
            return try encoder.encode(QueryCallsResponse(calls: [], duration: "1.0"))
        }
    }
}

private final class RecordingTransport: DefaultAPITransport, @unchecked Sendable {
    private(set) var requests: [URLRequest] = []
    private let response: Data

    init(response: Data) {
        self.response = response
    }

    func execute(request: Request) async throws -> (Data, URLResponse) {
        requests.append(try request.urlRequest())
        return (response, HTTPURLResponse(url: request.url, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}
