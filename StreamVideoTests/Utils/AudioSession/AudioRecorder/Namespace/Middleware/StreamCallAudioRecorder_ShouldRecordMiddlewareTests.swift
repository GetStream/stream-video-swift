//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

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
