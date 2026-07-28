//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

#if canImport(LiveCommunicationKit)
import Combine
import Foundation
import LiveCommunicationKit
@testable import StreamVideo
@preconcurrency import XCTest

@available(iOS 27.0, *)
final class LiveCommunicationKitServiceTests: XCTestCase, @unchecked Sendable {

    private var subject: LiveCommunicationKitService!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        subject = .init()
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        subject = nil
        super.tearDown()
    }

    func test_participantAutoLeavePolicy_hasExpectedDefaultValue() {
        XCTAssertTrue(subject.participantAutoLeavePolicy is LastParticipantAutoLeavePolicy)
    }

    func test_callIdentifierProperties_whenNoCallIsActive_areEmpty() {
        XCTAssertEqual(subject.callId, "")
        XCTAssertEqual(subject.callType, "")
        XCTAssertEqual(subject.callCount, 0)
    }

    func test_eventPipeline_whenInitialized_emitsIdle() {
        var receivedEvents: [CallKitService.Event] = []

        subject.eventPipeline
            .sink { receivedEvents.append($0) }
            .store(in: &cancellables)

        XCTAssertEqual(receivedEvents.count, 1)
        guard case .idle = receivedEvents.first else {
            return XCTFail("Expected the initial event to be idle.")
        }
    }

    func test_conversationManager_whenBuilt_usesServiceConfiguration() throws {
        let expectedIconData = try XCTUnwrap("icon".data(using: .utf8))
        subject.iconTemplateImageData = expectedIconData
        subject.ringtoneSound = "ring.caf"
        subject.supportsVideo = true
        subject.includesCallsInRecents = false

        let manager = subject.conversationManager
        let configuration = manager.configuration

        XCTAssertEqual(configuration.iconTemplateImageData, expectedIconData)
        XCTAssertEqual(configuration.ringtoneName, "ring.caf")
        XCTAssertEqual(configuration.maximumConversationGroups, 1)
        XCTAssertEqual(configuration.maximumConversationsPerConversationGroup, 1)
        XCTAssertFalse(configuration.includesConversationInRecents)
        XCTAssertTrue(configuration.supportsVideo)
        XCTAssertEqual(configuration.supportedHandleTypes, [.generic])
        XCTAssertTrue(manager.delegate === subject)
    }

    func test_checkIfCallWasHandled_whenStreamVideoIsNil_returnsNotConfiguredReason() {
        let reason = subject.checkIfCallWasHandled(callState: .dummy())

        XCTAssertEqual(
            reason,
            StreamRejectionReasonProvider.HandledCallReason.notConfigured.rawValue
        )
    }

    func test_callEntry_whenCallAndUUIDMatch_isEqual() {
        let call = Call.dummy(callType: .default, callId: "call-1")
        let callUUID = UUID()

        let lhs = LiveCommunicationKitService.CallEntry(
            call: call,
            callUUID: callUUID
        )
        let rhs = LiveCommunicationKitService.CallEntry(
            call: call,
            callUUID: callUUID
        )

        XCTAssertEqual(lhs, rhs)
    }

    func test_callEntry_whenCallUUIDDiffers_isNotEqual() {
        let call = Call.dummy(callType: .default, callId: "call-1")

        let lhs = LiveCommunicationKitService.CallEntry(
            call: call,
            callUUID: UUID()
        )
        let rhs = LiveCommunicationKitService.CallEntry(
            call: call,
            callUUID: UUID()
        )

        XCTAssertNotEqual(lhs, rhs)
    }
}
#endif
