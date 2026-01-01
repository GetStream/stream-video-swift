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
}
