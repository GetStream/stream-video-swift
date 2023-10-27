//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import StreamSwiftTestHelpers
import XCTest
import Combine

final class VideoRenderer_Tests: XCTestCase {

    private var mockThermalStateObserver: MockThermalStateObserver! = .init()
    private var subject: VideoRenderer!

    override func setUp() {
        super.setUp()

        InjectedValues[\.thermalStateObserver] = mockThermalStateObserver
        subject = .init(frame: .zero)
    }

    override func tearDown() {
        mockThermalStateObserver = nil
        super.tearDown()
    }

    // MARK: - preferredFramesPerSecond

    func testFPSForNominalThermalState() {
        mockThermalStateObserver.state = .nominal
        XCTAssertEqual(subject.preferredFramesPerSecond, UIScreen.main.maximumFramesPerSecond)
    }

    func testFPSForFairThermalState() {
        mockThermalStateObserver.state = .fair
        XCTAssertEqual(subject.preferredFramesPerSecond, UIScreen.main.maximumFramesPerSecond)
    }

    func testFPSForSeriousThermalState() {
        mockThermalStateObserver.state = .serious
        XCTAssertEqual(subject.preferredFramesPerSecond, Int(Double(UIScreen.main.maximumFramesPerSecond) * 0.5))
    }

    func testFPSForCriticalThermalState() {
        mockThermalStateObserver.state = .critical
        XCTAssertEqual(subject.preferredFramesPerSecond, Int(Double(UIScreen.main.maximumFramesPerSecond) * 0.4))
    }
}

// MARK: - Private Helpers

private final class MockThermalStateObserver: ThermalStateObserving {
    var state: ProcessInfo.ThermalState = .nominal { didSet { stateSubject.send(state) } }
    lazy var stateSubject: CurrentValueSubject<ProcessInfo.ThermalState, Never> = .init(state)
    var statePublisher: AnyPublisher<ProcessInfo.ThermalState, Never> { stateSubject.eraseToAnyPublisher() }
    var scale: CGFloat = 1
}
