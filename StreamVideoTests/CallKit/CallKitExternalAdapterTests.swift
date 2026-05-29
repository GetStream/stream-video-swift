//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CallKit
import Foundation
@testable import StreamVideo
import XCTest

final class CallKitExternalAdapterTests: XCTestCase, @unchecked Sendable {

    private var callKitService: CallKitService!
    private var callController: MockCXCallController!
    private var callProvider: MockCXProvider!
    private var uuidFactory: MockUUIDFactory!
    private var user: User!
    private var streamVideo: MockStreamVideo! = .init()
    private var subject: CallKitExternalAdapter!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        CurrentDevice.currentValue.didUpdate(.phone)
        callKitService = .init()
        callController = .init()
        callProvider = .init()
        uuidFactory = .init()
        user = .init(id: "current-user")
        streamVideo = .init(user: user)
        subject = .init()
        InjectedValues[\.callKitService] = callKitService
        InjectedValues[\.uuidFactory] = uuidFactory
        callKitService.callController = callController
        callKitService.callProvider = callProvider
        callKitService.streamVideo = streamVideo
    }

    @MainActor
    override func tearDown() async throws {
        CurrentDevice.currentValue.didUpdate(.simulator)
        subject = nil
        streamVideo = nil
        user = nil
        uuidFactory = nil
        callProvider = nil
        callController = nil
        callKitService = nil
        try await super.tearDown()
    }

    @MainActor
    func test_ringingOutgoingCall_requestsStartCallAction() async throws {
        let callUUID = UUID()
        uuidFactory.getResult = callUUID
        let call = makeOutgoingCall(remoteUserIds: ["remote"])
        subject.streamVideo = streamVideo

        streamVideo.state.ringingCall = call

        await fulfilmentInMainActor {
            self.callController.requestWasCalledWith?.0.actions.last is CXStartCallAction
        }
        let action = try XCTUnwrap(
            callController.requestWasCalledWith?.0.actions.last as? CXStartCallAction
        )
        XCTAssertEqual(action.callUUID, callUUID)
        XCTAssertEqual(action.handle.value, "remote")
    }

    @MainActor
    func test_ringingOutgoingCallBecomesActive_reportsOutgoingCallConnected() async throws {
        let callUUID = UUID()
        uuidFactory.getResult = callUUID
        let call = makeOutgoingCall(remoteUserIds: ["remote"])
        subject.streamVideo = streamVideo

        streamVideo.state.ringingCall = call
        await fulfilmentInMainActor {
            self.callController.requestWasCalledWith?.0.actions.last is CXStartCallAction
        }
        let action = try XCTUnwrap(
            callController.requestWasCalledWith?.0.actions.last as? CXStartCallAction
        )
        callKitService.provider(callProvider, perform: action)
        await fulfilmentInMainActor {
            if case .reportOutgoingCallStartedConnecting = self.callProvider.invocations.last {
                return true
            } else {
                return false
            }
        }
        callProvider.reset()

        streamVideo.state.activeCall = call

        await fulfilmentInMainActor {
            if case .reportOutgoingCallConnected = self.callProvider.invocations.last {
                return true
            } else {
                return false
            }
        }
        guard case let .reportOutgoingCallConnected(uuid, date) = callProvider.invocations.last else {
            return XCTFail()
        }
        XCTAssertEqual(uuid, callUUID)
        XCTAssertNotNil(date)
    }

    @MainActor
    func test_ringingIncomingCall_doesNotRequestStartCallAction() async {
        let call = makeIncomingCall(remoteUserIds: ["remote"])
        subject.streamVideo = streamVideo

        streamVideo.state.ringingCall = call

        await wait(for: 1)
        XCTAssertNil(callController.requestWasCalledWith)
    }

    // MARK: - Private Helpers

    @MainActor
    private func makeOutgoingCall(
        remoteUserIds: [String]
    ) -> MockCall {
        makeCall(createdBy: user, remoteUserIds: remoteUserIds)
    }

    @MainActor
    private func makeIncomingCall(
        remoteUserIds: [String]
    ) -> MockCall {
        makeCall(createdBy: .init(id: "caller"), remoteUserIds: remoteUserIds)
    }

    @MainActor
    private func makeCall(
        createdBy: User,
        remoteUserIds: [String]
    ) -> MockCall {
        let call = MockCall(.dummy())
        let callState = CallState(.dummy())
        callState.createdBy = createdBy
        callState.members = [Member(user: user, updatedAt: Date())]
            + remoteUserIds.map { Member(user: .init(id: $0), updatedAt: Date()) }
        call.stub(for: \.state, with: callState)
        return call
    }
}

private final class MockUUIDFactory: UUIDProviding {
    var getResult: UUID?

    func get() -> UUID {
        getResult ?? .init()
    }
}
