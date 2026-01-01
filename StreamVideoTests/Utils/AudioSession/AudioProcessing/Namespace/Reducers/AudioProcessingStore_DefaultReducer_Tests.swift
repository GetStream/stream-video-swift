//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class AudioProcessingStore_DefaultReducer_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - Subject

    private lazy var subject: AudioProcessingStore.Namespace.DefaultReducer! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_setInitializedConfiguration_updatesSampleRateAndChannels() async throws {
        let initial = AudioProcessingStore.Namespace.StoreState.initial

        let updated = try await subject.reduce(
            state: initial,
            action: .setInitializedConfiguration(sampleRate: 48000, channels: 2),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(updated.initializedSampleRate, 48000)
        XCTAssertEqual(updated.initializedChannels, 2)
    }

    func test_setAudioFilter_setsActiveFilter() async throws {
        let initial = AudioProcessingStore.Namespace.StoreState.initial
        let filter = MockAudioFilter(id: "test-filter")

        let updated = try await subject.reduce(
            state: initial,
            action: .setAudioFilter(filter),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(updated.audioFilter?.id, "test-filter")
    }

    func test_setNumberOfCaptureChannels_updatesCount() async throws {
        var initial = AudioProcessingStore.Namespace.StoreState.initial
        initial.numberOfCaptureChannels = 1

        let updated = try await subject.reduce(
            state: initial,
            action: .setNumberOfCaptureChannels(2),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(updated.numberOfCaptureChannels, 2)
    }

    func test_release_resetsInitialization() async throws {
        var initial = AudioProcessingStore.Namespace.StoreState.initial
        initial.initializedSampleRate = 44100
        initial.initializedChannels = 1

        let updated = try await subject.reduce(
            state: initial,
            action: .release,
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(updated.initializedSampleRate, 0)
        XCTAssertEqual(updated.initializedChannels, 0)
    }
}
