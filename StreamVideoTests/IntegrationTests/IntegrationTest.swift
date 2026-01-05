//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

class IntegrationTest: XCTestCase, @unchecked Sendable {

    private nonisolated(unsafe) static var videoConfig: VideoConfig! = .dummy()

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

        // We configure the production timeouts as we hit real endpoints
        WebRTCConfiguration.timeout = WebRTCConfiguration.Timeout.production
        CallConfiguration.timeout = CallConfiguration.Timeout.production
    }

    override class func tearDown() {
        Self.videoConfig = nil
        super.tearDown()
    }

    override func tearDown() {
        apiKey = nil
        userId = nil
        baseURL = nil
        authenticationProvider = nil
        client = nil

        #if STREAM_TESTS
        WebRTCConfiguration.timeout = WebRTCConfiguration.Timeout.testing
        CallConfiguration.timeout = CallConfiguration.Timeout.testing
        #endif

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
            videoConfig: Self.videoConfig,
            pushNotificationsConfig: .init(
                pushProviderInfo: .init(name: "ios-apn", pushProvider: .apn),
                voipPushProviderInfo: .init(name: "ios-voip", pushProvider: .apn)
            ),
            tokenProvider: { _ in },
            autoConnectOnInit: false
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
