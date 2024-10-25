//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class AdaptiveVideoCapturePolicy_Tests: XCTestCase {

    private static var thermalStateObserver: MockThermalStateObserver! = .init()

    private lazy var device: AVCaptureDevice! = .init(uniqueID: .unique)
    private lazy var peerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var videoTrack: RTCVideoTrack! = (
        RTCMediaStreamTrack
            .dummy(kind: .video, peerConnectionFactory: peerConnectionFactory) as! RTCVideoTrack
    )
    private lazy var cameraVideoCapturer: MockCameraVideoCapturer! = .init()
    private lazy var activeCaptureSession: VideoCaptureSession! = .init(
        position: .front,
        device: device,
        localTrack: videoTrack,
        capturer: cameraVideoCapturer
    )
    private var subject: AdaptiveVideoCapturePolicy!

    // MARK: - Lifecycle

    override class func tearDown() {
        Self.thermalStateObserver = nil
        InjectedValues[\.thermalStateObserver] = ThermalStateObserver.shared
        super.tearDown()
    }

    override func tearDown() {
        subject = nil
        activeCaptureSession = nil
        cameraVideoCapturer = nil
        videoTrack = nil
        peerConnectionFactory = nil
        device = nil
        super.tearDown()
    }

    // MARK: - updateCaptureQuality

    // MARK: ThermalState: .nominal | neuralEngineExists: false

    func test_updateCaptureQuality_thermalStateNominal_neuralEngineDoesNotExist_fullHalfAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.full, .half, .quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .nominal
        )
    }

    func test_updateCaptureQuality_thermalStateNominal_neuralEngineDoesNotExist_halfAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [
                .half,
                .quarter
            ],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .nominal
        )
    }

    func test_updateCaptureQuality_thermalStateNominal_neuralEngineDoesNotExist_fullAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [
                .full,
                .quarter
            ],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .nominal
        )
    }

    func test_updateCaptureQuality_thermalStateNominal_neuralEngineDoesNotExist_fullEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.full],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .nominal
        )
    }

    func test_updateCaptureQuality_thermalStateNominal_neuralEngineDoesNotExist_halfEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.half],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .nominal
        )
    }

    func test_updateCaptureQuality_thermalStateNominal_neuralEngineDoesNotExist_quarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .nominal
        )
    }

    func test_updateCaptureQuality_thermalStateNominal_neuralEngineDoesNotExist_quarterEncodingsMatchTheCurrentlyActiveOnes_capturerWasNotCalledASecondTime(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .nominal
        )

        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .nominal
        )
    }

    // MARK: ThermalState: .nominal | neuralEngineExists: true

    func test_updateCaptureQuality_thermalStateNominal_neuralEngineExists_fullHalfAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.full, .half, .quarter],
            expectedTimesCalled: 0,
            neuralEngineExists: true,
            thermalState: .nominal
        )
    }

    func test_updateCaptureQuality_thermalStateNominal_neuralEngineExists_halfAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [
                .half,
                .quarter
            ],
            expectedTimesCalled: 0,
            neuralEngineExists: true,
            thermalState: .nominal
        )
    }

    func test_updateCaptureQuality_thermalStateNominal_neuralEngineExists_fullAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [
                .full,
                .quarter
            ],
            expectedTimesCalled: 0,
            neuralEngineExists: true,
            thermalState: .nominal
        )
    }

    func test_updateCaptureQuality_thermalStateNominal_neuralEngineExists_fullEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.full],
            expectedTimesCalled: 0,
            neuralEngineExists: true,
            thermalState: .nominal
        )
    }

    func test_updateCaptureQuality_thermalStateNominal_neuralEngineExists_halfEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.half],
            expectedTimesCalled: 0,
            neuralEngineExists: true,
            thermalState: .nominal
        )
    }

    func test_updateCaptureQuality_thermalStateNominal_neuralEngineExists_quarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 0,
            neuralEngineExists: true,
            thermalState: .nominal
        )
    }

    func test_updateCaptureQuality_thermalStateNominal_neuralEngineExists_quarterEncodingsMatchTheCurrentlyActiveOnes_capturerWasNotCalledASecondTime(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 0,
            neuralEngineExists: true,
            thermalState: .nominal
        )

        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 0,
            neuralEngineExists: true,
            thermalState: .nominal
        )
    }

    // MARK: ThermalState: .fair | neuralEngineExists: false

    func test_updateCaptureQuality_thermalStateFair_neuralEngineDoesNotExist_fullHalfAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.full, .half, .quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .fair
        )
    }

    func test_updateCaptureQuality_thermalStateFair_neuralEngineDoesNotExist_halfAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [
                .half,
                .quarter
            ],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .fair
        )
    }

    func test_updateCaptureQuality_thermalStateFair_neuralEngineDoesNotExist_fullAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [
                .full,
                .quarter
            ],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .fair
        )
    }

    func test_updateCaptureQuality_thermalStateFair_neuralEngineDoesNotExist_fullEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.full],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .fair
        )
    }

    func test_updateCaptureQuality_thermalStateFair_neuralEngineDoesNotExist_halfEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.half],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .fair
        )
    }

    func test_updateCaptureQuality_thermalStateFair_neuralEngineDoesNotExist_quarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .fair
        )
    }

    func test_updateCaptureQuality_thermalStateFair_neuralEngineDoesNotExist_quarterEncodingsMatchTheCurrentlyActiveOnes_capturerWasNotCalledASecondTime(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .fair
        )

        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .fair
        )
    }

    // MARK: ThermalState: .fair | neuralEngineExists: true

    func test_updateCaptureQuality_thermalStateFair_neuralEngineExists_fullHalfAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.full, .half, .quarter],
            expectedTimesCalled: 0,
            neuralEngineExists: true,
            thermalState: .fair
        )
    }

    func test_updateCaptureQuality_thermalStateFair_neuralEngineExists_halfAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [
                .half,
                .quarter
            ],
            expectedTimesCalled: 0,
            neuralEngineExists: true,
            thermalState: .fair
        )
    }

    func test_updateCaptureQuality_thermalStateFair_neuralEngineExists_fullAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [
                .full,
                .quarter
            ],
            expectedTimesCalled: 0,
            neuralEngineExists: true,
            thermalState: .fair
        )
    }

    func test_updateCaptureQuality_thermalStateFair_neuralEngineExists_fullEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.full],
            expectedTimesCalled: 0,
            neuralEngineExists: true,
            thermalState: .fair
        )
    }

    func test_updateCaptureQuality_thermalStateFair_neuralEngineExists_halfEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.half],
            expectedTimesCalled: 0,
            neuralEngineExists: true,
            thermalState: .fair
        )
    }

    func test_updateCaptureQuality_thermalStateFair_neuralEngineExists_quarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 0,
            neuralEngineExists: true,
            thermalState: .fair
        )
    }

    func test_updateCaptureQuality_thermalStateFair_neuralEngineExists_quarterEncodingsMatchTheCurrentlyActiveOnes_capturerWasNotCalledASecondTime(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 0,
            neuralEngineExists: true,
            thermalState: .fair
        )

        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 0,
            neuralEngineExists: true,
            thermalState: .fair
        )
    }

    // MARK: thermalState: .serious | neuralEngineExists: false

    func test_updateCaptureQuality_thermalStateSerious_neuralEngineDoesNotExist_fullHalfAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.full, .half, .quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .serious
        )
    }

    func test_updateCaptureQuality_thermalStateSerious_neuralEngineDoesNotExist_halfAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [
                .half,
                .quarter
            ],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .serious
        )
    }

    func test_updateCaptureQuality_thermalStateSerious_neuralEngineDoesNotExist_fullAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [
                .full,
                .quarter
            ],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .serious
        )
    }

    func test_updateCaptureQuality_thermalStateSerious_neuralEngineDoesNotExist_fullEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.full],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .serious
        )
    }

    func test_updateCaptureQuality_thermalStateSerious_neuralEngineDoesNotExist_halfEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.half],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .serious
        )
    }

    func test_updateCaptureQuality_thermalStateSerious_neuralEngineDoesNotExist_quarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .serious
        )
    }

    func test_updateCaptureQuality_thermalStateSerious_neuralEngineDoesNotExist_quarterEncodingsMatchTheCurrentlyActiveOnes_capturerWasNotCalledASecondTime(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .serious
        )

        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .serious
        )
    }

    // MARK: thermalState: .serious | neuralEngineExists: true

    func test_updateCaptureQuality_thermalStateSerious_neuralEngineExists_fullHalfAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.full, .half, .quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: true,
            thermalState: .serious
        )
    }

    func test_updateCaptureQuality_thermalStateSerious_neuralEngineExists_halfAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [
                .half,
                .quarter
            ],
            expectedTimesCalled: 1,
            neuralEngineExists: true,
            thermalState: .serious
        )
    }

    func test_updateCaptureQuality_thermalStateSerious_neuralEngineExists_fullAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [
                .full,
                .quarter
            ],
            expectedTimesCalled: 1,
            neuralEngineExists: true,
            thermalState: .serious
        )
    }

    func test_updateCaptureQuality_thermalStateSerious_neuralEngineExists_fullEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.full],
            expectedTimesCalled: 1,
            neuralEngineExists: true,
            thermalState: .serious
        )
    }

    func test_updateCaptureQuality_thermalStateSerious_neuralEngineExists_halfEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.half],
            expectedTimesCalled: 1,
            neuralEngineExists: true,
            thermalState: .serious
        )
    }

    func test_updateCaptureQuality_thermalStateSerious_neuralEngineExists_quarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: true,
            thermalState: .serious
        )
    }

    func test_updateCaptureQuality_thermalStateSerious_neuralEngineExists_quarterEncodingsMatchTheCurrentlyActiveOnes_capturerWasNotCalledASecondTime(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: true,
            thermalState: .serious
        )

        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: true,
            thermalState: .serious
        )
    }

    // MARK: thermalState: .critical | neuralEngineExists: false

    func test_updateCaptureQuality_thermalStateCritical_neuralEngineDoesNotExist_fullHalfAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.full, .half, .quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .critical
        )
    }

    func test_updateCaptureQuality_thermalStateCritical_neuralEngineDoesNotExist_halfAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [
                .half,
                .quarter
            ],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .critical
        )
    }

    func test_updateCaptureQuality_thermalStateCritical_neuralEngineDoesNotExist_fullAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [
                .full,
                .quarter
            ],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .critical
        )
    }

    func test_updateCaptureQuality_thermalStateCritical_neuralEngineDoesNotExist_fullEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.full],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .critical
        )
    }

    func test_updateCaptureQuality_thermalStateCritical_neuralEngineDoesNotExist_halfEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.half],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .critical
        )
    }

    func test_updateCaptureQuality_thermalStateCritical_neuralEngineDoesNotExist_quarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .critical
        )
    }

    func test_updateCaptureQuality_thermalStateCritical_neuralEngineDoesNotExist_quarterEncodingsMatchTheCurrentlyActiveOnes_capturerWasNotCalledASecondTime(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .critical
        )

        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: false,
            thermalState: .critical
        )
    }

    // MARK: thermalState: .critical | neuralEngineExists: true

    func test_updateCaptureQuality_thermalStateCritical_neuralEngineExists_fullHalfAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.full, .half, .quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: true,
            thermalState: .critical
        )
    }

    func test_updateCaptureQuality_thermalStateCritical_neuralEngineExists_halfAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [
                .half,
                .quarter
            ],
            expectedTimesCalled: 1,
            neuralEngineExists: true,
            thermalState: .critical
        )
    }

    func test_updateCaptureQuality_thermalStateCritical_neuralEngineExists_fullAndQuarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [
                .full,
                .quarter
            ],
            expectedTimesCalled: 1,
            neuralEngineExists: true,
            thermalState: .critical
        )
    }

    func test_updateCaptureQuality_thermalStateCritical_neuralEngineExists_fullEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.full],
            expectedTimesCalled: 1,
            neuralEngineExists: true,
            thermalState: .critical
        )
    }

    func test_updateCaptureQuality_thermalStateCritical_neuralEngineExists_halfEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.half],
            expectedTimesCalled: 1,
            neuralEngineExists: true,
            thermalState: .critical
        )
    }

    func test_updateCaptureQuality_thermalStateCritical_neuralEngineExists_quarterEncodingsAreActive_capturerWasCalledWithExpectedVideoCodec(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: true,
            thermalState: .critical
        )
    }

    func test_updateCaptureQuality_thermalStateCritical_neuralEngineExists_quarterEncodingsMatchTheCurrentlyActiveOnes_capturerWasNotCalledASecondTime(
    ) async throws {
        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: true,
            thermalState: .critical
        )

        try await assertUpdateCaptureQuality(
            expected: [.quarter],
            expectedTimesCalled: 1,
            neuralEngineExists: true,
            thermalState: .critical
        )
    }

    // MARK: - Private helpers

    private func assertUpdateCaptureQuality(
        expected: [VideoLayer],
        expectedTimesCalled: Int,
        neuralEngineExists: Bool,
        thermalState: ProcessInfo.ThermalState,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        if subject == nil {
            subject = .init { neuralEngineExists }
        }
        Self.thermalStateObserver.stub(for: \.state, with: thermalState)

        try await subject.updateCaptureQuality(
            with: .init(
                expected.map(\.quality.rawValue)
            ),
            for: activeCaptureSession
        )

        XCTAssertEqual(
            cameraVideoCapturer.timesCalled(.updateCaptureQuality),
            expectedTimesCalled,
            file: file,
            line: line
        )

        if expectedTimesCalled > 0 {
            XCTAssertEqual(
                cameraVideoCapturer.recordedInputPayload(([VideoLayer], AVCaptureDevice?).self, for: .updateCaptureQuality)?.first?
                    .0
                    .map(\.quality.rawValue).sorted(),
                expected.map(\.quality.rawValue).sorted(),
                file: file,
                line: line
            )
        }
    }
}
