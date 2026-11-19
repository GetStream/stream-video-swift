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

    func test_activate_anotherSessionOwnsTheStore_doesNotTakeOver() async throws {
        let owner = String.unique
        mockAudioStore.audioStore.dispatch(.setActiveSessionIdentifier(owner))
        await fulfillment { self.state.activeSessionIdentifier == owner }
        let configuration = state.audioSessionConfiguration

        try await subject.activate()

        XCTAssertEqual(state.activeSessionIdentifier, owner)
        XCTAssertEqual(state.audioSessionConfiguration, configuration)
        XCTAssertFalse(state.isActive)
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
        XCTAssertEqual(
            recorder.batches,
            [
                [.conditioned(owned, action: .setActive(false))],
                [.conditioned(owned, action: .callBootstrapConfiguration)],
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
        let recorder = DispatchRecorder(failing: { $0.contains(.callBootstrapConfiguration) })
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

    // MARK: - Private Helpers

    /// Stands in for the audio store: records the batches it receives and
    /// fails the ones that match `failing`.
    private final class DispatchRecorder: @unchecked Sendable {
        @Atomic private var recorded: [[RTCAudioStore.Namespace.Action]] = []
        private let failing: ([RTCAudioStore.Namespace.Action]) -> Bool

        init(failing: @escaping ([RTCAudioStore.Namespace.Action]) -> Bool = { _ in false }) {
            self.failing = failing
        }

        var batches: [[RTCAudioStore.Namespace.Action]] { recorded }

        func reset() {
            recorded = []
        }

        var dispatch: HLSAudioSession.Dispatch {
            { [self] actions in
                recorded.append(actions)
                if failing(actions.map(unwrapped)) {
                    throw ClientError("Failed.")
                }
            }
        }

        /// The action inside `.conditioned`, so a test can match on it.
        private func unwrapped(_ action: RTCAudioStore.Namespace.Action) -> RTCAudioStore.Namespace.Action {
            if case let .conditioned(_, nested) = action { return nested }
            return action
        }
    }
}
