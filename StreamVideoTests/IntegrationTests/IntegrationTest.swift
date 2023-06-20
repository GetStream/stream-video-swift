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

    public override func setUp() async throws {
        try await super.setUp()
        try await client.connect()
    }

    public func assertNext<Output>(_ s: AsyncStream<Output>, _ assertion: @escaping (Output) -> Bool) async -> Void {}

    public func assertNext<Output>(_ p: some Publisher<Output, Never>, _ assertion: @escaping (Output) -> Bool) async -> Void {
        let expectation = XCTestExpectation(description: "NextValue")
        var assertionSucceded = false
        var values = [Output]()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }

        var bag = Set<AnyCancellable>()
        defer {
            bag.forEach { $0.cancel() }
        }

        p.sink {
            values.append($0)
            if assertion($0) {
                expectation.fulfill()
                assertionSucceded = true
            }
        }.store(in: &bag)
        await fulfillment(of: [expectation], timeout: 1)

        if assertionSucceded {
            return
        }

        XCTFail("unable to fulfill assertion, collected values on the publishers were: \(values)")
    }
}
