//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import Combine
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
        try await call.sendCustomEvent(["test": .string("asd")])
        
        let eventSubscriber = call.subscribe()
        await assertNext(eventSubscriber) { ev in
            if case let .typeCustomVideoEvent(data) = ev {
                return data.custom["test"]?.stringValue == "asd"
            }
            return false
        }
        
        let specificSub = call.subscribe(for: CustomVideoEvent.self)
        await assertNext(specificSub) { ev in
            return ev.custom["test"]?.stringValue == "asd"
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
    
    func test_paginate_call_with_members() async throws {
        let call = client.call(callType: "default", callId: UUID().uuidString)
        try await call.create(memberIds: ["thierry"])
        
        let call2 = client.call(callType: call.callType, callId: call.callId)
        let _ = try await call2.get(membersLimit: 0)

        let count = await call2.state.members.count
        XCTAssertEqual(0, count)
        
        let _ = try await call2.get(membersLimit: 1)
        await assertNext(call.state.$members) { v in
            return v.count == 1
        }
        
        var membersResponse = try await call2.queryMembers()
        XCTAssertEqual(1, membersResponse.members.count)
        
        membersResponse = try await call2.queryMembers(filters: ["user_id": .string("thierry")])
        XCTAssertEqual(1, membersResponse.members.count)
        
        membersResponse = try await call2.queryMembers(filters: ["user_id": .string("tommaso")])
        XCTAssertEqual(0, membersResponse.members.count)
        
        let tommasoClient = getUserClient(id: "tommaso")
        try await tommasoClient.connect()
        
        // add to call2 so we can test that the other call object is updated via WS events
        try await call2.addMembers(ids: ["tommaso"])
        await assertNext(call.state.$members) { v in
            return v.count == 2
        }
        
        membersResponse = try await call2.queryMembers(filters: ["user_id": .string("tommaso")])
        XCTAssertEqual(1, membersResponse.members.count)
        
        membersResponse = try await call2.queryMembers(limit:1)
        XCTAssertEqual(1, membersResponse.members.count)
        XCTAssertEqual("tommaso", membersResponse.members.first?.userId)
        
        membersResponse = try await call2.queryMembers(next: membersResponse.next)
        XCTAssertEqual(1, membersResponse.members.count)
        XCTAssertEqual("thierry", membersResponse.members.first?.userId)
        
        await assertNext(call2.state.$members) { v in
            return v.count == 2 && v.first?.id == "tommaso"
        }
    }
    
    func test_query_channels() async throws {
        let call = client.call(callType: "default", callId: UUID().uuidString)
        try await call.create(memberIds: ["thierry"])
        
        let (calls, next) = try await client.queryCalls(filters: ["cid": .string(call.cId)], watch: true)
        XCTAssertEqual(1, calls.count)
        XCTAssertEqual(call.cId, calls[0].cId)
        XCTAssertEqual(nil, next)
        
        // changes to a watched call via query call should propagate as usual to the state
        let updateResponse = try await call.update(custom: ["color": "blue"])
        XCTAssertEqual(updateResponse.call.custom["color"], "blue")
        
        await assertNext(calls[0].state.$custom) { v in
            return v["color"] == "blue"
        }
        
        let (secondTry, _) = try await client.queryCalls(filters: ["ended_at": .nil, "cid": .string(call.cId)])
        XCTAssertEqual(1, secondTry.count)
        XCTAssertEqual(call.cId, calls[0].cId)
        
        try await call.end()
        
        let (thirdTry, _) = try await client.queryCalls(filters: ["ended_at": .nil, "cid": .string(call.cId)])
        XCTAssertEqual(0, thirdTry.count)
        
        // check propagation as well
        await assertNext(calls[0].state.$endedAt) { v in
            return v != nil
        }
    }
    
    func test_send_reaction() async throws {
        let call = client.call(callType: "default", callId: UUID().uuidString)
        try await call.create(memberIds: ["thierry"])
        
        let specificSub = call.subscribe(for: CallReactionEvent.self)
        
        let _ = try await call.sendReaction(type: "happy")
        await assertNext(specificSub) { ev in
            return ev.reaction.type == "happy"
        }
        
        let _ = try await call.sendReaction(type: "happyy", emojiCode: ":smile:")
        await assertNext(specificSub) { ev in
            return ev.reaction.type == "happyy" && ev.reaction.emojiCode == ":smile:"
        }
        
        let _ = try await call.sendReaction(type: "happyyy", custom: ["test": .string("asd")])
        await assertNext(specificSub) { ev in
            return ev.reaction.type == "happyyy" && ev.reaction.custom?["test"]?.stringValue == "asd"
        }
    }
    
    func test_request_permission_discard() async throws {
        let call = client.call(callType: "audio_room", callId: UUID().uuidString)
        try await call.create(memberIds: ["thierry"])

        let tommasoClient = getUserClient(id: "tommaso")
        try await tommasoClient.connect()
        let tommasoCall = tommasoClient.call(callType: "audio_room", callId: call.callId)

        let _ = try await tommasoCall.get()
        var hasAudioCapability = await tommasoCall.currentUserHasCapability(.sendAudio)
        XCTAssertFalse(hasAudioCapability)
        var hasVideoCapability = await tommasoCall.currentUserHasCapability(.sendVideo)
        XCTAssertFalse(hasVideoCapability)

        try await tommasoCall.request(permissions: [.sendVideo, .sendAudio])

        await assertNext(call.state.$permissionRequests) { value in
            return value.count == 2 && value.first?.permission == "send-video"
        }
        if let p = await call.state.permissionRequests.first {
            p.reject()
        }
        
        // Test: send-audio request is the only one listed
        await assertNext(call.state.$permissionRequests) { value in
            return value.first?.permission == "send-audio"
        }
        // Test: tommaso does not have send-audio capabilities
        await assertNext(tommasoCall.state.$ownCapabilities) { value in
            return !value.contains(where: {$0.rawValue == "send-audio"})
        }

        // Then: accept the send-audio request
        if let p = await call.state.permissionRequests.first {
            try await call.grant(request: p)
        }
        // Test: permission requests list is now empty
        await assertNext(call.state.$permissionRequests) { value in
            return value.count == 0
        }
        // Test: tommaso has send-audio capability now
        await assertNext(tommasoCall.state.$ownCapabilities) { value in
            return value.contains(where: {$0.rawValue == "send-audio"})
        }
        
        hasAudioCapability = await tommasoCall.currentUserHasCapability(.sendAudio)
        XCTAssertTrue(hasAudioCapability)
        hasVideoCapability = await tommasoCall.currentUserHasCapability(.sendVideo)
        XCTAssertFalse(hasVideoCapability)
    }
    
    func test_mute_user_by_id() async throws {
        let call = client.call(callType: "audio_room", callId: UUID().uuidString)
        try await call.create(memberIds: ["thierry", "tommaso"])

        // there is no muted event from coordinator atm
        try await call.mute(userId: "tommaso")
    }
    
    func test_mute_user_by_all() async throws {
        let call = client.call(callType: "audio_room", callId: UUID().uuidString)
        try await call.create(memberIds: ["thierry", "tommaso"])

        try await call.muteAllUsers()
        // there is no muted event from coordinator atm
    }
}
