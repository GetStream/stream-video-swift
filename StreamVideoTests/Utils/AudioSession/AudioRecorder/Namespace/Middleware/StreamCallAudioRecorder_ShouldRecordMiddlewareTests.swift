//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class StreamCallAudioRecorder_ShouldRecordMiddlewareClientTests: StreamVideoTestCase, @unchecked Sendable {

    private var subject: StreamCallAudioRecorder.Namespace.ShouldRecordMiddleware!
    private var newClient: StreamVideo!

    override func tearDown() async throws {
        subject = nil
        await newClient?.disconnect()
        newClient = nil
        try await super.tearDown()
    }

    func test_newStreamVideoClient_activeCallEnds_dispatchesSetShouldRecordFalse() async {
        subject = .init()
        newClient = StreamVideo.mock(httpClient: HTTPClient_Mock())
        let validation = expectation(description: "setShouldRecord(false)")
        subject.dispatcher = .init { actions, _, _, _ in
            if case .setShouldRecord(false) = actions[0].wrappedValue {
                validation.fulfill()
            }
        }

        let call = Call.dummy(callType: .default, callId: .unique)
        await MainActor.run { newClient.state.activeCall = call }
        await wait(for: 0.3)
        await MainActor.run { newClient.state.activeCall = nil }

        await safeFulfillment(of: [validation])
    }

    /// Customer flow: the app creates a new client, uses the lobby, joins,
    /// and hangs up. A later audio route change must not reopen the mic.
    func test_newClientLobbyCallHangUp_routeChange_avAudioRecorderStaysOff() async throws {
        let spy = try MockAVAudioRecorder.build()
        spy.stub(for: .record, with: true)
        let permissions = MockPermissionsStore(inject: false)
        let session = MockRTCAudioStore()
        session.makeShared()
        defer { permissions.dismantle() }

        let store = StreamCallAudioRecorder.Namespace.store(
            initialState: .initial,
            middleware: [
                StreamCallAudioRecorder.Namespace.InterruptionMiddleware(),
                StreamCallAudioRecorder.Namespace.CategoryMiddleware(),
                StreamCallAudioRecorder.Namespace.AVAudioRecorderMiddleware(
                    audioRecorder: spy,
                    permissions: permissions.permissionsStore,
                    audioStore: session.audioStore
                ),
                StreamCallAudioRecorder.Namespace.ShouldRecordMiddleware()
            ]
        )
        let recorder = StreamCallAudioRecorder(store)
        newClient = StreamVideo.mock(httpClient: HTTPClient_Mock())
        var thrown: Error?

        do {
            // Lobby microphone check.
            recorder.startRecording(ignoreActiveCall: true)
            await fulfillment(timeout: 2) { spy.isMeteringEnabled }
            recorder.stopRecording()
            await fulfillment(timeout: 2) { !spy.isMeteringEnabled }

            // Join on the new client, then hang up.
            let call = Call.dummy(callType: .default, callId: .unique)
            await MainActor.run { newClient.state.activeCall = call }
            recorder.startRecording()
            await wait(for: 0.7)
            recorder.stopRecording()
            await MainActor.run { newClient.state.activeCall = nil }
            await wait(for: 0.7)
            let recordCallsAtHangUp = spy.timesCalled(.record)

            try await session.audioStore.dispatch(
                .setCurrentRoute(.dummy(outputs: [.dummy(isReceiver: true)]))
            ).result()
            await wait(for: 1)

            XCTAssertEqual(spy.timesCalled(.record), recordCallsAtHangUp)
            XCTAssertFalse(spy.isMeteringEnabled)
            XCTAssertFalse(store.state.shouldRecord)
        } catch {
            thrown = error
        }

        try await session.dismantle()
        if let thrown {
            throw thrown
        }
    }
}

// TODO: Reenable them

// final class StreamCallAudioRecorder_ShouldRecordMiddlewareTests: StreamVideoTestCase, @unchecked Sendable {
//
//    private lazy var subject: StreamCallAudioRecorder
//        .Namespace
//        .ShouldRecordMiddleware! = .init()
//
//    private lazy var mockAudioStore: MockRTCAudioStore! = .init()
//
//    override func setUp() {
//        super.setUp()
//        _ = PermissionStore.currentValue
//        _ = mockAudioStore
//    }
//
//    override func tearDown() {
//        mockAudioStore?.dismantle()
//        mockAudioStore = nil
//        subject = nil
//        super.tearDown()
//    }
//
//    // MARK: - activeCall updates
//
//    func test_activeCall_nonNilWithAudioOn_dispatchesSetShouldRecordTrue() async throws {
//        let validation = expectation(description: "Dispatcher was called")
//        subject.dispatcher = .init { actions, _, _, _ in
//            switch actions[0].wrappedValue {
//            case let .setShouldRecord(value) where value == true:
//                validation.fulfill()
//            default:
//                break
//            }
//        }
//
//        // Ensure audio session is active and permission is granted.
//        mockAudioStore.makeShared()
//        mockAudioStore.audioStore.dispatch(.audioSession(.isActive(true)))
//        mockAudioStore.audioStore.dispatch(.audioSession(.setHasRecordingPermission(true)))
//
//        let call = await MockCall(.dummy())
//        try await call.microphone.enable()
//        await fulfilmentInMainActor { call.state.callSettings.audioOn }
//        streamVideo.state.activeCall = call
//
//        await safeFulfillment(of: [validation])
//    }
//
//    func test_activeCall_nonNilWithAudioOn_changesToAudioOnFalse_dispatchesSetShouldRecordFalse() async throws {
//        let validation = expectation(description: "Dispatcher was called")
//        subject.dispatcher = .init { actions, _, _, _ in
//            switch actions[0].wrappedValue {
//            case let .setShouldRecord(value) where value == false:
//                validation.fulfill()
//            default:
//                break
//            }
//        }
//
//        // Ensure audio session is active and permission is granted.
//        mockAudioStore.makeShared()
//        mockAudioStore.audioStore.dispatch(.audioSession(.isActive(true)))
//        mockAudioStore.audioStore.dispatch(.audioSession(.setHasRecordingPermission(true)))
//
//        let call = await MockCall(.dummy())
//        try await call.microphone.enable()
//        await fulfilmentInMainActor { call.state.callSettings.audioOn }
//        streamVideo.state.activeCall = call
//
//        await wait(for: 0.1)
//        try await call.microphone.disable()
//
//        await safeFulfillment(of: [validation])
//    }
//
//    func test_activeCall_nil_noActionIsBeingDispatch() async throws {
//        let validation = expectation(description: "Dispatcher was called")
//        validation.isInverted = true
//        subject.dispatcher = .init { _, _, _, _ in }
//
//        let call = await MockCall(.dummy())
//        try await call.microphone.enable()
//
//        await safeFulfillment(of: [validation], timeout: 1)
//    }
//
//    func test_activeCall_audioOn_butPermissionMissing_dispatchesSetShouldRecordFalse() async throws {
//        let validation = expectation(description: "Dispatcher was called")
//        subject.dispatcher = .init { actions, _, _, _ in
//            switch actions[0].wrappedValue {
//            case let .setShouldRecord(value) where value == false:
//                validation.fulfill()
//            default:
//                break
//            }
//        }
//
//        mockAudioStore.makeShared()
//        mockAudioStore.audioStore.dispatch(.audioSession(.isActive(true)))
//        mockAudioStore.audioStore.dispatch(.audioSession(.setHasRecordingPermission(false)))
//
//        let call = await MockCall(.dummy())
//        try await call.microphone.enable()
//        await fulfilmentInMainActor { call.state.callSettings.audioOn }
//        streamVideo.state.activeCall = call
//
//        await safeFulfillment(of: [validation])
//    }
//
//    func test_activeCall_audioOn_butAudioSessionInactive_dispatchesSetShouldRecordFalse() async throws {
//        let validation = expectation(description: "Dispatcher was called")
//        subject.dispatcher = .init { actions, _, _, _ in
//            switch actions[0].wrappedValue {
//            case let .setShouldRecord(value) where value == false:
//                validation.fulfill()
//            default:
//                break
//            }
//        }
//
//        mockAudioStore.makeShared()
//        mockAudioStore.audioStore.dispatch(.audioSession(.isActive(false)))
//        mockAudioStore.audioStore.dispatch(.audioSession(.setHasRecordingPermission(true)))
//
//        let call = await MockCall(.dummy())
//        try await call.microphone.enable()
//        streamVideo.state.activeCall = call
//
//        await safeFulfillment(of: [validation])
//    }
// }
