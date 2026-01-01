//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

#if os(iOS)
@MainActor
final class IOSBackgroundTaskScheduler_Tests: XCTestCase, @unchecked Sendable {
    func test_notifications_foreground() {
        // Given
        let scheduler = IOSBackgroundTaskScheduler()
        var calledBackground = false
        var calledForeground = false
        scheduler.startListeningForAppStateUpdates(
            onEnteringBackground: { calledBackground = true },
            onEnteringForeground: { calledForeground = true }
        )

        // When
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        // Then
        XCTAssertTrue(calledForeground)
        XCTAssertFalse(calledBackground)
    }

    func test_notifications_background() {
        // Given
        let scheduler = IOSBackgroundTaskScheduler()
        var calledBackground = false
        var calledForeground = false
        scheduler.startListeningForAppStateUpdates(
            onEnteringBackground: { calledBackground = true },
            onEnteringForeground: { calledForeground = true }
        )

        // When
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)

        // Then
        XCTAssertFalse(calledForeground)
        XCTAssertTrue(calledBackground)
    }
}
#endif
