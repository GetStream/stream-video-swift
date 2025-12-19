//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class InternetConnection_Tests: XCTestCase, @unchecked Sendable {
    private var monitor: InternetConnectionMonitor_Mock! = .init()
    private lazy var subject: InternetConnection! = .init(monitor: monitor)

    override func setUp() async throws {
        try await super.setUp()
        _ = subject
        await fulfillment { self.subject.status == .available(.great) }
    }

    override func tearDown() {
        monitor = nil
        subject = nil
        super.tearDown()
    }

    func test_internetConnection_init() {
        // Assert status matches ther monitor
        XCTAssertEqual(subject.status, monitor.status)

        // Assert internet connection is set as a delegate
        XCTAssertTrue(monitor.delegate === subject)
    }

    func test_internetConnection_postsStatusAndAvailabilityNotifications_whenAvailabilityChanges() {
        // Set unavailable status
        monitor.status = .unavailable

        // Create new status
        let newStatus: InternetConnectionStatus = .available(.great)

        // Set up expectations for notifications
        let notificationExpectations = [
            expectation(
                forNotification: .internetConnectionStatusDidChange,
                object: subject,
                handler: { $0.internetConnectionStatus == newStatus }
            ),
            expectation(
                forNotification: .internetConnectionAvailabilityDidChange,
                object: subject,
                handler: { $0.internetConnectionStatus == newStatus }
            )
        ]

        // Simulate status update
        monitor.status = newStatus

        // Assert status is updated
        XCTAssertEqual(subject.status, newStatus)

        // Assert both notifications are posted
        wait(for: notificationExpectations, timeout: defaultTimeout)
    }

    func test_internetConnection_postsStatusNotification_whenQualityChanges() {
        // Set status
        monitor.status = .available(.constrained)

        // Create status with another quality
        let newStatus: InternetConnectionStatus = .available(.great)

        // Set up expectation for a notification
        let notificationExpectation = expectation(
            forNotification: .internetConnectionStatusDidChange,
            object: subject,
            handler: { $0.internetConnectionStatus == newStatus }
        )

        // Simulate quality update
        monitor.status = newStatus

        // Assert status is updated
        XCTAssertEqual(subject.status, newStatus)

        // Assert both notifications are posted
        wait(for: [notificationExpectation], timeout: defaultTimeout)
    }

    func test_internetConnection_stopsMonitorWhenDeallocated() throws {
        assert(monitor.isStarted)

        subject = nil
        XCTAssertFalse(monitor.isStarted)
    }
}
