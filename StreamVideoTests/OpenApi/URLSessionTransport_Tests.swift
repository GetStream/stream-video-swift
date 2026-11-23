//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
@preconcurrency import XCTest

final class URLSessionTransport_Tests: XCTestCase, @unchecked Sendable {

    private let token = "header.payload.signature"
    private lazy var logDestination: CapturingLogDestination! = .init()
    private lazy var originalLogDestinations: [LogDestination]! = LogConfig.destinations
    private lazy var subject: URLSessionTransport! = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ForbiddenURLProtocol.self]
        return URLSessionTransport(urlSession: URLSession(configuration: configuration))
    }()

    override func setUp() {
        super.setUp()
        _ = originalLogDestinations
        LogConfig.destinations = [logDestination]
    }

    override func tearDown() {
        LogConfig.destinations = originalLogDestinations
        originalLogDestinations = nil
        logDestination = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - execute(request:)

    func test_execute_requestFails_logsRequestWithoutAuthorizationValue() async throws {
        let request = Request(
            url: try XCTUnwrap(URL(string: "https://example.com/api/v2/video/call/default/123")),
            method: .get,
            queryParams: [],
            headers: ["Authorization": token, "stream-auth-type": "jwt"]
        )

        let url = request.url.absoluteString

        _ = try? await subject.execute(request: request)

        await fulfillment { [logDestination] in
            logDestination?.errorMessages.contains { $0.contains(url) } == true
        }
        let messages = logDestination.errorMessages
        let message = try XCTUnwrap(messages.first { $0.contains(url) })
        XCTAssertTrue(message.contains("stream-auth-type"))
        XCTAssertFalse(messages.contains { $0.contains(token) })
    }
}

// MARK: - Private helpers

/// Answers every request with a non-retried 403 API error.
private final class ForbiddenURLProtocol: URLProtocol, @unchecked Sendable {

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let body = Data(
            """
            {"code":17,"details":[],"duration":"0ms","message":"denied",\
            "more_info":"","StatusCode":403}
            """.utf8
        )
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 403,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private final class CapturingLogDestination: BaseLogDestination, @unchecked Sendable {

    private let lock = NSLock()
    private var _errorMessages: [String] = []

    var errorMessages: [String] {
        lock.lock()
        defer { lock.unlock() }
        return _errorMessages
    }

    convenience init() {
        self.init(
            identifier: UUID().uuidString,
            level: .debug,
            subsystems: .httpRequests,
            showDate: false,
            dateFormatter: DateFormatter(),
            formatters: [],
            showLevel: false,
            showIdentifier: false,
            showThreadName: false,
            showFileName: false,
            showLineNumber: false,
            showFunctionName: false
        )
    }

    override func process(logDetails: LogDetails) {
        guard logDetails.level == .error else { return }
        lock.lock()
        _errorMessages.append(logDetails.message)
        lock.unlock()
    }

    override func write(message: String) {}
}
