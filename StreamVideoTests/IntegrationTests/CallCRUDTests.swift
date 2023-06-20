//
// Copyright © 2023 Stream.io Inc. All rights reserved.
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
    
    func test_send_custom_event() async throws {
        let call = client.call(callType: "default", callId: UUID().uuidString)
        try await call.create()
        try await call.send(event: SendEventRequest(custom: ["test": .string("asd")]))

        let eventSubscriber = call.subscribe()
        await assertNext(eventSubscriber) { ev in
            if case let .typeCustomVideoEvent(data) = ev {
                return data.custom["test"]?.stringValue == "asd"
            }
            return false
        }
    }
    
    func test_create_call_with_members() async throws {
        let call = client.call(callType: "default", callId: UUID().uuidString)
        try await call.create(memberIds: ["thierry"])

        await assertNext(call.state.$members) { v in
            return v.count == 1 && v[0].id == "thierry"
        }

        try await call.updateMembers(members: [.init(custom: ["stars" : .number(3)], userId: "thierry")])
        await assertNext(call.state.$members) { v in
            guard let member = v.first else {
                return false
            }
            return member.id == "thierry" && member.customData["stars"]?.numberValue == 3
        }
        
        try await call.removeMembers(ids: ["thierry"])
        await assertNext(call.state.$members) { v in
            return v.count == 0
        }
        
        try await call.addMembers(members: [.init(custom: ["role" : .string("CEO")], userId: "thierry")])
        await assertNext(call.state.$members) { v in
            guard let member = v.first else {
                return false
            }
            return member.id == "thierry" && member.customData["role"]?.stringValue == "CEO"
        }
    }

}
