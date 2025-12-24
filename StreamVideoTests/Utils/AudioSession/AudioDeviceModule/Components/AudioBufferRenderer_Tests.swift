//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class AudioBufferRenderer_Tests: XCTestCase, @unchecked Sendable {

    private var subject: AudioBufferRenderer!

    override func setUp() {
        super.setUp()
        subject = AudioBufferRenderer()
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_configure_withContext_updatesStoredContext() {
        let engine = AVAudioEngine()
        let destination = AVAudioMixerNode()
        let format = makeFormat()
        let context = AVAudioEngine.InputContext(
            engine: engine,
            source: nil,
            destination: destination,
            format: format
        )

        subject.configure(with: context)

        let storedContext = rendererContext(subject)
        XCTAssertNotNil(storedContext)
        XCTAssertTrue(storedContext?.engine === engine)
        XCTAssertTrue(storedContext?.destination === destination)
    }

    func test_reset_clearsStoredContext() {
        let engine = AVAudioEngine()
        let destination = AVAudioMixerNode()
        let context = AVAudioEngine.InputContext(
            engine: engine,
            source: nil,
            destination: destination,
            format: makeFormat()
        )
        subject.configure(with: context)

        subject.reset()

        XCTAssertNil(rendererContext(subject))
    }

    // MARK: - Helpers

    private func makeFormat() -> AVAudioFormat {
        AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 48000,
            channels: 1,
            interleaved: false
        )!
    }

    private func rendererContext(
        _ renderer: AudioBufferRenderer
    ) -> AVAudioEngine.InputContext? {
        Mirror(reflecting: renderer)
            .descendant("context") as? AVAudioEngine.InputContext
    }
}
