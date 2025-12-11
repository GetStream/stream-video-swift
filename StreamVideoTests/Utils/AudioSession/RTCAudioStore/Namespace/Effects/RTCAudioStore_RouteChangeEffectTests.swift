//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCAudioStore_RouteChangeEffectTests: XCTestCase, @unchecked Sendable {

    private var session: RTCAudioSession!
    private var publisher: RTCAudioSessionPublisher!
    private var effect: RTCAudioStore.RouteChangeEffect!
    private var dispatcher: Store<RTCAudioStore.Namespace>.Dispatcher!
    private var dispatchedActions: [[StoreActionBox<RTCAudioStore.Namespace.Action>]]!
    private var dispatcherExpectation: XCTestExpectation?

    override func setUp() {
        super.setUp()
        session = .sharedInstance()
        publisher = .init(session)
        effect = .init(publisher)
        dispatchedActions = []
        dispatcher = .init { [weak self] actions, _, _, _ in
            self?.dispatchedActions.append(actions)
            self?.dispatcherExpectation?.fulfill()
        }
        effect.dispatcher = dispatcher
    }

    override func tearDown() {
        effect.dispatcher = nil
        dispatcherExpectation = nil
        dispatchedActions = nil
        dispatcher = nil
        effect = nil
        publisher = nil
        session = nil
        super.tearDown()
    }

    func test_routeChange_dispatchesSetCurrentRoute() async {
        dispatcherExpectation = expectation(description: "Dispatches setCurrentRoute")
        let reason: AVAudioSession.RouteChangeReason = .noSuitableRouteForCategory
        let previousRoute = AVAudioSessionRouteDescription.dummy()

        publisher.audioSessionDidChangeRoute(
            session,
            reason: reason,
            previousRoute: previousRoute
        )

        await safeFulfillment(of: [dispatcherExpectation!], timeout: 1)

        let actions = dispatchedActions.flatMap { $0.map(\.wrappedValue) }
        guard case let .setCurrentRoute(route) = actions.first else {
            return XCTFail("Expected setCurrentRoute action.")
        }

        let expectedRoute = RTCAudioStore.StoreState.AudioRoute(
            session.currentRoute,
            reason: reason
        )
        XCTAssertEqual(route, expectedRoute)
    }

    func test_nonRouteEvents_doNotDispatch() async {
        let invertedExpectation = expectation(description: "No dispatch")
        invertedExpectation.isInverted = true
        dispatcherExpectation = invertedExpectation

        publisher.audioSessionDidBeginInterruption(session)

        await safeFulfillment(of: [invertedExpectation], timeout: 0.5)
        XCTAssertTrue(dispatchedActions.isEmpty)
    }
}
