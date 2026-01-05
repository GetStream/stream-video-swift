//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class CapturedChannelsMiddleware_Tests: XCTestCase, @unchecked Sendable {

    private lazy var delegate: AudioCustomProcessingModule! = .init()
    private lazy var store: Store<AudioProcessingStore.Namespace>! = AudioProcessingStore.Namespace.store(initialState: .initial)
    private lazy var subject: AudioProcessingStore.Namespace.CapturedChannelsMiddleware! = .init()

    override func setUp() {
        super.setUp()
        subject.dispatcher = .init(store)
    }

    override func tearDown() {
        delegate = nil
        store = nil
        subject = nil
        super.tearDown()
    }

    func test_load_subscribesAndDispatchesInitialization() async {
        subject.apply(
            state: .init(
                initializedSampleRate: 0,
                initializedChannels: 0,
                numberOfCaptureChannels: 0,
                capturePostProcessingDelegate: delegate
            ),
            action: .load,
            file: #file,
            function: #function,
            line: #line
        )

        delegate.audioProcessingInitialize(sampleRate: 32000, channels: 2)

        await fulfillment {
            self.store.state.initializedSampleRate == 32000
                && self.store.state.initializedChannels == 2
        }
    }

    func test_release_dispatchesRelease() async {
        subject.apply(
            state: .init(
                initializedSampleRate: 32000,
                initializedChannels: 2,
                numberOfCaptureChannels: 0,
                capturePostProcessingDelegate: delegate
            ),
            action: .load,
            file: #file,
            function: #function,
            line: #line
        )

        delegate.audioProcessingRelease()

        await fulfillment {
            self.store.state.initializedSampleRate == 0
                && self.store.state.initializedChannels == 0
        }
    }
}
