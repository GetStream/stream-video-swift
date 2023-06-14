//
//  APIIntegrationTest.swift
//  StreamVideoTests
//
//  Created by tommaso barbugli on 09/06/2023.
//

import Foundation
import XCTest
import Combine
@testable import StreamVideo

class IntegrationTest: XCTestCase {
    public var client: StreamVideo = {
        return StreamVideo(
            apiKey: "hd8szvscpxvd",
            user: User(id: "thierry"),
            token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidGhpZXJyeSJ9._4aZL6BR0VGKfZsKYdscsBm8yKVgG-2LatYeHRJUq0g"
        )
    }()
    
    public override func setUp() async throws {
        try await super.setUp()
        try await client.connect()
    }
    
    func test_call_create_and_update() async throws {
        let call = client.call(callType: "default", callId: UUID().uuidString)

        let response = try await call.create(custom: ["color": "red"])
        XCTAssertEqual(response.call.custom["color"], "red")

        await AssertNext(self, call.newstate.$custom) { v in
            guard let newColor = v["color"]?.stringValue else {
                return false
            }
            return newColor == "red"
        }

        let updateResponse = try await call.update(custom: ["color": "blue"])
        XCTAssertEqual(updateResponse.call.custom["color"], "blue")

        await AssertNext(self, call.newstate.$custom) { v in
            return v["color"] == "blue"
        }
        
        // test errors are good and that we bubble all info
        
        // WS errors
        
        // WS events side-effects test
    }

}

func AssertNext<Output>(_ t: XCTestCase, _ p: some Publisher<Output, Never>, _ assertion: @escaping (Output) -> Bool) async -> Void {
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
    await t.fulfillment(of: [expectation], timeout: 1)
    
    if assertionSucceded {
        return
    }

    XCTFail("unable to fulfill assertion, collected values on the publishers were: \(values)")
}
