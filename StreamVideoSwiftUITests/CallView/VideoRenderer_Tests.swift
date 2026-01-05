//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class VideoRenderer_Tests: XCTestCase, @unchecked Sendable {

    private lazy var thermalStateSubject: PassthroughSubject<ProcessInfo.ThermalState, Never>! = .init()
    private lazy var mockThermalStateObserver: MockThermalStateObserver! = .init()
    private lazy var maximumFramesPerSecond: Int! = UIScreen.main.maximumFramesPerSecond
    private lazy var subject: VideoRenderer! = .init(frame: .zero)

    override func tearDown() async throws {
        InjectedValues[\.thermalStateObserver] = ThermalStateObserver { .nominal }
        thermalStateSubject = nil
        mockThermalStateObserver = nil
        maximumFramesPerSecond = nil
        subject = nil
        try await super.tearDown()
    }

    // MARK: - preferredFramesPerSecond

    func testFPSForNominalThermalState() async {
        await assertPreferredFramesPerSecond(
            thermalState: .nominal,
            expected: Double(maximumFramesPerSecond)
        )
    }

    func testFPSForFairThermalState() async {
        await assertPreferredFramesPerSecond(
            thermalState: .fair,
            expected: Double(maximumFramesPerSecond)
        )
    }

    func testFPSForSeriousThermalState() async {
        await assertPreferredFramesPerSecond(
            thermalState: .serious,
            expected: Double(maximumFramesPerSecond) * 0.5
        )
    }

    func testFPSForCriticalThermalState() async {
        await assertPreferredFramesPerSecond(
            thermalState: .critical,
            expected: Double(maximumFramesPerSecond) * 0.4
        )
    }

    // MARK: - Private helpers

    private func assertPreferredFramesPerSecond(
        thermalState: ProcessInfo.ThermalState,
        expected: Double,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        mockThermalStateObserver.stub(
            for: \.statePublisher,
            with: thermalStateSubject.eraseToAnyPublisher()
        )
        _ = subject
        thermalStateSubject.send(thermalState)

        await fulfilmentInMainActor { [subject] in
            subject?.preferredFramesPerSecond == Int(expected)
        }
    }
}
