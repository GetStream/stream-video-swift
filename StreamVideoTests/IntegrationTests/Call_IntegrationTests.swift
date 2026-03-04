//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class Call_IntegrationTests: XCTestCase, @unchecked Sendable {

    // MARK: - Nested Types

    private enum LeaveRouteVariant: String { case defaultRoute, speakerEnabled }

    // MARK: - Properties

    private var helpers: Call_IntegrationTests.Helpers! = .init()

    // MARK: - Lifecycle

    override func tearDown() async throws {
        _ = 0
        await helpers.dismantle()
        helpers = nil
        try await super.tearDown()
    }

    // MARK: - Scenarios

    // MARK: - Add Device

    func test_addDevice_whenANewDeviceIsAdded_thenListDevicesContainsTheNewlyAddedDeviceAsExpected() async throws {
        let deviceId = String.unique

        try await helpers
            .callFlow(id: .unique, type: .default, userId: .unique)
            .perform { try await $0.client.setDevice(id: deviceId) }
            .perform { try await $0.client.listDevices() }
            .assert { $0.value.map(\.id).contains(deviceId) }
    }

    func test_addDevice_whenANewVoIPDeviceIsAdded_thenListDevicesContainsTheNewlyAddedDeviceAsExpected() async throws {
        let deviceId = String.unique

        try await helpers
            .callFlow(id: .unique, type: .default, userId: .unique)
            .perform { try await $0.client.setVoipDevice(id: deviceId) }
            .perform { try await $0.client.listDevices() }
            .assert { $0.value.map(\.id).contains(deviceId) }
    }

    // MARK: - Delete Device

    func test_deleteDevice_whenADeviceIsRemoved_thenListDevicesShoulBeUpdatedAsExpected() async throws {
        let deviceId = String.unique

        try await helpers
            .callFlow(id: .unique, type: .default, userId: .unique)
            .perform { try await $0.client.setDevice(id: deviceId) }
            .perform { try await $0.client.deleteDevice(id: deviceId) }
            .perform { try await $0.client.listDevices() }
            .assert { $0.value.isEmpty }
    }

    func test_deleteDevice_whenAVoIPDeviceIsremoved_thenListDevicesShoulBeUpdatedAsExpected() async throws {
        let deviceId = String.unique

        try await helpers
            .callFlow(id: .unique, type: .default, userId: .unique)
            .perform { try await $0.client.setVoipDevice(id: deviceId) }
            .perform { try await $0.client.deleteDevice(id: deviceId) }
            .perform { try await $0.client.listDevices() }
            .assert { $0.value.isEmpty }
    }

    // MARK: Create

    func test_create_callContainsExpectedMembers() async throws {
        let user1 = String.unique

        try await helpers
            .callFlow(id: .unique, type: .default, userId: user1)
            .perform { try await $0.call.create(members: [.init(userId: user1)]) }
            .assertInMainActor { $0.call.state.members.endIndex == 1 }
            .assertInMainActor { $0.call.state.members.first?.id == user1 }
    }

    func test_create_whenCreatesCallwithMembersAndMemberIds_thenCallContainsExpectedMembers() async throws {
        let user1 = String.unique

        try await helpers
            .callFlow(id: .unique, type: .default, userId: user1)
            .perform { try await $0.call.create(members: [.init(userId: user1)], memberIds: [helpers.users.knownUser1]) }
            .assertInMainActor { $0.call.state.members.endIndex == 2 }
            .perform { try await $0.call.queryMembers() }
            .assert { $0.value.members.endIndex == 2 }
    }

    // MARK: Update

    func test_update_callWasUpdatedAsExpected() async throws {
        let colorKey = "color"
        let red: RawJSON = "red"
        let blue: RawJSON = "blue"

        try await helpers
            .callFlow(id: .unique, type: .default, userId: .unique)
            .perform { try await $0.call.create(custom: [colorKey: red]) }
            .assertEventually { await $0.call.state.custom[colorKey]?.stringValue == red.stringValue }
            .perform { try await $0.call.update(custom: [colorKey: blue]) }
            .assert { $0.value.call.custom[colorKey] == blue }
            .assertEventually { await $0.call.state.custom[colorKey]?.stringValue == blue.stringValue }
    }

    func test_update_whenUpdateExistingMembers_thenCallContainsExpectedMembers() async throws {
        let user1 = String.unique
        let membersGroup = "stars"
        let membersCount: Double = 3

        try await helpers
            .callFlow(id: .unique, type: .default, userId: user1)
            .perform { try await $0.call.create(members: [.init(userId: user1)]) }
            .assertInMainActor { $0.call.state.members.endIndex == 1 }
            .assertInMainActor { $0.call.state.members.first?.id == user1 }
            .perform {
                try await $0.call.updateMembers(
                    members: [.init(
                        custom: [membersGroup: .number(membersCount)],
                        userId: user1
                    )]
                )
            }
            .assertInMainActor { $0.call.state.members.endIndex == 1 }
            .assertInMainActor { $0.call.state.members.first?.customData[membersGroup]?.numberValue == membersCount }
    }

    func test_update_addMembers_whenAddedMemberIsAnAlreadyCreatedUser_thenCallContainsExpectedMembers() async throws {
        let user1 = String.unique
        let roleKey = "role"
        let roleValue = "CEO"

        try await helpers
            .callFlow(id: .unique, type: .default, userId: user1)
            .perform { try await $0.call.create(members: [.init(userId: user1)]) }
            .assertInMainActor { $0.call.state.members.endIndex == 1 }
            .assertInMainActor { $0.call.state.members.first?.id == user1 }
            .perform {
                try await $0.call.addMembers(
                    members: [
                        .init(
                            custom: [roleKey: .string(roleValue)],
                            userId: self.helpers.users.knownUser1
                        )
                    ]
                )
            }
            .assertInMainActor { $0.call.state.members.endIndex == 2 }
            .assertInMainActor { $0.call.state.members.first?.customData[roleKey]?.stringValue == roleValue }
    }

    func test_update_addMembers_whenAddedMemberIsNotAnAlreadyCreatedUser_thenCallUpdateFailsWithExpectedError() async throws {
        let user1 = String.unique
        let user2 = String.unique

        try await helpers
            .callFlow(id: .unique, type: .default, userId: user1)
            .perform { try await $0.call.create(members: [.init(userId: user1)]) }
            .assertInMainActor { $0.call.state.members.endIndex == 1 }
            .assertInMainActor { $0.call.state.members.first?.id == user1 }
            .performWithErrorExpectation { try await $0.call.addMembers(members: [.init(userId: user2)]) }
            .tryMap { $0.value as? APIError }
            .assert { $0.value.code == 4 }
            .assert { $0.value.message == "UpdateCallMembers failed with error: \"the provided users [\(user2)] don't exist\"" }
    }

    func test_update_removeMembers_whenRemoveAValidMember_thenCallContainsExpectedMembers() async throws {
        let user1 = String.unique

        try await helpers
            .callFlow(id: .unique, type: .default, userId: user1)
            .perform { try await $0.call.create(members: [.init(userId: user1)]) }
            .assertInMainActor { $0.call.state.members.endIndex == 1 }
            .assertInMainActor { $0.call.state.members.first?.id == user1 }
            .perform { try await $0.call.addMembers(members: [.init(userId: self.helpers.users.knownUser1)]) }
            .assertInMainActor { $0.call.state.members.endIndex == 2 }
            .perform { try await $0.call.removeMembers(ids: [self.helpers.users.knownUser1]) }
            .assertEventuallyInMainActor { $0.call.state.members.endIndex == 1 }
    }

    // MARK: Get

    func test_get_whenTheCallHasNotBeenCreated_throwsExpectedError() async throws {
        let callId = String.unique
        let callType = String.default
        let cid = callCid(from: callId, callType: callType)

        try await helpers
            .callFlow(id: callId, type: callType, userId: .unique)
            .performWithErrorExpectation { try await $0.call.get() }
            .tryMap { $0.value as? APIError }
            .assert { $0.value.code == 16 }
            .assert { $0.value.message == "GetCall failed with error: \"Can't find call with id \(cid)\"" }
    }

    func test_get_whenCallTypeIsInvalid_throwsExpectedError() async throws {
        let callType = String.unique

        try await helpers
            .callFlow(id: .unique, type: callType, userId: .unique)
            .performWithErrorExpectation { try await $0.call.get() }
            .tryMap { $0.value as? APIError }
            .assert { $0.value.code == 16 }
            .assert { $0.value.message.localizedStandardContains("\(callType): call type does not exist") }
    }

    // MARK: - Subscribe

    func test_subscribe_whenCustomerEventIsBeingSent_thenItShouldBeReceivedCorrectly() async throws {
        let customEventKey = String.unique
        let customEventValue = String.unique

        try await helpers
            .callFlow(id: .unique, type: .default, userId: .unique)
            .perform { try await $0.call.create() }
            .subscribe(for: CustomVideoEvent.self)
            .performWithoutValueOverride { try await $0.call.sendCustomEvent([customEventKey: .string(customEventValue)]) }
            .assertEventually { (event: CustomVideoEvent) in event.custom[customEventKey]?.stringValue == customEventValue }
    }

    // MARK: - QueryMembers

    func test_queryMembers_whenUsingASecondCallInstanceFromTheSameClient_thenCallContainsTheExpectedMembers() async throws {
        let callId = String.unique
        let user1 = String.unique

        // Initial CallFlow
        _ = try await helpers
            .callFlow(id: callId, type: .default, userId: user1)
            .perform { try await $0.call.create(memberIds: [user1]) }
            .assertEventuallyInMainActor { $0.call.state.members.endIndex == 1 }

        // Second CallFlow that uses the existing StreamVideo client
        try await helpers
            .callFlow(id: callId, type: .default, userId: user1, clientResolutionMode: .default)
            .perform { try await $0.call.get(membersLimit: 1) }
            .assertEventuallyInMainActor { $0.call.state.members.endIndex == 1 }
            .perform { try await $0.call.queryMembers() }
            .assert { $0.value.members.endIndex == 1 }
            .perform { try await $0.call.queryMembers(filters: [MemberRequest.CodingKeys.userId.rawValue: .string(user1)]) }
            .assert { $0.value.members.endIndex == 1 }
    }

    func test_queryMembers_whenUsingASecondCallInstanceFromDifferentClient_thenCallContainsTheExpectedMembers() async throws {
        let callId = String.unique
        let user1 = String.unique
        let user2 = String.unique

        // Initial CallFlow
        _ = try await helpers
            .callFlow(id: callId, type: .default, userId: user1)
            .perform { try await $0.call.create(memberIds: [user1]) }
            .assertEventuallyInMainActor { $0.call.state.members.endIndex == 1 }

        // Second CallFlow that uses a new StreamVideo client
        try await helpers
            .callFlow(id: callId, type: .default, userId: user2)
            .perform { try await $0.call.get() }
            .assertEventuallyInMainActor { $0.call.state.members.endIndex == 1 && $0.call.state.members.first?.user.id == user1 }
            .perform { try await $0.call.addMembers(ids: [user2]) }
            .assertEventuallyInMainActor { $0.call.state.members.endIndex == 2 }
            .perform { try await $0.call.queryMembers(filters: [MemberRequest.CodingKeys.userId.rawValue: .string(user2)]) }
            .assertEventuallyInMainActor { $0.value.members.endIndex == 1 }
            .perform { try await $0.call.queryMembers(limit: 1) }
            .assert { $0.value.members.endIndex == 1 && $0.value.members.first?.userId == user2 }
            .perform { (flow: CallFlow<QueryMembersResponse>) in try await flow.call.queryMembers(next: flow.value.next!) }
            .assert { $0.value.members.endIndex == 1 && $0.value.members.first?.userId == user1 }
    }

    // MARK: - QueryCalls

    func test_queryCalls_whenQueryForNotCreatedCall_thenReturnsNoResults() async throws {
        try await helpers
            .callFlow(id: .unique, type: .default, userId: .unique)
            .perform {
                try await $0.client.queryCalls(
                    filters: [CallSortField.cid.rawValue: .string($0.call.cId)],
                    watch: true
                )
            }
            .assert { $0.value.calls.isEmpty }
    }

    func test_queryCalls_whenQueryForCreatedCall_thenReturnsExpectedResults() async throws {
        try await helpers
            .callFlow(id: .unique, type: .default, userId: .unique)
            .perform { try await $0.call.create() }
            .perform {
                try await $0.client.queryCalls(
                    filters: [CallSortField.cid.rawValue: .string($0.call.cId)],
                    watch: true
                )
            }
            .assert { $0.value.calls.endIndex == 1 }
            .assert { $0.value.calls.first?.cId == $0.call.cId }
    }

    func test_queryCalls_whenQueryForCreatedCallAndThatCallUpdate_thenLocalInstanceGetsUpdatedAsExpected() async throws {
        let colorKey = "color"
        let colorValue = String.unique

        try await helpers
            .callFlow(id: .unique, type: .default, userId: .unique)
            .perform { try await $0.call.create() }
            .perform {
                try await $0.client.queryCalls(
                    filters: [CallSortField.cid.rawValue: .string($0.call.cId)],
                    watch: true
                )
            }
            .assert { $0.value.calls.endIndex == 1 }
            .assert { $0.value.calls.first?.cId == $0.call.cId }
            .perform { try await $0.call.update(custom: [colorKey: .string(colorValue)]) }
            .assertEventuallyInMainActor { $0.call.state.custom[colorKey]?.stringValue == colorValue }
    }

    func test_queryCalls_whenQueryForNotEndedCallAndCallHasNotEnded_thenReturnsExpectedResult() async throws {
        try await helpers
            .callFlow(id: .unique, type: .default, userId: .unique)
            .perform { try await $0.call.create() }
            .perform {
                try await $0.client.queryCalls(
                    filters: [
                        CallSortField.endedAt.rawValue: .nil,
                        CallSortField.cid.rawValue: .string($0.call.cId)
                    ],
                    watch: true
                )
            }
            .assert { $0.value.calls.endIndex == 1 }
            .assert { $0.value.calls.first?.cId == $0.call.cId }
    }

    func test_queryCalls_whenQueryForNotEndedCallAndCallNotEnded_thenReturnsExpectedResult() async throws {
        try await helpers
            .callFlow(id: .unique, type: .default, userId: .unique)
            .perform { try await $0.call.create() }
            .perform { try await $0.call.end() }
            .perform {
                try await $0.client.queryCalls(
                    filters: [
                        CallSortField.endedAt.rawValue: .nil,
                        CallSortField.cid.rawValue: .string($0.call.cId)
                    ],
                    watch: true
                )
            }
            .assert { $0.value.calls.isEmpty }
    }

    // MARK: - End

    func test_end_whenCreatorEndsCall_thenParticipantAutomaticallyLeaves() async throws {
        let callId = String.unique
        let creatorUserId = String.unique
        let participantUserId = String.unique

        let creatorUserFlow = try await helpers
            .callFlow(id: callId, type: .default, userId: creatorUserId)

        let participantUserFlow = try await helpers
            .callFlow(id: callId, type: .default, userId: participantUserId)

        let creatorFlow = try await creatorUserFlow
            .perform { try await $0.call.create(memberIds: [creatorUserId, participantUserId]) }

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await creatorFlow
                    .perform { try await $0.call.join() }
                    .assertEventuallyInMainActor { $0.call.state.participants.endIndex == 2 }
                    .perform { try await $0.call.end() }
            }

            group.addTask {
                try await participantUserFlow
                    .perform { try await $0.call.join() }
                    .assertEventuallyInMainActor { $0.call.streamVideo.state.activeCall == nil }
            }

            try await group.waitForAll()
        }
    }

    // MARK: - SendReactions

    func test_sendReaction_whenSendingReactionWithoutEmojiCode_thenCallReceivesTheReactionAsExpected() async throws {
        let reactionType = String.unique

        try await helpers
            .callFlow(id: .unique, type: .default, userId: .unique)
            .perform { try await $0.call.create() }
            .subscribe(for: CallReactionEvent.self)
            .performWithoutValueOverride { try await $0.call.sendReaction(type: reactionType) }
            .assertEventually { (event: CallReactionEvent) in event.reaction.type == reactionType }
    }

    func test_sendReaction_whenSendingReactionWithEmojiCode_thenCallReceivesTheReactionAsExpected() async throws {
        let reactionType = String.unique
        let emojiCode = String.unique

        try await helpers
            .callFlow(id: .unique, type: .default, userId: .unique)
            .perform { try await $0.call.create() }
            .subscribe(for: CallReactionEvent.self)
            .performWithoutValueOverride { try await $0.call.sendReaction(type: reactionType, emojiCode: emojiCode) }
            .assertEventually { (event: CallReactionEvent) in
                event.reaction.type == reactionType && event.reaction.emojiCode == emojiCode
            }
    }

    func test_sendReaction_whenSendingReactionWithCustomData_thenCallReceivesTheReactionAsExpected() async throws {
        let reactionType = String.unique
        let customKey = String.unique
        let customValue = String.unique

        try await helpers
            .callFlow(id: .unique, type: .default, userId: .unique)
            .perform { try await $0.call.create() }
            .subscribe(for: CallReactionEvent.self)
            .performWithoutValueOverride { try await $0.call.sendReaction(
                type: reactionType,
                custom: [customKey: .string(customValue)]
            ) }
            .assertEventually { (event: CallReactionEvent) in
                event.reaction.type == reactionType && event.reaction.custom?[customKey]?.stringValue == customValue
            }
    }

    // MARK: - Block

    func test_block_whenUserGetsBlocked_thenCallStateUpdatesAsExpected() async throws {
        try await helpers
            .callFlow(id: .unique, type: .default, userId: helpers.users.knownUser1)
            .perform { try await $0.call.create(memberIds: [helpers.users.knownUser1, helpers.users.knownUser2]) }
            .perform { try await $0.call.blockUser(with: helpers.users.knownUser2) }
            .assertEventuallyInMainActor { $0.call.state.blockedUserIds.contains(helpers.users.knownUser2) }
            .perform { try await $0.call.queryMembers() }
            .assert { $0.value.members.endIndex == 2 }
            .perform { try await $0.call.get() }
            .assert { $0.value.call.blockedUserIds.contains(helpers.users.knownUser2) }
    }

    // MARK: - Unblock

    func test_unblock_whenUserGetsBlocked_thenCallStateUpdatesAsExpected() async throws {
        try await helpers
            .callFlow(id: .unique, type: .default, userId: helpers.users.knownUser1)
            .perform { try await $0.call.create(memberIds: [helpers.users.knownUser1, helpers.users.knownUser2]) }
            .perform { try await $0.call.blockUser(with: helpers.users.knownUser2) }
            .assertEventuallyInMainActor { $0.call.state.blockedUserIds.contains(helpers.users.knownUser2) }
            .perform { try await $0.call.unblockUser(with: helpers.users.knownUser2) }
            .assertEventuallyInMainActor { $0.call.state.blockedUserIds.isEmpty }
            .perform { try await $0.call.queryMembers() }
            .assert { $0.value.members.endIndex == 2 }
            .perform { try await $0.call.get() }
            .assert { $0.value.call.blockedUserIds.isEmpty }
    }

    // MARK: - Accept

    func test_accept_whenUserAcceptsTheCall_thenCallStateUpdatesForAllParticipantsAsExpected() async throws {
        let callId = String.unique
        let user1 = String.unique
        let user2 = String.unique

        let user1CallFlow = try await helpers
            .callFlow(id: callId, type: .default, userId: user1)
        let user2CallFlow = try await helpers
            .callFlow(id: callId, type: .default, userId: user2)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await user1CallFlow
                    .perform { try await $0.call.create(memberIds: [user1, user2], ring: true) }
                    .assertEventuallyInMainActor { $0.call.state.session?.acceptedBy[user2] != nil }
            }

            group.addTask {
                try await user2CallFlow
                    .perform { $0.client.subscribe(for: CallRingEvent.self) }
                    .assertEventually { (event: CallRingEvent) in event.call.id == callId }
                    .perform { try await $0.call.get() }
                    .perform { try await $0.call.accept() }
                    .assertEventuallyInMainActor { $0.call.state.session?.acceptedBy[user2] != nil }
            }

            try await group.waitForAll()
        }
    }

    // MARK: - Notify

    func test_notify_whenNotifyEventIsBeingSent_thenOtherParticipantsReceiveTheEventAsExpected() async throws {
        let callId = String.unique
        let user1 = String.unique
        let user2 = String.unique

        let user1CallFlow = try await helpers
            .callFlow(id: callId, type: .default, userId: user1)
        let user2CallFlow = try await helpers
            .callFlow(id: callId, type: .default, userId: user2)

        let user1CallFlowAfterCallCreation = try await user1CallFlow
            .perform { try await $0.call.create(memberIds: [user1, user2]) }

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await user1CallFlowAfterCallCreation
                    .delay(0.5)
                    .perform { try await $0.call.notify() }
            }

            group.addTask {
                try await user2CallFlow
                    .perform { try await $0.call.get() }
                    .subscribe(for: CallNotificationEvent.self)
                    .assertEventually { (event: CallNotificationEvent) in
                        event.call.id == callId && event.members.map(\.userId).contains(user2)
                    }
            }

            try await group.waitForAll()
        }
    }

    // MARK: - Join

    // MARK: Livestream

    func test_join_livestream_whenCallIsInBackstageOnlyHostCanJoin_thenAnyOtherParticipantShouldFailToJoin() async throws {
        let callId = String.unique
        let participant = String.unique

        try await helpers
            .callFlow(id: callId, type: .livestream, userId: .unique, environment: "demo")
            .perform { try await $0.call.create(backstage: .init(enabled: true)) }
            .perform { try await $0.call.join() }

        try await helpers
            .callFlow(id: callId, type: .livestream, userId: participant, environment: "demo")
            .performWithErrorExpectation { try await $0.call.join() }
            .tryMap { $0.value as? APIError }
            .assert { $0.value.code == 17 }
            .assert {
                $0.value
                    .message ==
                    "JoinCall failed with error: \"User '\(participant)' with role 'user' is not allowed to perform action JoinBackstage in scope 'video:livestream'\""
            }
            .perform { _ in
                NotificationCenter
                    .default
                    .publisher(for: Notification.Name(CallNotification.callEnded))
                    .map { _ in true }
                    .eraseToAnyPublisher()
            }
            .assertEventually { _ in true }
    }

    func test_join_livestream_whenCallIsInBackstage_thenOnlyCreatorAndOtherHostsCanJoin() async throws {
        let callId = String.unique
        let participant = String.unique
        let otherHost = String.unique

        let otherHostCallFlow = try await helpers
            .callFlow(id: callId, type: .livestream, userId: otherHost, environment: "demo")

        try await helpers
            .callFlow(id: callId, type: .livestream, userId: .unique, environment: "demo")
            .perform { try await $0.call.create(memberIds: [otherHost], backstage: .init(enabled: true)) }
            .perform { try await $0.call.join() }

        try await otherHostCallFlow
            .performWithErrorExpectation { try await $0.call.join() }

        try await helpers
            .callFlow(id: callId, type: .livestream, userId: participant, environment: "demo")
            .performWithErrorExpectation { try await $0.call.join() }
            .tryMap { $0.value as? APIError }
            .assert { $0.value.code == 17 }
            .assert {
                $0.value
                    .message ==
                    "JoinCall failed with error: \"User '\(participant)' with role 'user' is not allowed to perform action JoinBackstage in scope 'video:livestream'\""
            }
    }

    func test_join_livestream_whenCallIsInBackstageOnlyHostCanJoin_thenAfterCallGoesLiveAnyOtherParticipantCanJoin() async throws {
        let callId = String.unique
        let participant = String.unique
        let joinAheadTimeSeconds: Double = 5
        let startingDate = Date(timeIntervalSinceNow: 10)
        let joiningDate = Date(timeIntervalSinceNow: joinAheadTimeSeconds + 2)

        try await helpers
            .callFlow(id: callId, type: .livestream, userId: .unique, environment: "demo")
            .perform {
                try await $0.call.create(
                    startsAt: startingDate,
                    backstage: .init(
                        enabled: true,
                        joinAheadTimeSeconds: Int(joinAheadTimeSeconds)
                    )
                )
            }
            .perform { try await $0.call.join() }

        try await self
            .helpers
            .callFlow(id: callId, type: .livestream, userId: participant, environment: "demo")
            .performWithErrorExpectation { try await $0.call.join() }
            .assertEventually { _ in Date() >= joiningDate }
            .perform { try await $0.call.join() }
    }

    // MARK: AudioRoom

    func test_join_audioRoom_whenAParticipantIsGrantedPermissionsToSpeak_thenTheirCallStateUpdatesWithExpectedCapabilities(
    ) async throws {
        let callId = String.unique
        let host = String.unique

        let hostCallFlow = try await helpers
            .callFlow(id: callId, type: .audioRoom, userId: host, environment: "demo")
            .perform { try await $0.call.create(memberIds: [host], backstage: .init(enabled: false)) }
            .perform { try await $0.call.join() }

        let participantCallFlow = try await helpers
            .callFlow(id: callId, type: .audioRoom, userId: .unique, environment: "demo")

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await hostCallFlow
                    .assertEventuallyInMainActor { $0.call.state.permissionRequests.endIndex == 1 }
                    .tryMap { await $0.call.state.permissionRequests.first }
                    .perform { try await $0.call.grant(request: $0.value) }
            }

            group.addTask {
                try await participantCallFlow
                    .perform { try await $0.call.join() }
                    .assertInMainActor { $0.call.currentUserHasCapability(.sendAudio) == false }
                    .assertInMainActor { $0.call.currentUserHasCapability(.sendVideo) == false }
                    .perform { try await $0.call.request(permissions: [.sendAudio]) }
                    .assertEventuallyInMainActor { $0.call.currentUserHasCapability(.sendAudio) }
            }

            try await group.waitForAll()
        }
    }

    func test_join_audioRoom_whenAParticipanRequestsPermissionToSpeakAndGetsRejected_thenTheirCallStateDoesNotUpdate() async throws {
        let callId = String.unique
        let host = String.unique

        let hostCallFlow = try await helpers
            .callFlow(id: callId, type: .audioRoom, userId: host, environment: "demo")
            .perform { try await $0.call.create(memberIds: [host], backstage: .init(enabled: false)) }
            .perform { try await $0.call.join() }

        let participantCallFlow = try await helpers
            .callFlow(id: callId, type: .audioRoom, userId: .unique, environment: "demo")

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await hostCallFlow
                    .assertEventuallyInMainActor { $0.call.state.permissionRequests.endIndex == 1 }
                    .tryMap { await $0.call.state.permissionRequests.first }
                    .perform { $0.value.reject() }
            }

            group.addTask {
                try await participantCallFlow
                    .perform { try await $0.call.join() }
                    .assertInMainActor { $0.call.currentUserHasCapability(.sendAudio) == false }
                    .assertInMainActor { $0.call.currentUserHasCapability(.sendVideo) == false }
                    .perform { try await $0.call.request(permissions: [.sendAudio]) }
                    .delay(2)
                    .assertInMainActor { $0.call.currentUserHasCapability(.sendAudio) == false }
            }

            try await group.waitForAll()
        }
    }

    func test_join_audioRoom_whenAParticipantPermissionGetsRevoked_thenTheirCallStateUpdatesWithExpectedCapabilities() async throws {
        let callId = String.unique
        let host = "host"
        let participant = "participant"

        let hostCallFlow = try await helpers
            .callFlow(id: callId, type: .audioRoom, userId: host)
            .perform { try await $0.call.create(members: [.init(role: "host", userId: host)], backstage: .init(enabled: false)) }
            .perform { try await $0.call.join() }
            .assertEventuallyInMainActor { $0.call.state.ownCapabilities.contains(.updateCallPermissions) }

        let participantCallFlow = try await helpers
            .callFlow(id: callId, type: .audioRoom, userId: participant)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await hostCallFlow
                    .assertEventuallyInMainActor { $0.call.state.permissionRequests.endIndex == 1 }
                    .tryMap { await $0.call.state.permissionRequests.first }
                    .perform { try await $0.call.grant(request: $0.value) }
                    .delay(2)
                    .perform { try await $0.call.revoke(permissions: [.sendAudio], for: participant) }
            }

            group.addTask {
                try await participantCallFlow
                    .perform { try await $0.call.join() }
                    .assertEventuallyInMainActor { $0.call.state.participants.endIndex == 2 }
                    .assertInMainActor { $0.call.currentUserHasCapability(.sendAudio) == false }
                    .perform { try await $0.call.request(permissions: [.sendAudio]) }
                    .assertEventuallyInMainActor { $0.call.currentUserHasCapability(.sendAudio) }
                    .assertEventuallyInMainActor { $0.call.currentUserHasCapability(.sendAudio) == false }
            }

            try await group.waitForAll()
        }
    }

    // MARK: - Pin

    func test_pin_whenUserGetsPinnedForEveryone_thenCallStateOfAllParticipantsUpdatesAsExpected() async throws {
        let callId = String.unique
        let user1 = String.unique
        let user2 = String.unique

        let user1CallFlow = try await helpers
            .callFlow(id: callId, type: .default, userId: user1)

        let user2CallFlow = try await helpers
            .callFlow(id: callId, type: .default, userId: user2)
            .assertEventuallyInMainActor { $0.call.state.sessionId.isEmpty == false }

        let user1CallFlowAfterCallCreation = try await user1CallFlow
            .perform { try await $0.call.create(memberIds: [user1, user2]) }
            .perform { try await $0.call.join() }

        let user2SessionId = await user2CallFlow.call.state.sessionId

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await user1CallFlowAfterCallCreation
                    .assertEventuallyInMainActor { $0.call.state.participants.endIndex == 2 }
                    .perform { try await $0.call.pinForEveryone(userId: user2, sessionId: user2SessionId) }
                    .assertEventuallyInMainActor { $0.call.state.participantsMap[user2SessionId]?.pin != nil }
            }

            group.addTask {
                try await user2CallFlow
                    .perform { try await $0.call.join() }
                    .assertEventuallyInMainActor { $0.call.state.participantsMap[user2SessionId]?.pin != nil }
            }

            try await group.waitForAll()
        }
    }

    func test_pin_whenUserGetsPinnedLocally_thenCallStateOfLocalParticipantOnlyUpdatesAsExpected() async throws {
        let callId = String.unique
        let user1 = String.unique
        let user2 = String.unique

        let user1CallFlow = try await helpers
            .callFlow(id: callId, type: .default, userId: user1)

        let user2CallFlow = try await helpers
            .callFlow(id: callId, type: .default, userId: user2)
            .assertEventuallyInMainActor { $0.call.state.sessionId.isEmpty == false }

        let user1CallFlowAfterCallCreation = try await user1CallFlow
            .perform { try await $0.call.create(memberIds: [user1, user2]) }
            .perform { try await $0.call.join() }

        let user2SessionId = await user2CallFlow.call.state.sessionId

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await user1CallFlowAfterCallCreation
                    .assertEventuallyInMainActor { $0.call.state.participants.endIndex == 2 }
                    .perform { try await $0.call.pin(sessionId: user2SessionId) }
                    .assertEventuallyInMainActor { $0.call.state.participantsMap[user2SessionId]?.pin?.isLocal == true }
            }

            group.addTask {
                try await user2CallFlow
                    .perform { try await $0.call.join() }
                    .delay(2)
                    .assertEventuallyInMainActor { $0.call.state.participantsMap[user2SessionId]?.pin == nil }
            }

            try await group.waitForAll()
        }
    }

    // MARK: - Unpin

    func test_pin_whenUserGetsUnpinnedForEveryone_thenCallStateOfAllParticipantsUpdatesAsExpected() async throws {
        let callId = String.unique
        let user1 = String.unique
        let user2 = String.unique

        let user1CallFlow = try await helpers
            .callFlow(id: callId, type: .default, userId: user1)

        let user2CallFlow = try await helpers
            .callFlow(id: callId, type: .default, userId: user2)
            .assertEventuallyInMainActor { $0.call.state.sessionId.isEmpty == false }

        let user1CallFlowAfterCallCreation = try await user1CallFlow
            .perform { try await $0.call.create(memberIds: [user1, user2]) }
            .perform { try await $0.call.join() }

        let user2SessionId = await user2CallFlow.call.state.sessionId

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await user1CallFlowAfterCallCreation
                    .assertEventuallyInMainActor { $0.call.state.participants.endIndex == 2 }
                    .perform { try await $0.call.pinForEveryone(userId: user2, sessionId: user2SessionId) }
                    .assertEventuallyInMainActor { $0.call.state.participantsMap[user2SessionId]?.pin != nil }
                    .perform { try await $0.call.unpinForEveryone(userId: user2, sessionId: user2SessionId) }
            }

            group.addTask {
                try await user2CallFlow
                    .perform { try await $0.call.join() }
                    .assertEventuallyInMainActor { $0.call.state.participantsMap[user2SessionId]?.pin != nil }
                    .assertEventuallyInMainActor { $0.call.state.participantsMap[user2SessionId]?.pin == nil }
            }

            try await group.waitForAll()
        }
    }

    func test_pin_whenUserGetsUnpinnedLocally_thenCallStateOfLocalParticipantOnlyUpdatesAsExpected() async throws {
        let callId = String.unique
        let user1 = String.unique
        let user2 = String.unique

        let user1CallFlow = try await helpers
            .callFlow(id: callId, type: .default, userId: user1)

        let user2CallFlow = try await helpers
            .callFlow(id: callId, type: .default, userId: user2)
            .assertEventuallyInMainActor { $0.call.state.sessionId.isEmpty == false }

        let user1CallFlowAfterCallCreation = try await user1CallFlow
            .perform { try await $0.call.create(memberIds: [user1, user2]) }
            .perform { try await $0.call.join() }

        let user2SessionId = await user2CallFlow.call.state.sessionId

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await user1CallFlowAfterCallCreation
                    .assertEventuallyInMainActor { $0.call.state.participants.endIndex == 2 }
                    .perform { try await $0.call.pin(sessionId: user2SessionId) }
                    .assertEventuallyInMainActor { $0.call.state.participantsMap[user2SessionId]?.pin?.isLocal == true }
                    .perform { try await $0.call.unpin(sessionId: user2SessionId) }
                    .assertEventuallyInMainActor { $0.call.state.participantsMap[user2SessionId]?.pin == nil }
            }

            group.addTask {
                try await user2CallFlow
                    .perform { try await $0.call.join() }
                    .delay(2)
                    .assertEventuallyInMainActor { $0.call.state.participantsMap[user2SessionId]?.pin == nil }
            }

            try await group.waitForAll()
        }
    }

    // MARK: - Leave

    func test_leaveCallRepeatedly_defaultRoute_doesNotCrash() async throws {
        try await executeLeaveCallLifecycleScenario(.defaultRoute)
    }

    func test_leaveCallRepeatedly_speakerEnabled_doesNotCrash() async throws {
        try await executeLeaveCallLifecycleScenario(.speakerEnabled)
    }

    private func executeLeaveCallLifecycleScenario(
        _ routeVariant: LeaveRouteVariant,
        cycles: Int = 8
    ) async throws {
        let userId = String.unique

        for _ in 0..<cycles {
            try await helpers
                .callFlow(id: .unique, type: .default, userId: userId)
                .perform { try await $0.call.create(memberIds: [userId]) }
                .perform { try await $0.call.join(callSettings: .init(audioOn: true, speakerOn: routeVariant == .speakerEnabled)) }
                .assertEventuallyInMainActor { $0.call.state.participants.endIndex == 1 }
                .perform { $0.call.leave() }
                .assertEventually { _ in RTCAudioStore.shared.state.audioDeviceModule == nil }
        }
    }

    // MARK: - MuteById

    func test_mute_whenUserGetsMuted_thenCallStateOfAllParticipantsIsUpdatedAsExpected() async throws {
        let callId = String.unique
        let user1 = String.unique
        let user2 = String.unique
        helpers.permissions.setMicrophonePermission(isGranted: true)

        let user1CallFlow = try await helpers
            .callFlow(id: callId, type: .audioRoom, userId: user1)

        let user2CallFlow = try await helpers
            .callFlow(id: callId, type: .audioRoom, userId: user2)

        let user1CallFlowAfterCallCreation = try await user1CallFlow
            .perform { try await $0.call.create(memberIds: [user1, user2]) }
            .perform { try await $0.call.goLive() }

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await user1CallFlowAfterCallCreation
                    .perform { try await $0.call.join(callSettings: .init(audioOn: true, videoOn: false)) }
                    .assertEventuallyInMainActor { $0.call.state.participants.endIndex == 2 }
                    .perform { try await $0.call.grant(permissions: [.sendAudio], for: user2) }
                    .assertEventuallyInMainActor { $0.call.state.participants.first { $0.userId == user2 }?.hasAudio == true }
                    .perform { try await $0.call.mute(userId: user2) }
                    .assertEventuallyInMainActor { $0.call.state.participants.first { $0.userId == user2 }?.hasAudio == false }
            }

            group.addTask {
                try await user2CallFlow
                    .perform { try await $0.call.join(callSettings: .init(audioOn: false, videoOn: false)) }
                    .assertEventuallyInMainActor { $0.call.state.participants.endIndex == 2 }
                    .assertEventuallyInMainActor { $0.call.state.callSettings.audioOn == false }
                    .assertEventuallyInMainActor { $0.call.currentUserHasCapability(.sendAudio) }
                    .perform { try await $0.call.microphone.toggle() }
                    .assertEventuallyInMainActor { $0.call.state.callSettings.audioOn }
            }

            try await group.waitForAll()
        }
    }

    // MARK: - MuteAll

    func test_mute_whenAllOtherUsersGetMuted_thenCallStateOfAllParticipantsIsUpdatedAsExpected() async throws {
        let callId = String.unique
        let user1 = String.unique
        let user2 = String.unique
        helpers.permissions.setMicrophonePermission(isGranted: true)

        let user1CallFlow = try await helpers
            .callFlow(id: callId, type: .audioRoom, userId: user1)

        let user2CallFlow = try await helpers
            .callFlow(id: callId, type: .audioRoom, userId: user2)
            .assertEventuallyInMainActor { $0.call.state.sessionId.isEmpty == false }
        let user2SessionId = await user2CallFlow.call.state.sessionId

        let user1CallFlowAfterCallCreation = try await user1CallFlow
            .perform { try await $0.call.create(memberIds: [user1, user2]) }
            .perform { try await $0.call.goLive() }

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await user1CallFlowAfterCallCreation
                    .perform { try await $0.call.join(callSettings: .init(audioOn: true, videoOn: false)) }
                    .assertEventuallyInMainActor { $0.call.state.callSettings.audioOn }
                    .assertEventuallyInMainActor { $0.call.state.participants.endIndex == 2 }
                    .perform { try await $0.call.grant(permissions: [.sendAudio], for: user2) }
                    .assertEventuallyInMainActor { $0.call.state.participants.first { $0.userId == user2 }?.hasAudio == true }
                    .perform { try await $0.call.muteAllUsers() }
                    .assertEventuallyInMainActor { $0.call.state.participants.first { $0.userId == user2 }?.hasAudio == false }
            }

            group.addTask {
                try await user2CallFlow
                    .perform { try await $0.call.join(callSettings: .init(audioOn: false, videoOn: false)) }
                    .assertEventuallyInMainActor { $0.call.state.callSettings.audioOn == false }
                    .assertEventuallyInMainActor { $0.call.state.participants.endIndex == 2 }
                    .assertEventuallyInMainActor { $0.call.currentUserHasCapability(.sendAudio) }
                    .perform { try await $0.call.microphone.toggle() }
                    .assertEventuallyInMainActor { $0.call.state.callSettings.audioOn }
                    .assertEventuallyInMainActor { $0.call.state.callSettings.audioOn == false }
            }

            try await group.waitForAll()
        }
    }
}
