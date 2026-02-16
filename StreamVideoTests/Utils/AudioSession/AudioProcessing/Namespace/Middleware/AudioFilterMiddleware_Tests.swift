//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class AudioFilterMiddleware_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - Subject

    private lazy var subject: AudioProcessingStore.Namespace.AudioFilterMiddleware! = .init()
    private var mockAudioStore: MockRTCAudioStore?

    override func tearDown() {
        mockAudioStore?.dismantle()
        subject = nil
        mockAudioStore = nil
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

    func test_setAudioFilter_noiseCancellationFilter_dispatchesSetSoftwareNoiseCancellationTrue() async {
        mockAudioStore = MockRTCAudioStore()
        mockAudioStore?.makeShared()

        let filter = NoiseCancellationFilter(
            name: "noise-cancellation",
            initialize: { _, _ in },
            process: { _, _, _, _ in },
            release: {}
        )
        var state = AudioProcessingStore.Namespace.StoreState.initial
        state.audioFilter = filter

        subject.apply(
            state: state,
            action: .setAudioFilter(filter),
            file: #file, function: #function, line: #line
        )

        await fulfillment {
            self.mockAudioStore?.audioStore.state.hasSoftwareNoiseCancellation == true
        }
    }

    func test_setAudioFilter_nonNoiseCancellationFilter_dispatchesSetSoftwareNoiseCancellationFalse() async {
        mockAudioStore = MockRTCAudioStore()
        mockAudioStore?.makeShared()

        let noiseFilter = NoiseCancellationFilter(
            name: "noise-cancellation",
            initialize: { _, _ in },
            process: { _, _, _, _ in },
            release: {}
        )
        let regularFilter = MockAudioFilter(id: "regular-filter")
        var state = AudioProcessingStore.Namespace.StoreState.initial

        state.audioFilter = noiseFilter
        subject.apply(
            state: state,
            action: .setAudioFilter(noiseFilter),
            file: #file, function: #function, line: #line
        )
        await fulfillment {
            self.mockAudioStore?.audioStore.state.hasSoftwareNoiseCancellation == true
        }

        state.audioFilter = regularFilter
        subject.apply(
            state: state,
            action: .setAudioFilter(regularFilter),
            file: #file, function: #function, line: #line
        )

        await fulfillment {
            self.mockAudioStore?.audioStore.state.hasSoftwareNoiseCancellation == false
        }
    }

    func test_setAudioFilter_nilFilter_dispatchesSetSoftwareNoiseCancellationFalse() async {
        mockAudioStore = MockRTCAudioStore()
        mockAudioStore?.makeShared()

        let filter = NoiseCancellationFilter(
            name: "noise-cancellation",
            initialize: { _, _ in },
            process: { _, _, _, _ in },
            release: {}
        )
        var state = AudioProcessingStore.Namespace.StoreState.initial
        state.audioFilter = filter
        subject.apply(
            state: state,
            action: .setAudioFilter(filter),
            file: #file, function: #function, line: #line
        )
        await fulfillment {
            self.mockAudioStore?.audioStore.state.hasSoftwareNoiseCancellation == true
        }

        state.audioFilter = nil
        subject.apply(
            state: state,
            action: .setAudioFilter(nil),
            file: #file, function: #function, line: #line
        )

        await fulfillment {
            self.mockAudioStore?.audioStore.state.hasSoftwareNoiseCancellation == false
        }
    }
}
