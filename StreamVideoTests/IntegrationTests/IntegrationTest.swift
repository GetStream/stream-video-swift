//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

class IntegrationTest: XCTestCase {

    private var apiKey: String! = ""
    private var userId: String! = "thierry"
    private var baseURL: URL! = .init(string: "https://pronto.getstream.io/api/auth/create-token")!
    private var authenticationProvider: TestsAuthenticationProvider! = .init()
    private(set) var client: StreamVideo!

    // MARK: - Lifecycle

    override func setUp() async throws {
        #if compiler(<5.8)
        throw XCTSkip("API tests are flaky on Xcode <14.3 due to async expectation handler in XCTest")
        #else
        try await super.setUp()
        client = try await makeClient(for: userId)
        #endif
    }

    override func tearDown() {
        apiKey = nil
        userId = nil
        baseURL = nil
        authenticationProvider = nil
        client = nil
        super.tearDown()
    }

    // MARK: - Helpers

    func makeClient(
        for userId: String,
        environment: String = "demo"
    ) async throws -> StreamVideo {
        let tokenResponse = try await authenticationProvider.authenticate(
            environment: environment,
            baseURL: baseURL,
            userId: userId
        )
        let client = StreamVideo(
            apiKey: tokenResponse.apiKey,
            user: User(id: userId),
            token: .init(rawValue: tokenResponse.token),
            pushNotificationsConfig: .init(
                pushProviderInfo: .init(name: "ios-apn", pushProvider: .apn),
                voipPushProviderInfo: .init(name: "ios-voip", pushProvider: .apn)
            ),
            tokenProvider: { _ in }
        )
        try await client.connect()
        return client
    }

    func refreshStreamVideoProviderKey() {
        StreamVideoProviderKey.currentValue = client
    }

    // TODO: extract code between these two assertNext methods
    func assertNext<Output: Sendable>(
        _ s: AsyncStream<Output>,
        timeout seconds: TimeInterval = 1,
        _ assertion: @Sendable @escaping (Output) -> Bool
    ) async -> Void {
        let expectation = expectation(description: "NextValue")
        expectation.assertForOverFulfill = false

        Task {
            for await v in s {
                if assertion(v) {
                    expectation.fulfill()
                    return
                }
            }
        }

        await safeFulfillment(of: [expectation], timeout: seconds)
    }

    func assertNext<Output>(
        _ p: some Publisher<Output, Never>,
        timeout seconds: TimeInterval = 1,
        _ assertion: @escaping (Output) -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) async -> Void {
        let expectation = expectation(description: "NextValue")
        expectation.assertForOverFulfill = false

        var values = [Output]()
        var bag = Set<AnyCancellable>()
        defer { bag.forEach { $0.cancel() } }

        p.sink {
            values.append($0)
            if assertion($0) {
                expectation.fulfill()
            }
        }.store(in: &bag)

        await safeFulfillment(of: [expectation], timeout: seconds)
    }
}

private extension URL {

    var isWeb: Bool { scheme == "http" || scheme == "https" }

    var queryParameters: [String: String] {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return [:] }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }

    func addQueryParameter(_ key: String, value: String?) -> URL {
        if #available(iOS 16.0, *) {
            return appending(queryItems: [.init(name: key, value: value)])
        } else {
            guard
                var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
            else {
                return self
            }

            var queryItems: [URLQueryItem] = components.queryItems ?? []
            queryItems.append(.init(name: key, value: value))
            components.queryItems = queryItems

            return components.url ?? self
        }
    }

    func appending(_ queryItem: URLQueryItem) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        components.queryItems = (components.queryItems ?? []) + [queryItem]

        return components.url ?? self
    }

    var host: String? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?.host
    }
}

private final class TestsAuthenticationProvider {
    struct TokenResponse: Codable {
        var userId: String
        var token: String
        var apiKey: String
    }

    func authenticate(
        environment: String,
        baseURL: URL,
        userId: String,
        callIds: [String] = [],
        expirationIn: Int = 0
    ) async throws -> TokenResponse {
        var url = baseURL
            .appending(.init(name: "user_id", value: userId))
            .appending(.init(name: "environment", value: environment))

        if !callIds.isEmpty {
            url = url.appending(
                URLQueryItem(
                    name: "call_cids",
                    value: callIds.joined(separator: ",")
                )
            )
        }

        if expirationIn > 0 {
            url = url.appending(
                URLQueryItem(
                    name: "exp",
                    value: "\(expirationIn)"
                )
            )
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }
}
