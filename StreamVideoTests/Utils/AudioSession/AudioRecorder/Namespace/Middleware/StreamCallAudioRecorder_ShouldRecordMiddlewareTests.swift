//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class StreamCallAudioRecorder_ShouldRecordMiddlewareClientTests: StreamVideoTestCase, @unchecked Sendable {

    private var subject: StreamCallAudioRecorder.Namespace.ShouldRecordMiddleware!
    private var newClient: StreamVideo!
    private var replacementClient: StreamVideo!
    private var fixtureSession: MockRTCAudioStore?
    private var fixturePermissions: MockPermissionsStore?

    override func tearDown() async throws {
        subject = nil
        try await fixtureSession?.dismantle()
        fixtureSession = nil
        fixturePermissions?.dismantle()
        fixturePermissions = nil
        await replacementClient?.disconnect()
        replacementClient = nil
        await newClient?.disconnect()
        newClient = nil
        try await super.tearDown()
    }

    /// Collects every `setShouldRecord` value the middleware dispatches.
    private func recordShouldRecordValues() -> AllocatedUnfairLock<[Bool]> {
        let values = AllocatedUnfairLock<[Bool]>([])
        subject.dispatcher = .init { actions, _, _, _ in
            if case let .setShouldRecord(value) = actions[0].wrappedValue {
                values.withLock { $0.append(value) }
            }
        }
        return values
    }

    func test_newStreamVideoClient_activeCallEnds_dispatchesSetShouldRecordFalseOnce() async {
        subject = .init()
        newClient = StreamVideo.mock(httpClient: HTTPClient_Mock())
        let values = recordShouldRecordValues()

        let call = Call.dummy(callType: .default, callId: .unique)
        await MainActor.run { newClient.state.activeCall = call }
        // The middleware reports the recording state after its debounce. Wait
        // for it, so only the call end can add a value afterwards.
        await fulfillment { values.withLock { $0.count } >= 1 }
        values.withLock { $0.removeAll() }
        await MainActor.run { newClient.state.activeCall = nil }
        await fulfillment { values.withLock { $0.count } >= 1 }
        await wait(for: 0.5)

        XCTAssertEqual(values.withLock { $0 }, [false])
    }

    func test_newStreamVideoClient_noActiveCall_afterClientWithoutCall_dispatchesNothingBeforeACall() async {
        subject = .init()
        let values = recordShouldRecordValues()
        newClient = StreamVideo.mock(httpClient: HTTPClient_Mock())
        replacementClient = StreamVideo.mock(httpClient: HTTPClient_Mock())

        // The call value is debounced. A value from an earlier "no call"
        // report is not, so it arrives first if it exists.
        let call = Call.dummy(callType: .default, callId: .unique)
        await MainActor.run { replacementClient.state.activeCall = call }
        await fulfillment { values.withLock { $0.count } >= 1 }

        XCTAssertEqual(values.withLock { $0 }.count, 1)
    }

    func test_clientReplacedDuringCall_dispatchesSetShouldRecordFalseOnce() async {
        subject = .init()
        newClient = StreamVideo.mock(httpClient: HTTPClient_Mock())
        let values = recordShouldRecordValues()
        let call = Call.dummy(callType: .default, callId: .unique)
        await MainActor.run { newClient.state.activeCall = call }
        // The middleware reports the recording state after its debounce. Wait
        // for it, so only the replacement can add a value afterwards.
        await fulfillment { values.withLock { $0.count } >= 1 }
        values.withLock { $0.removeAll() }

        replacementClient = StreamVideo.mock(httpClient: HTTPClient_Mock())
        await fulfillment { values.withLock { $0.count } >= 1 }
        await wait(for: 0.5)

        XCTAssertEqual(values.withLock { $0 }, [false])
    }

    /// Customer flow: the app creates a new client, uses the lobby, joins,
    /// and hangs up. A later audio route change must not reopen the mic.
    func test_newClientLobbyCallHangUp_routeChange_avAudioRecorderStaysOff() async throws {
        let spy = try MockAVAudioRecorder.build()
        spy.stub(for: .record, with: true)
        let permissions = MockPermissionsStore(inject: true)
        let session = MockRTCAudioStore()
        session.makeShared()
        defer { permissions.dismantle() }
        // The category middleware stops recording whenever the category
        // cannot record, and it reports the current one when it starts.
        // Calls configure `.playAndRecord` first, so the test does too.
        try await session.audioStore.dispatch(
            .avAudioSession(.setCategoryAndMode(.playAndRecord, mode: .default))
        ).result()

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
            await fulfillment(timeout: 10) { spy.isMeteringEnabled }
            recorder.stopRecording()
            await fulfillment(timeout: 10) { !spy.isMeteringEnabled }

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

    /// Hang-up can win the race against call monitoring. A later route
    /// change must still leave the microphone off.
    func test_hangUpBeforeMonitoringStarts_routeChange_avAudioRecorderStaysOff() async throws {
        let spy = try MockAVAudioRecorder.build()
        spy.stub(for: .record, with: true)
        let permissions = MockPermissionsStore(inject: true)
        let session = MockRTCAudioStore()
        session.makeShared()
        defer { permissions.dismantle() }

        let store = StreamCallAudioRecorder.Namespace.store(
            initialState: .initial,
            middleware: [
                StreamCallAudioRecorder.Namespace.AVAudioRecorderMiddleware(
                    audioRecorder: spy,
                    permissions: permissions.permissionsStore,
                    audioStore: session.audioStore
                ),
                StreamCallAudioRecorder.Namespace.ShouldRecordMiddleware()
            ]
        )
        _ = StreamCallAudioRecorder(store)
        newClient = StreamVideo.mock(httpClient: HTTPClient_Mock())
        var thrown: Error?

        do {
            let call = Call.dummy(callType: .default, callId: .unique)
            await MainActor.run {
                newClient.state.activeCall = call
                newClient.state.activeCall = nil
            }
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

    /// A call that starts and ends at once creates two tasks. The first
    /// must not cancel the second, or the lobby recording stays on.
    func test_lobbyRecording_callStartsAndEndsBeforeMonitoring_dispatchesSetShouldRecordFalse() async {
        let store = StreamCallAudioRecorder.Namespace.store(
            initialState: .initial,
            middleware: [StreamCallAudioRecorder.Namespace.ShouldRecordMiddleware()]
        )
        let recorder = StreamCallAudioRecorder(store)
        newClient = StreamVideo.mock(httpClient: HTTPClient_Mock())
        recorder.startRecording(ignoreActiveCall: true)
        await fulfillment { store.state.shouldRecord }

        let call = Call.dummy(callType: .default, callId: .unique)
        await MainActor.run {
            newClient.state.activeCall = call
            newClient.state.activeCall = nil
        }

        // The reducer turns `shouldRecord` off only for `.setShouldRecord(false)`.
        await fulfillment(timeout: 3) { !store.state.shouldRecord }
    }

    // MARK: - Lobby without a call

    /// The lobby sets `shouldRecord` without a call. After it closes, an
    /// unrelated audio change must not turn the microphone on again.
    func test_lobbyClosedWithoutCall_routeChange_avAudioRecorderStaysOff() async throws {
        let fixture = try await makeRecorderFixture()
        newClient = StreamVideo.mock(httpClient: HTTPClient_Mock())

        fixture.recorder.startRecording(ignoreActiveCall: true)
        await fulfillment(timeout: 10) { fixture.spy.isMeteringEnabled }
        fixture.recorder.stopRecording()
        await fulfillment(timeout: 10) { !fixture.spy.isMeteringEnabled }
        let recordCallsAtClose = fixture.spy.timesCalled(.record)

        try await fixture.session.audioStore.dispatch(
            .setCurrentRoute(.dummy(outputs: [.dummy(isReceiver: true)]))
        ).result()
        await wait(for: 1)

        XCTAssertEqual(fixture.spy.timesCalled(.record), recordCallsAtClose)
        XCTAssertFalse(fixture.spy.isMeteringEnabled)
    }

    // MARK: - Category change during a call

    /// A category that cannot record stops the recorder. When the category
    /// allows recording again, the recording of an unmuted call must resume.
    func test_callUnmuted_categoryDropsAndReturns_avAudioRecorderResumes() async throws {
        let fixture = try await makeRecorderFixture()
        newClient = StreamVideo.mock(httpClient: HTTPClient_Mock())
        try await fixture.session.audioStore.dispatch([
            .setActive(true),
            .setHasRecordingPermission(true)
        ]).result()
        let call = Call.dummy(callType: .default, callId: .unique)
        await MainActor.run {
            call.state.callSettings = CallSettings(audioOn: true)
            newClient.state.activeCall = call
        }
        fixture.recorder.startRecording()
        await fulfillment(timeout: 10) { fixture.store.state.shouldRecord && fixture.spy.isMeteringEnabled }

        try await fixture.session.audioStore.dispatch(
            .avAudioSession(
                .setCategoryAndModeAndCategoryOptions(.playback, mode: .default, categoryOptions: [])
            )
        ).result()
        await fulfillment(timeout: 10) { fixture.spy.timesCalled(.stop) >= 1 }
        XCTAssertTrue(fixture.store.state.shouldRecord)
        // Let any restart that the drop itself causes finish first.
        await wait(for: 1)
        let recordCallsAtDrop = fixture.spy.timesCalled(.record)

        try await fixture.session.audioStore.dispatch(
            .avAudioSession(
                .setCategoryAndModeAndCategoryOptions(.playAndRecord, mode: .voiceChat, categoryOptions: [])
            )
        ).result()

        await fulfillment(timeout: 10) {
            fixture.spy.timesCalled(.record) > recordCallsAtDrop && fixture.spy.isMeteringEnabled
        }
    }

    // MARK: - Private Helpers

    /// Builds a recorder with the real middleware. `tearDown` cleans up the
    /// shared audio store and permissions.
    private func makeRecorderFixture() async throws -> (
        spy: MockAVAudioRecorder,
        session: MockRTCAudioStore,
        store: Store<StreamCallAudioRecorder.Namespace>,
        recorder: StreamCallAudioRecorder
    ) {
        let spy = try MockAVAudioRecorder.build()
        spy.stub(for: .record, with: true)
        let permissions = MockPermissionsStore(inject: true)
        fixturePermissions = permissions
        let session = MockRTCAudioStore()
        session.makeShared()
        fixtureSession = session
        // Calls configure `.playAndRecord` before the recorder starts.
        try await session.audioStore.dispatch(
            .avAudioSession(.setCategoryAndMode(.playAndRecord, mode: .default))
        ).result()

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
        return (spy, session, store, StreamCallAudioRecorder(store))
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
