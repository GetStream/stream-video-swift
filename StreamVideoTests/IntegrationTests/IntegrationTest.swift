//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

class IntegrationTest: XCTestCase {
    
    static let testApiKey = "hd8szvscpxvd"
    
    public var client: StreamVideo = {
        let userId = "thierry"
        let token = TokenGenerator.shared.fetchToken(for: userId, expiration: 100) ?? UserToken(rawValue: "")
        return StreamVideo(
            apiKey: testApiKey,
            user: User(id: userId),
            token: token,
            pushNotificationsConfig: .init(
                pushProviderInfo: .init(name: "apn", pushProvider: .apn),
                voipPushProviderInfo: .init(name: "voip", pushProvider: .apn)
            ),
            tokenProvider: {
                _ in
            }
        )
    }()

    public func getUserClient(id: String) -> StreamVideo {
        let token = TokenGenerator.shared.fetchToken(for: id, expiration: 100) ?? UserToken(rawValue: "")
        return StreamVideo(
            apiKey: Self.testApiKey,
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
        try await client.connect()
        #endif
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
        
        await fulfillment(of: [expectation], timeout: seconds)
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

        await fulfillment(of: [expectation], timeout: seconds)
    }
    
    private func fulfillment(
        of expectations: [XCTestExpectation],
        timeout seconds: TimeInterval = .infinity
    ) async {
        #if compiler(>=5.8)
        await super.fulfillment(of: expectations, timeout: seconds)
        #else
        await waitForExpectations(timeout: seconds)
        #endif
    }
}
