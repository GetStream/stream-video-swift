//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class AdaptiveVideoCapturePolicy_Tests: XCTestCase {

    private lazy var mockCapturer: MockStreamVideoCapturer! = .init()
    private lazy var mockThermalStateObserver: MockThermalStateObserver! = .init()
    private lazy var peerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var subject: AdaptiveVideoCapturePolicy! = .init { false }

    override func tearDown() {
        mockCapturer = nil
        subject = nil
        mockThermalStateObserver = nil
        peerConnectionFactory = nil
        super.tearDown()
    }

    // MARK: - updateCaptureQuality

    // MARK: NeuralEngine exists

    func test_updateCaptureQuality_thermalStateNominalNeuralEngineExists_doesNotUpdateWithPreferredDimensions() async throws {
        try await assertUpdateCaptureQuality(
            thermalState: .nominal,
            neuralEngineExists: true,
            iterationInputs: [.init(width: 1280, height: 720)],
            expectedCallInputs: []
        )
    }

    func test_updateCaptureQuality_thermalStateFairNeuralEngineExists_doesNotUpdateWithPreferredDimensions() async throws {
        try await assertUpdateCaptureQuality(
            thermalState: .fair,
            neuralEngineExists: true,
            iterationInputs: [.init(width: 1280, height: 720)],
            expectedCallInputs: []
        )
    }

    func test_updateCaptureQuality_thermalStateSeriousNeuralEngineExists_updateWithPreferredDimensions() async throws {
        try await assertUpdateCaptureQuality(
            thermalState: .serious,
            neuralEngineExists: true,
            iterationInputs: [.init(width: 1280, height: 720)],
            expectedCallInputs: [.init(width: 1280, height: 720)]
        )
    }

    func test_updateCaptureQuality_thermalStateCriticalNeuralEngineExists_updatesWithPreferredDimensions() async throws {
        try await assertUpdateCaptureQuality(
            thermalState: .serious,
            neuralEngineExists: true,
            iterationInputs: [.init(width: 1280, height: 720)],
            expectedCallInputs: [.init(width: 1280, height: 720)]
        )
    }

    // MARK: NeuralEngine does not exist

    func test_updateCaptureQuality_thermalStateNominalNeuralEngineDoesNotExist_updatesWithPreferredDimensions() async throws {
        try await assertUpdateCaptureQuality(
            thermalState: .nominal,
            neuralEngineExists: false,
            iterationInputs: [.init(width: 1280, height: 720)],
            expectedCallInputs: [.init(width: 1280, height: 720)]
        )
    }

    func test_updateCaptureQuality_thermalStateFairNNeuralEngineDoesNotExist_updatesWithPreferredDimensions() async throws {
        try await assertUpdateCaptureQuality(
            thermalState: .fair,
            neuralEngineExists: false,
            iterationInputs: [.init(width: 1280, height: 720)],
            expectedCallInputs: [.init(width: 1280, height: 720)]
        )
    }

    func test_updateCaptureQuality_thermalStateSeriousNeuralEngineDoesNotExist_updatesWithPreferredDimensions() async throws {
        try await assertUpdateCaptureQuality(
            thermalState: .serious,
            neuralEngineExists: false,
            iterationInputs: [.init(width: 1280, height: 720)],
            expectedCallInputs: [.init(width: 1280, height: 720)]
        )
    }

    func test_updateCaptureQuality_thermalStateCriticalNeuralEngineDoesNotExist_updatesWithPreferredDimensions() async throws {
        try await assertUpdateCaptureQuality(
            thermalState: .serious,
            neuralEngineExists: false,
            iterationInputs: [.init(width: 1280, height: 720)],
            expectedCallInputs: [.init(width: 1280, height: 720)]
        )
    }

    // MARK: Called multiple times with same dimensions

    func test_updateCaptureQuality_sameDimensionsMultipleTimes_updatesWithPreferredDimensionsOnlyOnce() async throws {
        try await assertUpdateCaptureQuality(
            thermalState: .nominal,
            neuralEngineExists: false,
            iterationInputs: [
                .init(width: 1280, height: 720),
                .init(width: 1280, height: 720),
                .init(width: 1280, height: 720),
                .init(width: 1280, height: 720)
            ],
            expectedCallInputs: [.init(width: 1280, height: 720)]
        )
    }

    // MARK: - Private Helpers

    private func makeActiveSession(
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> VideoCaptureSession {
        VideoCaptureSession(
            position: .front,
            localTrack: peerConnectionFactory.mockVideoTrack(forScreenShare: false),
            capturer: mockCapturer
        )
    }

    private func assertUpdateCaptureQuality(
        thermalState: ProcessInfo.ThermalState,
        neuralEngineExists: Bool,
        iterationInputs: [CGSize],
        expectedCallInputs: [CGSize],
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        mockThermalStateObserver.stub(for: \.state, with: thermalState)
        subject = .init { neuralEngineExists }
        let activeSession = try makeActiveSession()

        for iterationInput in iterationInputs {
            try await subject.updateCaptureQuality(
                with: iterationInput,
                for: activeSession
            )
        }

        XCTAssertEqual(
            mockCapturer.timesCalled(.updateCaptureQuality),
            expectedCallInputs.endIndex,
            file: file,
            line: line
        )
        XCTAssertEqual(
            mockCapturer.recordedInputPayload(CGSize.self, for: .updateCaptureQuality),
            expectedCallInputs,
            file: file,
            line: line
        )
    }
}
