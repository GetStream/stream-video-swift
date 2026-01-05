//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
@testable import StreamVideo
import XCTest

final class AudioEngineLevelNodeAdapter_Tests: XCTestCase, @unchecked Sendable {

    private var subject: CurrentValueSubject<Float, Never>!
    private var sut: AudioEngineLevelNodeAdapter!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        subject = .init(-100)
        sut = AudioEngineLevelNodeAdapter()
        sut.subject = subject
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - installInputTap

    func test_installInputTap_configuresMixerTapOnce() {
        let mixer = TestMixerNode()
        let format = makeAudioFormat()

        sut.installInputTap(on: mixer, format: format, bus: 1, bufferSize: 2048)

        XCTAssertEqual(mixer.installTapCount, 1)
        XCTAssertEqual(mixer.capturedBus, 1)
        XCTAssertEqual(mixer.capturedBufferSize, 2048)
        XCTAssertTrue(mixer.capturedFormat === format)
    }

    func test_installInputTap_whenAlreadyInstalled_doesNotInstallTwice() {
        let mixer = TestMixerNode()
        let format = makeAudioFormat()

        sut.installInputTap(on: mixer, format: format)
        sut.installInputTap(on: mixer, format: format)

        XCTAssertEqual(mixer.installTapCount, 1)
    }

    func test_installInputTap_whenTapReceivesSamples_publishesDecibelValue() {
        let mixer = TestMixerNode()
        let format = makeAudioFormat()
        sut.installInputTap(on: mixer, format: format)
        let expectation = expectation(description: "Received audio level")

        var recordedValue: Float?
        subject
            .dropFirst()
            .sink { value in
                recordedValue = value
                expectation.fulfill()
            }
            .store(in: &cancellables)

        let samples: [Float] = Array(repeating: 0.5, count: 4)
        mixer.emit(bufferWith: samples, format: format)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(recordedValue ?? 0, 20 * log10(0.5), accuracy: 0.001)
    }

    // MARK: - uninstall

    func test_uninstall_removesTapAndSendsSilence() {
        let mixer = TestMixerNode()
        sut.installInputTap(on: mixer, format: makeAudioFormat())
        let expectation = expectation(description: "Received silence")

        subject
            .dropFirst()
            .sink { value in
                if value == AudioEngineLevelNodeAdapter.Constant.silenceDB {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.uninstall()
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(mixer.removeTapCount, 1)
    }

    // MARK: - Helpers

    private func makeAudioFormat() -> AVAudioFormat {
        AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, channels: 1, interleaved: false)!
    }
}

private final class TestMixerNode: AVAudioMixerNode {

    private(set) var installTapCount = 0
    private(set) var removeTapCount = 0
    private(set) var capturedBus: AVAudioNodeBus?
    private(set) var capturedBufferSize: AVAudioFrameCount?
    private(set) var capturedFormat: AVAudioFormat?
    private var tapBlock: AVAudioNodeTapBlock?
    var stubbedEngine: AVAudioEngine?

    override var engine: AVAudioEngine? { stubbedEngine }

    init(engine: AVAudioEngine? = .init()) {
        stubbedEngine = engine
        super.init()
    }

    override func installTap(
        onBus bus: AVAudioNodeBus,
        bufferSize: AVAudioFrameCount,
        format: AVAudioFormat?,
        block tapBlock: @escaping AVAudioNodeTapBlock
    ) {
        installTapCount += 1
        capturedBus = bus
        capturedBufferSize = bufferSize
        capturedFormat = format
        self.tapBlock = tapBlock
    }

    override func removeTap(onBus bus: AVAudioNodeBus) {
        removeTapCount += 1
        tapBlock = nil
    }

    func emit(bufferWith samples: [Float], format: AVAudioFormat) {
        guard let tapBlock else {
            XCTFail("Tap block not installed")
            return
        }

        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
        buffer.frameLength = AVAudioFrameCount(samples.count)
        if let pointer = buffer.floatChannelData?[0] {
            for (index, sample) in samples.enumerated() {
                pointer[index] = sample
            }
        }

        tapBlock(buffer, AVAudioTime(hostTime: 0))
    }
}
