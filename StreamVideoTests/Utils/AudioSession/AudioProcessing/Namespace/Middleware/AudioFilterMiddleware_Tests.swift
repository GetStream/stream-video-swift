//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class AudioFilterMiddleware_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - Subject

    private lazy var subject: AudioProcessingStore.Namespace.AudioFilterMiddleware! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_setInitializedConfiguration_initializesExistingFilter() async {
        let filter = MockAudioFilter(id: "f")
        var state = AudioProcessingStore.Namespace.StoreState.initial
        state.audioFilter = filter

        subject.apply(
            state: state,
            action: .setInitializedConfiguration(sampleRate: 48000, channels: 2),
            file: #file, function: #function, line: #line
        )

        await fulfillment {
            filter.initializedParams?.sampleRate == 48000
                && filter.initializedParams?.channels == 2
        }
    }

    func test_setAudioFilter_initializesWhenFormatKnown() async {
        let filter = MockAudioFilter(id: "g")
        var state = AudioProcessingStore.Namespace.StoreState.initial
        state.initializedSampleRate = 44100
        state.initializedChannels = 1

        subject.apply(
            state: state,
            action: .setAudioFilter(filter),
            file: #file, function: #function, line: #line
        )

        await fulfillment {
            filter.initializedParams?.sampleRate == 44100
                && filter.initializedParams?.channels == 1
        }
    }

    func test_release_releasesFilterAndClearsProcessingHandler() {
        let filter = MockAudioFilter(id: "existing")
        var state = AudioProcessingStore.Namespace.StoreState.initial
        state.audioFilter = filter
        state.capturePostProcessingDelegate.processingHandler = { _ in }

        subject.apply(
            state: state,
            action: .release,
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(filter.releaseCount, 1)
        XCTAssertNil(state.capturePostProcessingDelegate.processingHandler)
    }

    func test_setAudioFilter_replacesExistingFilter_releasesPreviousAndUpdatesHandler() async {
        let oldFilter = MockAudioFilter(id: "old")
        let newFilter = MockAudioFilter(id: "new")
        var state = AudioProcessingStore.Namespace.StoreState.initial
        state.initializedSampleRate = 48000
        state.initializedChannels = 2
        state.audioFilter = oldFilter
        let capturePostProcessingDelegate = state.capturePostProcessingDelegate

        subject.apply(
            state: state,
            action: .setAudioFilter(newFilter),
            file: #file,
            function: #function,
            line: #line
        )

        await fulfillment {
            oldFilter.releaseCount == 1
                && newFilter.initializedParams?.sampleRate == 48000
                && newFilter.initializedParams?.channels == 2
                && capturePostProcessingDelegate.processingHandler != nil
        }
    }
}
