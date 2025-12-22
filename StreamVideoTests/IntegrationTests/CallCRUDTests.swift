//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@preconcurrency import Combine
import Foundation
@testable import StreamVideo
import XCTest

// final class CallCRUDTests: IntegrationTest, @unchecked Sendable {
//
//    let user1 = "thierry"
//    let user2 = "tommaso"
//    let defaultCallType = "default"
//    let apiErrorCode = 16
//    let randomCallId = UUID().uuidString
//    let userIdKey = MemberRequest.CodingKeys.userId.rawValue
//
//    func customWait(nanoseconds duration: UInt64 = 3_000_000_000) async throws {
//        try await Task.sleep(nanoseconds: duration)
//    }
//
//    func waitForCapability(
//        _ capability: OwnCapability,
//        on call: Call,
//        granted: Bool = true,
//        timeout: Double = 20
//    ) async -> Bool {
//        let endTime = Date().timeIntervalSince1970 * 1000 + timeout * 1000
//        var userHasRequiredCapability = !granted
//        while userHasRequiredCapability != granted && endTime > Date().timeIntervalSince1970 * 1000 {
//            print("Waiting for \(capability.rawValue)")
//            userHasRequiredCapability = await call.currentUserHasCapability(capability)
//        }
//        return userHasRequiredCapability
//    }
//
//    func waitForAudio(
//        on call: Call,
//        timeout: Double = 20
//    ) async -> Bool {
//        let endTime = Date().timeIntervalSince1970 * 1000 + timeout * 1000
//        var usersHaveAudio = false
//        while !usersHaveAudio && endTime > Date().timeIntervalSince1970 * 1000 {
//            print("Waiting for Audio")
//            let u1 = await call.state.participants.first!.hasAudio
//            let u2 = await call.state.participants.last!.hasAudio
//            usersHaveAudio = u1 && u2
//        }
//        return usersHaveAudio
//    }
//
//    func waitForAudioLoss(
//        on call: Call,
//        timeout: Double = 20
//    ) async -> Bool {
//        let endTime = Date().timeIntervalSince1970 * 1000 + timeout * 1000
//        var usersLostAudio = false
//        while !usersLostAudio && endTime > Date().timeIntervalSince1970 * 1000 {
//            print("Waiting for Audio Loss")
//            let u1 = await call.state.participants.first!.hasAudio
//            let u2 = await call.state.participants.last!.hasAudio
//            usersLostAudio = u1 == false && u2 == false
//        }
//        return usersLostAudio
//    }
//
//    func waitForPinning(
//        firstUserCall: Call,
//        secondUserCall: Call,
//        timeout: Double = 20
//    ) async {
//        let endTime = Date().timeIntervalSince1970 * 1000 + timeout * 1000
//        var userIsPinned = false
//        while !userIsPinned && endTime > Date().timeIntervalSince1970 * 1000 {
//            print("Waiting for Pinning")
//            let pin = await firstUserCall.state.participantsMap[secondUserCall.state.sessionId]?.pin
//            userIsPinned = pin != nil
//        }
//    }
//
//    func waitForUnpinning(
//        firstUserCall: Call,
//        secondUserCall: Call,
//        timeout: Double = 20
//    ) async {
//        let endTime = Date().timeIntervalSince1970 * 1000 + timeout * 1000
//        var userIsUnpinned = false
//        while !userIsUnpinned && endTime > Date().timeIntervalSince1970 * 1000 {
//            print("Waiting for Unpinning")
//            let pin = await firstUserCall.state.participantsMap[secondUserCall.state.sessionId]?.pin
//            userIsUnpinned = pin == nil
//        }
//    }
//
//    func test_callCreateAndUpdate() async throws {
//        let colorKey = "color"
//        let red: RawJSON = "red"
//        let blue: RawJSON = "blue"
//
//        let call = client.call(callType: defaultCallType, callId: randomCallId)
//
//        let response = try await call.create(custom: [colorKey: red])
//        XCTAssertEqual(response.custom[colorKey], red)
//
//        await assertNext(call.state.$custom) { v in
//            guard let newColor = v[colorKey]?.stringValue else {
//                return false
//            }
//            return newColor == red.stringValue
//        }
//
//        let updateResponse = try await call.update(custom: [colorKey: blue])
//        XCTAssertEqual(updateResponse.call.custom[colorKey], blue)
//
//        await assertNext(call.state.$custom) { v in
//            v[colorKey] == blue
//        }
//    }
//
//    func test_getCallMissingId() async throws {
//        let call = client.call(callType: defaultCallType, callId: randomCallId)
//        let apiErr = await XCTAssertThrowsErrorAsync {
//            _ = try await call.get()
//        }
//        guard let apiErr = apiErr as? APIError else {
//            XCTAssert((apiErr as Any) is APIError)
//            return
//        }
//        XCTAssertEqual(apiErr.code, apiErrorCode)
//
//        let expectedErrMessage = "GetCall failed with error: \"Can't find call with id \(call.cId)\""
//        XCTAssertEqual(apiErr.message, expectedErrMessage)
//    }
//
//    func test_getCallWrongType() async throws {
//        let wrongCallType = "bananas"
//        let call = client.call(callType: wrongCallType, callId: randomCallId)
//        let apiErr = await XCTAssertThrowsErrorAsync {
//            _ = try await call.get()
//            return
//        }
//        guard let apiErr = apiErr as? APIError else {
//            XCTAssert((apiErr as Any) is APIError)
//            return
//        }
//        XCTAssertEqual(apiErr.code, apiErrorCode)
//
//        let expectedErrMessage = "\(wrongCallType): call type does not exist"
//        XCTAssertTrue(apiErr.message.localizedStandardContains(expectedErrMessage))
//    }
//
//    func test_sendCustomEvent() async throws {
//        let customEventKey = "test"
//        let customEventValue = "asd"
//
//        let call = client.call(callType: defaultCallType, callId: randomCallId)
//        try await call.create()
//
//        let subscription = call.subscribe(for: CustomVideoEvent.self)
//        try await call.sendCustomEvent([customEventKey: .string(customEventValue)])
//
//        await assertNext(subscription) { ev in
//            ev.custom[customEventKey]?.stringValue == customEventValue
//        }
//    }
//
//    func test_createCallWithMembers() async throws {
//        let roleKey = "role"
//        let roleValue = "CEO"
//        let membersGroup = "stars"
//        let membersCount: Double = 3
//
//        let call = client.call(callType: defaultCallType, callId: randomCallId)
//        try await call.create(memberIds: [user1])
//
//        await assertNext(call.state.$members) { v in
//            v.count == 1 && v[0].id == self.user1
//        }
//
//        try await call
//            .updateMembers(
//                members: [
//                    .init(
//                        custom: [
//                            membersGroup: .number(membersCount)
//                        ], userId: user1
//                    )
//                ]
//            )
//
//        await fulfilmentInMainActor {
//            if let member = call.state.members.first {
//                return member.id == self.user1
//                    && member.customData[membersGroup]?.numberValue == membersCount
//            } else {
//                return false
//            }
//        }
//
//        try await call.removeMembers(ids: [user1])
//
//        await fulfilmentInMainActor { call.state.members.isEmpty }
//
//        try await call.addMembers(
//            members: [
//                .init(
//                    custom: [roleKey: .string(roleValue)],
//                    userId: user1
//                )
//            ]
//        )
//
//        await fulfilmentInMainActor {
//            if let member = call.state.members.first {
//                return member.id == self.user1
//                    && member.customData[roleKey]?.stringValue == roleValue
//            } else {
//                return false
//            }
//        }
//    }
//
//    func test_paginateCallWithMembers() async throws {
//        let call1 = client.call(callType: defaultCallType, callId: randomCallId)
//        try await call1.create(memberIds: [user1])
//
//        let call2 = client.call(callType: call1.callType, callId: call1.callId)
//        _ = try await call2.get(membersLimit: 1)
//
//        await fulfilmentInMainActor { call1.state.members.count == 1 }
//
//        var membersResponse = try await call2.queryMembers()
//        XCTAssertEqual(1, membersResponse.members.count)
//
//        membersResponse = try await call2.queryMembers(filters: [userIdKey: .string(user1)])
//        XCTAssertEqual(1, membersResponse.members.count)
//
//        membersResponse = try await call2.queryMembers(filters: [userIdKey: .string(user2)])
//        XCTAssertEqual(0, membersResponse.members.count)
//
//        let secondUserClient = try await makeClient(for: user2)
//        try await secondUserClient.connect()
//
//        // add to call2 so we can test that the other call object is updated via WS events
//        try await call2.addMembers(ids: [user2])
//        await fulfilmentInMainActor { call1.state.members.count == 2 }
//
//        membersResponse = try await call2.queryMembers(filters: [userIdKey: .string(user2)])
//        XCTAssertEqual(1, membersResponse.members.count)
//
//        membersResponse = try await call2.queryMembers(limit: 1)
//        XCTAssertEqual(1, membersResponse.members.count)
//        XCTAssertEqual(user2, membersResponse.members.first?.userId)
//
//        membersResponse = try await call2.queryMembers(next: membersResponse.next)
//        XCTAssertEqual(1, membersResponse.members.count)
//        XCTAssertEqual(user1, membersResponse.members.first?.userId)
//
//        await fulfilmentInMainActor {
//            call2.state.members.count == 2
//                && call2.state.members.first?.id == self.user2
//        }
//    }
//
//    @MainActor
//    func test_queryChannels() async throws {
//        let colorKey = "color"
//        let blue: RawJSON = "blue"
//
//        let call = client.call(callType: defaultCallType, callId: randomCallId)
//        try await call.create(memberIds: [user1])
//
//        let (calls, _) = try await client.queryCalls(
//            filters: [CallSortField.cid.rawValue: .string(call.cId)],
//            watch: true
//        )
//        XCTAssertEqual(1, calls.count)
//        var fetchedCall = try XCTUnwrap(calls.first)
//        XCTAssertEqual(call.cId, fetchedCall.cId)
//
//        // changes to a watched call via query call should propagate as usual to the state
//        let updateResponse = try await call.update(custom: [colorKey: blue])
//        XCTAssertEqual(updateResponse.call.custom[colorKey], blue)
//
//        await fulfilmentInMainActor { fetchedCall.state.custom[colorKey] == blue }
//
//        let (secondTry, _) = try await client.queryCalls(
//            filters: [
//                CallSortField.endedAt.rawValue: .nil,
//                CallSortField.cid.rawValue: .string(call.cId)
//            ]
//        )
//        XCTAssertEqual(1, secondTry.count)
//        fetchedCall = try XCTUnwrap(secondTry.first)
//        XCTAssertEqual(call.cId, fetchedCall.cId)
//
//        try await call.end()
//
//        let (thirdTry, _) = try await client.queryCalls(
//            filters: [
//                CallSortField.endedAt.rawValue: .nil,
//                CallSortField.cid.rawValue: .string(call.cId)
//            ]
//        )
//        XCTAssertEqual(0, thirdTry.count)
//
//        await fulfilmentInMainActor { fetchedCall.state.endedAt != nil }
//    }
//
//    func test_sendReaction() async throws {
//        let reactionType1 = "happy"
//        let reactionType2 = "happyy"
//        let reactionType3 = "happyyy"
//        let emojiCode = ":smile:"
//        let customReactionKey = "test"
//        let customReactionValue = "asd"
//
//        let call = client.call(callType: defaultCallType, callId: randomCallId)
//        try await call.create(memberIds: [user1])
//
//        let specificSub = call.subscribe(for: CallReactionEvent.self)
//
//        _ = try await call.sendReaction(type: reactionType1)
//
//        await assertNext(specificSub) { ev in
//            ev.reaction.type == reactionType1
//        }
//
//        _ = try await call.sendReaction(type: reactionType2, emojiCode: emojiCode)
//        await assertNext(specificSub) { ev in
//            ev.reaction.type == reactionType2 && ev.reaction.emojiCode == emojiCode
//        }
//
//        _ = try await call.sendReaction(
//            type: reactionType3,
//            custom: [customReactionKey: .string(customReactionValue)]
//        )
//        await assertNext(specificSub) { ev in
//            ev.reaction.type == reactionType3 && ev.reaction.custom?[customReactionKey]?.stringValue == customReactionValue
//        }
//    }
//
//    func test_requestPermissionDiscard() async throws {
//        let firstUserCall = client.call(
//            callType: String.audioRoom,
//            callId: randomCallId
//        )
//        try await firstUserCall.create(memberIds: [user1])
//
//        let secondUserClient = try await makeClient(for: user2)
//        try await secondUserClient.connect()
//        let secondUserCall = secondUserClient.call(
//            callType: String.audioRoom,
//            callId: firstUserCall.callId
//        )
//
//        _ = try await secondUserCall.get()
//        var hasAudioCapability = await secondUserCall.currentUserHasCapability(.sendAudio)
//        XCTAssertFalse(hasAudioCapability)
//        var hasVideoCapability = await secondUserCall.currentUserHasCapability(.sendVideo)
//        XCTAssertFalse(hasVideoCapability)
//
//        try await secondUserCall.request(permissions: [.sendAudio])
//
//        await assertNext(firstUserCall.state.$permissionRequests) { value in
//            value.count == 1 && value.first?.permission == Permission.sendAudio.rawValue
//        }
//        if let p = await firstUserCall.state.permissionRequests.first {
//            p.reject()
//        }
//
//        // Test: permission requests list is now empty
//        await assertNext(firstUserCall.state.$permissionRequests) { value in
//            value.isEmpty
//        }
//
//        hasAudioCapability = await secondUserCall.currentUserHasCapability(.sendAudio)
//        XCTAssertFalse(hasAudioCapability)
//        hasVideoCapability = await secondUserCall.currentUserHasCapability(.sendVideo)
//        XCTAssertFalse(hasVideoCapability)
//    }
//
//    func test_muteUserById() async throws {
//        throw XCTSkip("https://github.com/GetStream/ios-issues-tracking/issues/541")
//
//        let firstUserCall = client.call(callType: String.audioRoom, callId: randomCallId)
//        try await firstUserCall.create(memberIds: [user1, user2])
//        try await firstUserCall.goLive()
//
//        let secondUserClient = try await makeClient(for: user2)
//        let secondUserCall = secondUserClient.call(
//            callType: String.audioRoom,
//            callId: firstUserCall.callId
//        )
//
//        try await firstUserCall.join()
//        try await customWait()
//
//        try await firstUserCall.microphone.enable()
//        try await customWait()
//
//        try await secondUserCall.join()
//        try await customWait()
//
//        try await firstUserCall.grant(permissions: [.sendAudio], for: user2)
//        try await customWait()
//
//        try await secondUserCall.microphone.enable()
//        try await customWait()
//
//        let everyoneIsUnmutedOnTheFirstCall = await waitForAudio(on: firstUserCall)
//        let everyoneIsUnmutedOnTheSecondCall = await waitForAudio(on: secondUserCall)
//        XCTAssertTrue(everyoneIsUnmutedOnTheFirstCall, "Everyone should be unmuted on creator's call")
//        XCTAssertTrue(everyoneIsUnmutedOnTheSecondCall, "Everyone should be unmuted on participant's call")
//
//        for userId in [user1, user2] {
//            try await firstUserCall.mute(userId: userId)
//        }
//        try await customWait()
//
//        let everyoneIsMutedOnTheFirstCall = await waitForAudioLoss(on: firstUserCall)
//        let everyoneIsMutedOnTheSecondCall = await waitForAudioLoss(on: secondUserCall)
//        XCTAssertTrue(everyoneIsMutedOnTheFirstCall, "Everyone should be muted on creator's call")
//        XCTAssertTrue(everyoneIsMutedOnTheSecondCall, "Everyone should be muted on participant's call")
//    }
//
//    func test_muteAllUsers() async throws {
//        throw XCTSkip("https://github.com/GetStream/ios-issues-tracking/issues/541")
//
//        let firstUserCall = client.call(callType: String.audioRoom, callId: randomCallId)
//        try await firstUserCall.create(memberIds: [user1, user2])
//        try await firstUserCall.goLive()
//
//        let secondUserClient = try await makeClient(for: user2)
//        let secondUserCall = secondUserClient.call(
//            callType: String.audioRoom,
//            callId: firstUserCall.callId
//        )
//
//        try await firstUserCall.join()
//        try await customWait()
//
//        try await firstUserCall.microphone.enable()
//        try await customWait()
//
//        try await secondUserCall.join()
//        try await customWait()
//
//        try await firstUserCall.grant(permissions: [.sendAudio], for: user2)
//        try await customWait()
//
//        try await secondUserCall.microphone.enable()
//        try await customWait()
//
//        let everyoneIsUnmutedOnTheFirstCall = await waitForAudio(on: firstUserCall)
//        let everyoneIsUnmutedOnTheSecondCall = await waitForAudio(on: secondUserCall)
//        XCTAssertTrue(everyoneIsUnmutedOnTheFirstCall, "Everyone should be unmuted on creator's call")
//        XCTAssertTrue(everyoneIsUnmutedOnTheSecondCall, "Everyone should be unmuted on participant's call")
//
//        try await firstUserCall.muteAllUsers()
//        try await customWait()
//
//        let everyoneIsMutedOnTheFirstCall = await waitForAudioLoss(on: firstUserCall)
//        let everyoneIsMutedOnTheSecondCall = await waitForAudioLoss(on: secondUserCall)
//        XCTAssertTrue(everyoneIsMutedOnTheFirstCall, "Everyone should be muted on creator's call")
//        XCTAssertTrue(everyoneIsMutedOnTheSecondCall, "Everyone should be muted on participant's call")
//    }
//
//    func test_blockAndUnblockUser() async throws {
//        let call = client.call(callType: defaultCallType, callId: randomCallId)
//        try await call.create(memberIds: [user1, user2])
//        try await call.blockUser(with: user2)
//
//        var membersResponse = try await call.queryMembers()
//        XCTAssertEqual(2, membersResponse.members.count)
//
//        var blockedUsers = try await call.get().call.blockedUserIds
//        XCTAssertEqual(blockedUsers, [user2])
//
//        try await call.unblockUser(with: user2)
//
//        membersResponse = try await call.queryMembers()
//        XCTAssertEqual(2, membersResponse.members.count)
//
//        blockedUsers = try await call.get().call.blockedUserIds
//        XCTAssertEqual(blockedUsers, [])
//    }
//
//    func test_createCallWithMembersAndMemberIds() async throws {
//        let call = client.call(callType: defaultCallType, callId: randomCallId)
//
//        var membersRequest = [MemberRequest]()
//        membersRequest.append(.init(userId: user2))
//
//        try await call.create(members: membersRequest, memberIds: [user1])
//        let membersResponse = try await call.queryMembers()
//
//        XCTAssertEqual(2, membersResponse.members.count)
//    }
//
//    func test_grantPermissions() async throws {
//        throw XCTSkip("https://github.com/GetStream/ios-issues-tracking/issues/541")
//
//        let call = client.call(callType: defaultCallType, callId: randomCallId)
//        try await call.create(memberIds: [user1])
//
//        let expectedPermissions: [Permission] = [.sendAudio, .sendVideo, .screenshare]
//        try await call.revoke(permissions: expectedPermissions, for: user1)
//
//        for permission in expectedPermissions {
//            let capability = try XCTUnwrap(OwnCapability(rawValue: permission.rawValue))
//            let userHasRequiredCapability = await waitForCapability(capability, on: call, granted: false)
//            XCTAssertFalse(userHasRequiredCapability, "\(permission.rawValue) should not be granted")
//        }
//
//        try await call.grant(permissions: expectedPermissions, for: user1)
//
//        for permission in expectedPermissions {
//            let capability = try XCTUnwrap(OwnCapability(rawValue: permission.rawValue))
//            let userHasRequiredCapability = await waitForCapability(capability, on: call)
//            XCTAssertTrue(userHasRequiredCapability, "\(permission.rawValue) permission should be granted")
//        }
//    }
//
//    func test_grantPermissionsByRequest() async throws {
//        throw XCTSkip("https://github.com/GetStream/ios-issues-tracking/issues/541")
//
//        let firstUserCall = client.call(callType: String.audioRoom, callId: randomCallId)
//        try await firstUserCall.create(memberIds: [user1, user2])
//
//        let secondUserClient = try await makeClient(for: user2)
//        let secondUserCall = secondUserClient.call(
//            callType: firstUserCall.callType,
//            callId: firstUserCall.callId
//        )
//
//        refreshStreamVideoProviderKey()
//
//        try await firstUserCall.revoke(permissions: [.sendAudio], for: secondUserClient.user.id)
//
//        var userHasUnexpectedCapability = await waitForCapability(.sendAudio, on: secondUserCall, granted: false)
//        XCTAssertFalse(userHasUnexpectedCapability)
//
//        try await secondUserCall.request(permissions: [.sendAudio])
//
//        userHasUnexpectedCapability = await waitForCapability(.sendAudio, on: secondUserCall, granted: false)
//        XCTAssertFalse(userHasUnexpectedCapability)
//
//        await assertNext(firstUserCall.state.$permissionRequests) { value in
//            value.count == 1 && value.first?.permission == Permission.sendAudio.rawValue
//        }
//        if let p = await firstUserCall.state.permissionRequests.first {
//            try await firstUserCall.grant(request: p)
//        }
//
//        let userHasExpectedCapability = await waitForCapability(.sendAudio, on: secondUserCall)
//        XCTAssertTrue(userHasExpectedCapability)
//    }
//
//    func test_acceptCall() async throws {
//        try await client.connect()
//        let call = client.call(callType: defaultCallType, callId: randomCallId)
//        try await call.create(memberIds: [user1])
//        try await call.ring()
//        try await customWait()
//
//        var session = try await call.get().call.session
//        XCTAssertEqual(session?.acceptedBy.isEmpty, true, "Call should not be accepted yet")
//
//        try await call.accept()
//        try await customWait()
//
//        session = try await call.get().call.session
//        XCTAssertNotNil(session?.acceptedBy[client.user.id], "Call should be accepted by \(user1)")
//    }
//
//    func test_notifyUser() async throws {
//        let call = client.call(callType: defaultCallType, callId: randomCallId)
//        try await call.create(memberIds: [user1, user2])
//
//        let subscription = call.subscribe(for: CallNotificationEvent.self)
//
//        try await call.notify()
//        try await customWait()
//
//        await assertNext(subscription) { [user2] ev in
//            ev.members.first?.userId == user2
//        }
//    }
//
//    func test_setAndDeleteDevices() async throws {
//        let deviceId = UUID().uuidString
//        let voipDeviceId = UUID().uuidString
//        let call = client.call(callType: defaultCallType, callId: randomCallId)
//        try await call.create(memberIds: [user1, user2])
//
//        try await call.streamVideo.setDevice(id: deviceId)
//        try await call.streamVideo.setVoipDevice(id: voipDeviceId)
//        try await customWait()
//        var listDevices = try await call.streamVideo.listDevices()
//        XCTAssertTrue(listDevices.contains(where: { $0.id == deviceId }), "Device should be added")
//        XCTAssertTrue(listDevices.contains(where: { $0.id == voipDeviceId }), "Voip device should be added")
//
//        try await call.streamVideo.deleteDevice(id: deviceId)
//        try await call.streamVideo.deleteDevice(id: voipDeviceId)
//        try await customWait()
//        listDevices = try await call.streamVideo.listDevices()
//        XCTAssertFalse(listDevices.contains(where: { $0.id == deviceId }), "Device should be removed")
//        XCTAssertFalse(listDevices.contains(where: { $0.id == voipDeviceId }), "Voip device should be removed")
//    }
//
//    func test_setAndDeleteVoipDevices() async throws {
//        throw XCTSkip("https://github.com/GetStream/ios-issues-tracking/issues/541")
//
//        let deviceId = UUID().uuidString
//        let call = client.call(callType: defaultCallType, callId: randomCallId)
//        try await call.create(memberIds: [user1, user2])
//
//        try await call.streamVideo.setVoipDevice(id: deviceId)
//        try await customWait()
//        var listDevices = try await call.streamVideo.listDevices()
//        XCTAssertTrue(listDevices.contains(where: { $0.id == deviceId }))
//
//        try await call.streamVideo.deleteDevice(id: deviceId)
//        try await customWait()
//        listDevices = try await call.streamVideo.listDevices()
//        XCTAssertFalse(listDevices.contains(where: { $0.id == deviceId }))
//    }
//
//    func test_pinAndUnpinUser() async throws {
//        try await client.connect()
//        let firstUserCall = client.call(callType: .default, callId: randomCallId)
//        try await firstUserCall.create(memberIds: [user1, user2])
//
//        let secondUserClient = try await makeClient(for: user2)
//        let secondUserCall = secondUserClient.call(
//            callType: .default,
//            callId: firstUserCall.callId
//        )
//
//        try await firstUserCall.join()
//        try await customWait()
//
//        try await secondUserCall.join()
//        try await customWait()
//
//        _ = try await firstUserCall.pinForEveryone(userId: user2, sessionId: secondUserCall.state.sessionId)
//        await waitForPinning(firstUserCall: firstUserCall, secondUserCall: secondUserCall)
//
//        var pin = await firstUserCall.state.participantsMap[secondUserCall.state.sessionId]?.pin
//        XCTAssertNotNil(pin)
//        XCTAssertEqual(pin?.isLocal, false)
//
//        _ = try await firstUserCall.unpinForEveryone(userId: user2, sessionId: secondUserCall.state.sessionId)
//        await waitForUnpinning(firstUserCall: firstUserCall, secondUserCall: secondUserCall)
//
//        pin = await firstUserCall.state.participantsMap[secondUserCall.state.sessionId]?.pin
//        XCTAssertNil(pin)
//
//        try await firstUserCall.pin(sessionId: secondUserCall.state.sessionId)
//        await waitForPinning(firstUserCall: firstUserCall, secondUserCall: secondUserCall)
//
//        pin = await firstUserCall.state.participantsMap[secondUserCall.state.sessionId]?.pin
//        XCTAssertNotNil(pin)
//        XCTAssertEqual(pin?.isLocal, true)
//
//        try await firstUserCall.unpin(sessionId: secondUserCall.state.sessionId)
//        await waitForUnpinning(firstUserCall: firstUserCall, secondUserCall: secondUserCall)
//
//        pin = await firstUserCall.state.participantsMap[secondUserCall.state.sessionId]?.pin
//        XCTAssertNil(pin)
//    }
//
//    func test_joinBackstageRegularUser() async throws {
//        let startingDate = Date(timeIntervalSinceNow: 30)
//        let joiningDate = Date(timeInterval: -20, since: startingDate)
//        let firstUserCall = client.call(callType: .livestream, callId: randomCallId)
//        try await firstUserCall.create(
//            memberIds: [user1],
//            startsAt: startingDate,
//            backstage: .init(enabled: true, joinAheadTimeSeconds: 20)
//        )
//
//        let secondUserClient = try await makeClient(for: user2)
//        let secondUserCall = secondUserClient.call(
//            callType: .livestream,
//            callId: firstUserCall.callId
//        )
//
//        try await firstUserCall.join()
//
//        let error = await XCTAssertThrowsErrorAsync {
//            try await secondUserCall.join()
//        }
//        let apiError = try XCTUnwrap(error as? APIError)
//        XCTAssertEqual(apiError.statusCode, 403)
//
//        await fulfillment(timeout: 30) { Date() >= joiningDate }
//        try await secondUserCall.join()
//    }
// }
