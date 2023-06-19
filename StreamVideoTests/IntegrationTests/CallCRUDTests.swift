//
//  CallCRUDTests.swift
//  StreamVideoTests
//
//  Created by tommaso barbugli on 19/06/2023.
//

import Foundation
import Combine
import XCTest
@testable import StreamVideo

class CallCRUDTest: IntegrationTest {
    func test_call_create_and_update() async throws {
        let call = client.call(callType: "default", callId: UUID().uuidString)
        
        let response = try await call.create(custom: ["color": "red"])
        XCTAssertEqual(response.custom["color"], "red")
        
        await assertNext(call.state.$custom) { v in
            guard let newColor = v["color"]?.stringValue else {
                return false
            }
            return newColor == "red"
        }
        
        let updateResponse = try await call.update(custom: ["color": "blue"])
        XCTAssertEqual(updateResponse.call.custom["color"], "blue")
        
        await assertNext(call.state.$custom) { v in
            return v["color"] == "blue"
        }
    }

    func test_get_call_missing_id() async throws {
        let call = client.call(callType: "default", callId: UUID().uuidString)
        let apiErr = await XCTAssertThrowsErrorAsync({
            let _ = try await call.get()
            return
        })
        guard let apiErr = apiErr as? APIError else {
            XCTAssert((apiErr as Any) is APIError)
            return
        }
        XCTAssertEqual(apiErr.code, 16)
        XCTAssertEqual(apiErr.message, "GetCall failed with error: \"Can't find call with id \(call.cId)\"")
    }

    func test_get_call_wrong_type() async throws {
        let call = client.call(callType: "bananas", callId: UUID().uuidString)
        let apiErr = await XCTAssertThrowsErrorAsync({
            let _ = try await call.get()
            return
        })
        guard let apiErr = apiErr as? APIError else {
            XCTAssert((apiErr as Any) is APIError)
            return
        }
        XCTAssertEqual(apiErr.code, 16)
        XCTAssertTrue(apiErr.message.localizedStandardContains("call type does not exist"))
    }

}

