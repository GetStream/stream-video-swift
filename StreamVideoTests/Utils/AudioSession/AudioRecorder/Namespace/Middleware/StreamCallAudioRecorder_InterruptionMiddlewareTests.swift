//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class StreamCallAudioRecorder_InterruptionMiddlewareStoreTests: XCTestCase, @unchecked Sendable {

    private var session: MockRTCAudioStore!
    private var subject: StreamCallAudioRecorder.Namespace.InterruptionMiddleware!

    override func setUp() {
        super.setUp()
        session = MockRTCAudioStore()
        session.makeShared()
        subject = .init()
    }

    override func tearDown() async throws {
        subject = nil
        try await session.dismantle()
        session = nil
        try await super.tearDown()
    }

    // MARK: - init

    /// Each `.setIsInterrupted(false)` can restart the recorder, so other
    /// audio state changes must not dispatch it again.
    func test_audioStoreIsInterruptedUnchanged_otherStateChanges_noActionDispatch() async throws {
        let validation = expectation(description: "Dispatcher was called")
        validation.isInverted = true
        validation.assertForOverFulfill = false
        subject.dispatcher = .init { _, _, _, _ in validation.fulfill() }

        try await session.audioStore.dispatch([
            .setHasRecordingPermission(true),
            .setHasRecordingPermission(false)
        ]).result()

        await safeFulfillment(of: [validation], timeout: 1)
    }

    func test_audioStoreIsInterruptedChanges_dispatchesEachChange() async throws {
        let dispatched = expectation(description: "Dispatcher was called")
        dispatched.expectedFulfillmentCount = 2
        let values = AllocatedUnfairLock<[Bool]>([])
        subject.dispatcher = .init { actions, _, _, _ in
            if case let .setIsInterrupted(value) = actions[0].wrappedValue {
                values.withLock { $0.append(value) }
                dispatched.fulfill()
            }
        }

        try await session.audioStore.dispatch(.setInterrupted(true)).result()
        try await session.audioStore.dispatch(.setInterrupted(false)).result()

        await safeFulfillment(of: [dispatched])
        XCTAssertEqual(values.withLock { $0 }, [true, false])
    }
}

// TODO: Reenable them
// final class StreamCallAudioRecorder_InterruptionMiddlewareTests: XCTestCase, @unchecked Sendable {
//
//    @Injected(\.audioStore) private var audioStore
//
//    private var subject: StreamCallAudioRecorder
//        .Namespace
//        .InterruptionMiddleware! = .init()
//
//    override func tearDown() {
//        subject = nil
//        super.tearDown()
//    }
//
//    // MARK: - init
//
//    func test_audioStoreIsInterrupted_true_dispatchesSetIsInterruptedTrue() async {
//        let validation = expectation(description: "Dispatcher was called")
//        subject.dispatcher = .init { actions, _, _, _ in
//            switch actions[0].wrappedValue {
//            case let .setIsInterrupted(value) where value == true:
//                validation.fulfill()
//            default:
//                break
//            }
//        }
//
//        audioStore.dispatch(.audioSession(.isInterrupted(true)))
//
//        await safeFulfillment(of: [validation])
//    }
//
//    func test_audioStoreIsInterrupted_false_dispatchesSetIsInterruptedFalse() async {
//        let validation = expectation(description: "Dispatcher was called")
//        subject.dispatcher = .init { actions, _, _, _ in
//            switch actions[0].wrappedValue {
//            case let .setIsInterrupted(value) where value == false:
//                validation.fulfill()
//            default:
//                break
//            }
//        }
//
//        // We need to post a true to workaround the `removeDuplicates` in the
//        // RTCAudioStore.publisher
//        audioStore.dispatch(.audioSession(.isInterrupted(true)))
//        audioStore.dispatch(.audioSession(.isInterrupted(false)))
//
//        await safeFulfillment(of: [validation])
//    }
// }
