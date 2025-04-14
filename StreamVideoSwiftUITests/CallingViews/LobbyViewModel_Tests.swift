//
//  LobbyViewModelTests.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 14/4/25.
//

import XCTest
@testable import StreamVideo
import Combine
@testable import StreamVideoSwiftUI

@MainActor
final class LobbyViewModelTests: XCTestCase, @unchecked Sendable {
    private lazy var mockStreamVideo: MockStreamVideo! = .init()
    private lazy var subject: LobbyViewModel! = .init(callType: .default, callId: .unique)

    override func tearDown() async throws {
        subject = nil
        mockStreamVideo = nil
        try await super.tearDown()
    }
    
    // MARK: - Join Events Tests
    
    func test_subscribeForCallJoinUpdates_addsNewParticipant() async throws {
        let mockCall = MockCall()
        mockCall.stub(
            for: .get,
            with: GetCallResponse.init(
                call: .dummy(),
                duration: "0",
                members: [],
                ownCapabilities: []
            )
        )
        mockStreamVideo.stub(for: .call, with: mockCall)
        _ = subject
        // we wait for loadCurrentMembers to complete
        try await Task.sleep(nanoseconds: 500_000_000)

        mockCall.onEvent(
            .coordinatorEvent(
                .typeCallSessionParticipantJoinedEvent(
                    .init(
                        callCid: mockCall.cId,
                        createdAt: .init(),
                        participant: .dummy(user: .dummy(id: "test")),
                        sessionId: mockCall.state.sessionId
                    )
                )
            )
        )

        await fulfilmentInMainActor { self.subject.participants.count == 1 }
    }
    
    // MARK: - Leave Events Tests
    
    func test_subscribeForCallLeaveUpdates_removesParticipant() async throws {
        let mockCall = MockCall()
        mockCall.stub(
            for: .get,
            with: GetCallResponse.init(
                call: .dummy(session: .dummy(participants: [.dummy(user: .dummy(id: "test"))])),
                duration: "0",
                members: [],
                ownCapabilities: []
            )
        )
        mockStreamVideo.stub(for: .call, with: mockCall)
        _ = subject
        await fulfilmentInMainActor { self.subject.participants.count == 1 }

        mockCall.onEvent(
            .coordinatorEvent(
                .typeCallSessionParticipantLeftEvent(
                    .init(
                        callCid: mockCall.cId,
                        createdAt: .init(),
                        durationSeconds: 0,
                        participant: .dummy(user: .dummy(id: "test")),
                        sessionId: mockCall.state.sessionId
                    )
                )
            )
        )

        await fulfilmentInMainActor { self.subject.participants.count == 0 }
    }
    
    func test_subscribeForCallLeaveUpdates_doesNotRemoveWrongParticipant() async throws {
        let mockCall = MockCall()
        mockCall.stub(
            for: .get,
            with: GetCallResponse.init(
                call: .dummy(
                    session: .dummy(
                        participants: [
                            .dummy(user: .dummy(id: "test1")),
                            .dummy(user: .dummy(id: "test2")),
                        ]
                    )
                ),
                duration: "0",
                members: [],
                ownCapabilities: []
            )
        )
        mockStreamVideo.stub(for: .call, with: mockCall)
        _ = subject
        await fulfilmentInMainActor { self.subject.participants.count == 2 }

        mockCall.onEvent(
            .coordinatorEvent(
                .typeCallSessionParticipantLeftEvent(
                    .init(
                        callCid: mockCall.cId,
                        createdAt: .init(),
                        durationSeconds: 0,
                        participant: .dummy(user: .dummy(id: "test1")),
                        sessionId: mockCall.state.sessionId
                    )
                )
            )
        )

        await fulfilmentInMainActor { self.subject.participants.count == 1 }
        XCTAssertEqual(self.subject.participants.map(\.id), ["test2"])
    }
}
