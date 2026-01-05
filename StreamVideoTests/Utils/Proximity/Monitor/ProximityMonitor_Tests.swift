//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class ProximityMonitor_Tests: XCTestCase, @unchecked Sendable {
    private lazy var subject: ProximityMonitor! = ProximityMonitor()

    override func tearDown() async throws {
        subject = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_init_initialStateIsFar() {
        XCTAssertEqual(subject.state, .far)
    }

    // MARK: - Observation Tests

    // MARK: startObservation

    func test_startObservation_deviceTypeIsUnspecified_isActiveFalse() async {
        await assertIsActive(for: .unspecified, expected: false)
    }

    func test_startObservation_deviceTypeIsPhone_isActiveTrue() async {
        await assertIsActive(for: .phone, expected: true)
    }

    func test_startObservation_deviceTypeIsPad_isActiveFalse() async {
        await assertIsActive(for: .pad, expected: false)
    }

    func test_startObservation_deviceTypeIsTV_isActiveFalse() async {
        await assertIsActive(for: .tv, expected: false)
    }

    func test_startObservation_deviceTypeIsCarPlay_isActiveFalse() async {
        await assertIsActive(for: .carPlay, expected: false)
    }

    func test_startObservation_deviceTypeIsMac_isActiveFalse() async {
        await assertIsActive(for: .mac, expected: false)
    }

    func test_startObservation_deviceTypeIsVision_isActiveFalse() async {
        await assertIsActive(for: .vision, expected: false)
    }

    // MARK: stopObservation

    @MainActor
    func test_stopObservation_isActiveBecomesFalse() async {
        CurrentDevice.currentValue.didUpdate(.phone)
        await fulfillment { CurrentDevice.currentValue.deviceType == .phone }

        subject.startObservation()
        XCTAssertTrue(subject.isActive)

        subject.stopObservation()

        XCTAssertFalse(subject.isActive)
    }

    // MARK: - Private Helpers

    private func assertIsActive(
        for deviceType: CurrentDevice.DeviceType,
        expected: Bool,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async {
        _ = CurrentDevice.currentValue
        await wait(for: 0.5)
        CurrentDevice.currentValue.didUpdate(deviceType)
        await fulfilmentInMainActor { CurrentDevice.currentValue.deviceType == deviceType }
        _ = subject

        await subject.startObservation()

        await fulfilmentInMainActor { self.subject.isActive == expected }
    }
}
