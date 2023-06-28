//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import Combine
import XCTest
@testable import StreamVideo

class IntegrationTest: XCTestCase {
    // TODO: get credentials from build params and from Github actions when running in CI mode
    public var client: StreamVideo = {
        return StreamVideo(
            apiKey: "hd8szvscpxvd",
            user: User(id: "thierry"),
            token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidGhpZXJyeSJ9._4aZL6BR0VGKfZsKYdscsBm8yKVgG-2LatYeHRJUq0g",
            tokenProvider: { _ in }
        )
    }()

    // TODO: wire this up with utils
    public func getUserClient(id: String) -> StreamVideo {
        return StreamVideo(
            apiKey: "hd8szvscpxvd",
            user: User(id: id),
            token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidG9tbWFzbyJ9.9BvijGcp9ga7AHsqd3pz9PIVSqq4moCVFSDwRnNx3qI",
            tokenProvider: { _ in }
        )
    }

    public override func setUp() async throws {
        try await super.setUp()
        try await client.connect()
        
        /**
         Token generation example
         
         let token = TokenGenerator.shared.fetchToken(for: <#T##String#>, expiration: <#T##Double#>)
         */
    }

    // TODO: extract code between these two assertNext methods
    public func assertNext<Output: Sendable>(_ s: AsyncStream<Output>, _ assertion: @Sendable @escaping (Output) -> Bool) async -> Void {
        let expectation = XCTestExpectation(description: "NextValue")

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
        _ assertion: @escaping (Output) -> Bool
    ) async -> Void {
        let nextValueExpectation = expectation(description: "NextValue")
        var values = [Output]()
        var bag = Set<AnyCancellable>()
        defer { bag.forEach { $0.cancel() } }

        p.sink {
            values.append($0)
            if assertion($0) {
                nextValueExpectation.fulfill()
            }
        }.store(in: &bag)

    #if compiler(>=5.8)
        await fulfillment(of: [nextValueExpectation], timeout: 1)
    #else
        wait(for: [nextValueExpectation], timeout: 1)
    #endif
    }
}
