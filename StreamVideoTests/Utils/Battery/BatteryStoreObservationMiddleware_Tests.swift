//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

#if canImport(UIKit)
import UIKit

@testable import StreamVideo
import XCTest

final class BatteryStoreObservationMiddleware_Tests: XCTestCase, @unchecked Sendable {

    func test_batteryStateNotification_dispatchesSetState() async {
        let expectation = expectation(description: "Dispatch setState")
        let middleware = BatteryStore.Namespace.ObservationMiddleware()
        let collector = ActionCollector(expectation: expectation) { action in
            if case .setState = action {
                return true
            }
            return false
        }

        middleware.dispatcher = .init { actions, _, _, _ in
            collector.handle(actions.map(\.wrappedValue))
        }

        await MainActor.run {
            UIDevice.current.isBatteryMonitoringEnabled = true
            NotificationCenter
                .default
                .post(name: UIDevice.batteryStateDidChangeNotification, object: nil)
        }

        await fulfillment(of: [expectation], timeout: 1.0)
        withExtendedLifetime(middleware) {}
    }

    func test_batteryLevelNotification_dispatchesSetLevel() async {
        let expectation = expectation(description: "Dispatch setLevel")
        let middleware = BatteryStore.Namespace.ObservationMiddleware()
        let collector = ActionCollector(expectation: expectation) { action in
            if case .setLevel = action {
                return true
            }
            return false
        }

        middleware.dispatcher = .init { actions, _, _, _ in
            collector.handle(actions.map(\.wrappedValue))
        }

        await MainActor.run {
            UIDevice.current.isBatteryMonitoringEnabled = true
            NotificationCenter
                .default
                .post(name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        }

        await fulfillment(of: [expectation], timeout: 1.0)
        withExtendedLifetime(middleware) {}
    }
}

private final class ActionCollector: @unchecked Sendable {
    private let expectation: XCTestExpectation
    private let matcher: (BatteryStore.Namespace.Action) -> Bool

    init(
        expectation: XCTestExpectation,
        matcher: @escaping (BatteryStore.Namespace.Action) -> Bool
    ) {
        self.expectation = expectation
        self.matcher = matcher
    }

    func handle(_ actions: [BatteryStore.Namespace.Action]) {
        guard expectation.isInverted == false else { return }
        if actions.contains(where: matcher) {
            expectation.fulfill()
        }
    }
}
#endif
