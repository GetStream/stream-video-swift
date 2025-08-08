//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class InterruptionEffect_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - Properties

    private lazy var store: MockRTCAudioStore! = .init()
    private lazy var subject: RTCAudioStore.InterruptionEffect! = .init(store.audioStore)

    // MARK: - Lifecycle

    override func tearDown() {
        store = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init_delegateWasAdded() {
        _ = subject

        XCTAssertEqual(store.session.timesCalled(.addDelegate), 1)
    }

    // MARK: - audioSessionDidBeginInterruption

    func test_audioSessionDidBeginInterruption_dispatchesIsInterruptedAndDisablesAudio() async {
        subject.audioSessionDidBeginInterruption(.sharedInstance())

        await fulfillment {
            self.store.audioStore.state.isInterrupted == true
                && self.store.audioStore.state.isAudioEnabled == false
        }
    }

    // MARK: - audioSessionDidEndInterruption

    func test_audioSessionDidEndInterruption_shouldNotResume_dispatchesIsInterruptedFalseOnly() async {
        subject.audioSessionDidBeginInterruption(.sharedInstance())

        subject.audioSessionDidEndInterruption(
            .sharedInstance(),
            shouldResumeSession: false
        )

        await fulfillment { self.store.audioStore.state.isInterrupted == false }
        XCTAssertFalse(store.audioStore.state.isActive)
        XCTAssertFalse(store.audioStore.state.isAudioEnabled)
    }

    func test_audioSessionDidEndInterruption_shouldResume_dispatchesExpectedSequence() async {
        subject.audioSessionDidBeginInterruption(.sharedInstance())

        subject.audioSessionDidEndInterruption(
            .sharedInstance(),
            shouldResumeSession: true
        )

        await fulfillment {
            self.store.audioStore.state.isInterrupted == false
                && self.store.audioStore.state.isActive == true
                && self.store.audioStore.state.isAudioEnabled == true
        }
    }
}
