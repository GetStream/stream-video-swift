//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

final class ThermalStateObserverTests: XCTestCase, @unchecked Sendable {

    private var stubThermalState: ProcessInfo.ThermalState = .nominal
    private lazy var subject: ThermalStateObserver! = .init { self.stubThermalState }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init_stateHasBeenCorrectlySetUp() {
        XCTAssertEqual(ThermalStateObserver().state, ProcessInfo.processInfo.thermalState)
    }

    // MARK: - notificationObserver

    func test_notificationObserver_stateChangesWhenSystemPostsNotification() {
        func assertThermalState(
            _ expected: ProcessInfo.ThermalState,
            file: StaticString = #file,
            line: UInt = #line
        ) {
            stubThermalState = expected

            let expectation = self.expectation(description: "Notification was received")
            var cancellable: AnyCancellable?
            cancellable = subject
                .$state
                .dropFirst()
                .sink {
                    XCTAssertEqual($0, expected, file: file, line: line)
                    expectation.fulfill()
                    cancellable?.cancel()
                }

            NotificationCenter
                .default
                .post(.init(name: ProcessInfo.thermalStateDidChangeNotification))

            wait(for: [expectation], timeout: defaultTimeout)
        }

        assertThermalState(.fair)
        assertThermalState(.serious)
        assertThermalState(.critical)
        assertThermalState(.nominal)
    }

    // MARK: - scale

    func test_scale_hasExpectedValueForEachThermalState() {
        func assertScale(
            _ thermalState: ProcessInfo.ThermalState,
            expected: CGFloat,
            file: StaticString = #file,
            line: UInt = #line
        ) {
            stubThermalState = thermalState

            let expectation = self.expectation(description: "Notification was received")
            var cancellable: AnyCancellable?
            cancellable = subject
                .$state
                .dropFirst()
                .receive(on: DispatchQueue.main)
                .sink { [subject] _ in
                    XCTAssertEqual(subject?.scale, expected, file: file, line: line)
                    expectation.fulfill()
                    cancellable?.cancel()
                }

            NotificationCenter
                .default
                .post(.init(name: ProcessInfo.thermalStateDidChangeNotification))

            wait(for: [expectation], timeout: defaultTimeout)
        }

        assertScale(.nominal, expected: 1)
        assertScale(.fair, expected: 1.5)
        assertScale(.serious, expected: 2)
        assertScale(.critical, expected: 4)
    }
}
