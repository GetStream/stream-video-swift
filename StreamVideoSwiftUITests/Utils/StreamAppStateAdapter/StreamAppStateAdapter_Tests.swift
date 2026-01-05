//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
@testable import StreamVideoSwiftUI
@preconcurrency import XCTest

final class StreamAppStateAdapter_Tests: XCTestCase, @unchecked Sendable {

    private var subject: StreamAppStateAdapter! = .init()

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        super.tearDown()
    }
    
    // MARK: - init

    func test_init_stateIsSetToForeground() {
        XCTAssertEqual(subject.state, .foreground)
    }

    // MARK: - move to foreground

    func test_whenMoveToForegroundIsCalled_stateIsSetToForeground() async {
        await assertApplicationState(initial: .background, target: .foreground)
    }

    // MARK: - move to background

    func test_whenMoveToBackgroundIsCalled_stateIsSetToBackground() async {
        await assertApplicationState(initial: .foreground, target: .background)
    }

    // MARK: - Private Helpers

    @MainActor private func assertApplicationState(
        initial: ApplicationState,
        target: ApplicationState,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let initialNotification = initial == .background
            ? Notification(name: UIApplication.didEnterBackgroundNotification)
            : Notification(name: UIApplication.willEnterForegroundNotification)
        let targetNotification = target == .background
            ? Notification(name: UIApplication.didEnterBackgroundNotification)
            : Notification(name: UIApplication.willEnterForegroundNotification)

        NotificationCenter.default.post(initialNotification)
        await fulfillment(file: file, line: line) { self.subject.state == initial }

        NotificationCenter.default.post(targetNotification)
        await fulfillment(file: file, line: line) { self.subject.state == target }
    }
}
