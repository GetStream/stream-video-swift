//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamVideo
import XCTest

final class HLSAudioSession_Tests: XCTestCase, @unchecked Sendable {

    private var mockAudioStore: MockRTCAudioStore!
    private var middleware: MockMiddleware<RTCAudioStore.Namespace>!
    private var subject: HLSAudioSession!

    private var state: RTCAudioStore.Namespace.State { mockAudioStore.audioStore.state }

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        mockAudioStore = .init()
        mockAudioStore.makeShared()
        middleware = .init()
        mockAudioStore.audioStore.add(middleware)
        subject = .init()
    }

    override func tearDown() async throws {
        await subject?.deactivate()
        subject = nil
        middleware = nil
        try await mockAudioStore.dismantle()
        mockAudioStore = nil
        try await super.tearDown()
    }

    // MARK: - activate

    func test_activate_unowned_configuresPlaybackWithoutRecordOptions() async throws {
        try await subject.activate()

        let configuration = state.audioSessionConfiguration
        XCTAssertEqual(configuration.category, .playback)
        XCTAssertEqual(configuration.mode, .moviePlayback)
        XCTAssertEqual(configuration.options, [])
    }

    func test_activate_afterTheCallBootstrap_dropsTheCallCategoryOptions() async throws {
        mockAudioStore.audioStore.dispatch(
            .avAudioSession(
                .setCategoryAndModeAndCategoryOptions(
                    .playAndRecord,
                    mode: .voiceChat,
                    categoryOptions: [.allowBluetoothHFP, .allowBluetoothA2DP]
                )
            )
        )
        await fulfillment { self.state.audioSessionConfiguration.category == .playAndRecord }

        try await subject.activate()

        let configuration = state.audioSessionConfiguration
        XCTAssertEqual(configuration.category, .playback)
        XCTAssertEqual(configuration.options, [])
    }

    func test_activate_unowned_claimsOwnership() async throws {
        try await subject.activate()

        XCTAssertEqual(state.activeSessionIdentifier, subject.identifier)
    }

    func test_activate_activatesTheSessionOnce() async throws {
        try await subject.activate()

        XCTAssertTrue(state.isActive)
        XCTAssertEqual(middleware.actionsReceived.filter { $0 == .setActive(true) }.count, 1)
    }

    func test_activate_repeated_isANoOp() async throws {
        try await subject.activate()
        let received = middleware.actionsReceived.count

        try await subject.activate()

        XCTAssertEqual(middleware.actionsReceived.count, received)
    }

    func test_activate_cancelled_throwsAndDispatchesNothing() async throws {
        let subject = try XCTUnwrap(subject)
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await subject.activate()
        }

        do {
            try await task.value
            XCTFail("Expected the cancelled activation to throw.")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
        XCTAssertTrue(middleware.actionsReceived.isEmpty)
        XCTAssertEqual(state.activeSessionIdentifier, "")
    }

    func test_activate_anotherSessionOwnsTheStore_takesOwnershipAndPlays() async throws {
        let owner = String.unique
        mockAudioStore.audioStore.dispatch(.setActiveSessionIdentifier(owner))
        await fulfillment { self.state.activeSessionIdentifier == owner }

        try await subject.activate()

        XCTAssertEqual(state.activeSessionIdentifier, subject.identifier)
        XCTAssertEqual(state.audioSessionConfiguration.category, .playback)
        XCTAssertEqual(state.audioSessionConfiguration.mode, .moviePlayback)
        XCTAssertTrue(state.isActive)
    }

    func test_deactivate_afterTheLoss_leavesTheNewOwnersConfigurationAlone() async throws {
        try await subject.activate()
        let owner = String.unique
        mockAudioStore.audioStore.dispatch(
            [
                .setActiveSessionIdentifier(owner),
                .avAudioSession(
                    .setCategoryAndModeAndCategoryOptions(
                        .playAndRecord,
                        mode: .videoChat,
                        categoryOptions: [.allowBluetoothA2DP]
                    )
                )
            ]
        )
        await fulfillment { self.state.audioSessionConfiguration.mode == .videoChat }

        await subject.deactivate()

        XCTAssertEqual(state.activeSessionIdentifier, owner)
        XCTAssertEqual(state.audioSessionConfiguration.mode, .videoChat)
        XCTAssertEqual(state.audioSessionConfiguration.options, [.allowBluetoothA2DP])
    }

    // MARK: - deactivate

    func test_deactivate_afterActivate_deactivatesAndReleasesOwnership() async throws {
        try await subject.activate()

        await subject.deactivate()

        XCTAssertFalse(state.isActive)
        XCTAssertEqual(state.activeSessionIdentifier, "")
        XCTAssertEqual(middleware.actionsReceived.filter { $0 == .setActive(false) }.count, 1)
    }

    func test_deactivate_repeated_isANoOp() async throws {
        try await subject.activate()
        await subject.deactivate()
        let received = middleware.actionsReceived.count

        await subject.deactivate()

        XCTAssertEqual(middleware.actionsReceived.count, received)
    }

    func test_deactivate_withoutActivate_isANoOp() async {
        await subject.deactivate()

        XCTAssertTrue(middleware.actionsReceived.isEmpty)
    }

    func test_deactivate_anotherSessionOwnsTheStore_leavesItsOwnershipAlone() async throws {
        try await subject.activate()
        let owner = String.unique
        mockAudioStore.audioStore.dispatch(.setActiveSessionIdentifier(owner))
        await fulfillment { self.state.activeSessionIdentifier == owner }

        await subject.deactivate()

        XCTAssertEqual(state.activeSessionIdentifier, owner)
    }

    func test_deactivate_afterActivate_restoresTheCallConfiguration() async throws {
        try await subject.activate()

        await subject.deactivate()

        let configuration = state.audioSessionConfiguration
        XCTAssertEqual(configuration.category, .playAndRecord)
        XCTAssertEqual(configuration.mode, .voiceChat)
        XCTAssertEqual(configuration.options, [.allowBluetoothHFP, .allowBluetoothA2DP])
    }

    func test_deactivate_anotherSessionOwnsTheStore_doesNotRestoreTheCallConfiguration() async throws {
        try await subject.activate()
        mockAudioStore.audioStore.dispatch(.setActiveSessionIdentifier(.unique))
        await fulfillment { self.state.activeSessionIdentifier != self.subject.identifier }

        await subject.deactivate()

        XCTAssertEqual(state.audioSessionConfiguration.category, .playback)
    }

    // MARK: - deactivate (dispatch order and failures)

    func test_deactivate_dispatchesDeactivationThenRestoreThenRelease() async throws {
        let recorder = DispatchRecorder()
        let subject = HLSAudioSession(dispatch: recorder.dispatch)
        try await subject.activate()
        recorder.reset()

        await subject.deactivate()

        let owned = RTCAudioStore.Namespace.Action.Condition
            .activeSessionIdentifier(subject.identifier)
        let bootstrap: RTCAudioStore.StoreAction = .avAudioSession(
            .setCategoryAndModeAndCategoryOptions(
                .playAndRecord,
                mode: .voiceChat,
                categoryOptions: [.allowBluetoothHFP, .allowBluetoothA2DP]
            )
        )
        XCTAssertEqual(
            recorder.batches,
            [
                [.conditioned(owned, action: .setActive(false))],
                [.conditioned(owned, action: bootstrap)],
                [.conditioned(owned, action: .setActiveSessionIdentifier(""))]
            ]
        )
    }

    func test_deactivate_setActiveFails_stillRestoresAndReleases() async throws {
        let recorder = DispatchRecorder(failing: { $0.contains(.setActive(false)) })
        let subject = HLSAudioSession(dispatch: recorder.dispatch)
        try await subject.activate()
        recorder.reset()

        await subject.deactivate()

        XCTAssertEqual(recorder.batches.count, 3)
        XCTAssertEqual(
            recorder.batches.last,
            [.conditioned(
                .activeSessionIdentifier(subject.identifier),
                action: .setActiveSessionIdentifier("")
            )]
        )
    }

    func test_deactivate_restoreFails_stillReleases() async throws {
        let bootstrap: RTCAudioStore.StoreAction = .avAudioSession(
            .setCategoryAndModeAndCategoryOptions(
                .playAndRecord,
                mode: .voiceChat,
                categoryOptions: [.allowBluetoothHFP, .allowBluetoothA2DP]
            )
        )
        let recorder = DispatchRecorder(failing: { $0.contains(bootstrap) })
        let subject = HLSAudioSession(dispatch: recorder.dispatch)
        try await subject.activate()
        recorder.reset()

        await subject.deactivate()

        XCTAssertEqual(recorder.batches.count, 3)
        XCTAssertEqual(
            recorder.batches.last,
            [.conditioned(
                .activeSessionIdentifier(subject.identifier),
                action: .setActiveSessionIdentifier("")
            )]
        )
    }

    func test_activateAfterDeactivate_activatesAgain() async throws {
        try await subject.activate()
        await subject.deactivate()

        try await subject.activate()

        XCTAssertTrue(state.isActive)
        XCTAssertEqual(state.activeSessionIdentifier, subject.identifier)
    }
}
