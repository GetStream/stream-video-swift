//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

#if os(iOS)
final class IOSBackgroundTaskScheduler_Tests: XCTestCase {
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

    func test_whenSchedulerIsDeallocated_backgroundTaskIsEnded() {
        // Create mock scheduler type and catch `endTask` invokation
        class MockScheduler: IOSBackgroundTaskScheduler {
            let endTaskClosure: () -> Void

            init(endTaskClosure: @escaping () -> Void) {
                self.endTaskClosure = endTaskClosure
            }

            override func endTask() {
                endTaskClosure()
            }
        }

        // Create mock scheduler and catch `endTask`
        var endTaskCalled = false
        var scheduler: MockScheduler? = MockScheduler {
            endTaskCalled = true
        }

        // Assert `endTask` is not called yet
        XCTAssertFalse(endTaskCalled)

        // Remove all strong refs to scheduler
        scheduler = nil

        // Assert `endTask` is called
        XCTAssertTrue(endTaskCalled)

        // Simulate access to scheduler to eliminate the warning
        _ = scheduler
    }
}
#endif
