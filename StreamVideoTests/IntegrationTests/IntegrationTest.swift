//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import Combine
import XCTest
@testable import StreamVideo

class IntegrationTest: XCTestCase {
    
    static let testApiKey = "hd8szvscpxvd"
    
    public var client: StreamVideo = {
        let userId = "thierry"
        let token = TokenGenerator.shared.fetchToken(for: userId, expiration: 10)!
        return StreamVideo(
            apiKey: testApiKey,
            user: User(id: userId),
            token: token,
            tokenProvider: { _ in }
        )
    }()

    public func getUserClient(id: String) -> StreamVideo {
        let token = TokenGenerator.shared.fetchToken(for: id, expiration: 10)!
        return StreamVideo(
            apiKey: Self.testApiKey,
            user: User(id: id),
            token: token,
            tokenProvider: { _ in }
        )
    }

    public override func setUp() async throws {
    #if compiler(<5.8)
        throw XCTSkip("API tests are flaky on Xcode <14.3 due to async expectation handler in XCTest")
    #else
        try await super.setUp()
        try await client.connect()
    #endif
    }

    // TODO: extract code between these two assertNext methods
    public func assertNext<Output: Sendable>(_ s: AsyncStream<Output>, _ assertion: @Sendable @escaping (Output) -> Bool) async -> Void {
        let expectation = expectation(description: "NextValue")
        expectation.assertForOverFulfill = false

        Task {
            expectation.fulfill()
            for await v in s {
                if assertion(v) {
                    expectation.fulfill()
                    return
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 1)
    }

    public func assertNext<Output>(
        _ p: some Publisher<Output, Never>,
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

        await fulfillment(of: [expectation], timeout: 1)
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
