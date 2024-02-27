//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

class IntegrationTest: XCTestCase {

    private var environment = "demo"
    private var apiKey: String = ""
    private lazy var userId = "thierry"

    public lazy var client: StreamVideo = {
        let token = TokenGenerator.shared.fetchToken(for: userId, expiration: 100) ?? UserToken(rawValue: "")
        return StreamVideo(
            apiKey: apiKey,
            user: User(id: userId),
            token: token,
            pushNotificationsConfig: .init(
                pushProviderInfo: .init(name: "ios-apn", pushProvider: .apn),
                voipPushProviderInfo: .init(name: "ios-voip", pushProvider: .apn)
            ),
            tokenProvider: {
                _ in
            }
        )
    }()

    public func getUserClient(id: String) async throws -> StreamVideo {
        apiKey = try await fetchApiKey(userId: userId)
        let token = TokenGenerator.shared.fetchToken(
            for: id,
            expiration: 100
        ) ?? UserToken(rawValue: "")
        return StreamVideo(
            apiKey: apiKey,
            user: User(id: id),
            token: token,
            pushNotificationsConfig: .init(
                pushProviderInfo: .init(name: "apn", pushProvider: .apn),
                voipPushProviderInfo: .init(name: "voip", pushProvider: .apn)
            ),
            tokenProvider: { _ in }
        )
    }
    
    public func refreshStreamVideoProviderKey() {
        StreamVideoProviderKey.currentValue = client
    }

    override public func setUp() async throws {
        #if compiler(<5.8)
        throw XCTSkip("API tests are flaky on Xcode <14.3 due to async expectation handler in XCTest")
        #else
        try await super.setUp()
        apiKey = try await fetchApiKey(userId: userId)
        try await client.connect()
        #endif
    }

    private func fetchApiKey(
        userId: String
    ) async throws -> String {
        let url = URL(string: "https://pronto.getstream.io/api/auth/create-token")!
            .appending(.init(name: "user_id", value: userId))
            .appending(.init(name: "environment", value: environment))

        let (data, _) = try await URLSession.shared.data(from: url)
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        return tokenResponse.apiKey
    }

    // TODO: extract code between these two assertNext methods
    public func assertNext<Output: Sendable>(
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

    public func assertNext<Output>(
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

private struct TokenResponse: Codable {
    let userId: String
    let token: String
    let apiKey: String
}
