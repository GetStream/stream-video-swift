//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCAudioStore_RouteChangeMiddlewareTests: XCTestCase, @unchecked Sendable {

    private var session: RTCAudioSession!
    private var publisher: RTCAudioSessionPublisher!
    private var subject: RTCAudioStore.RouteChangeMiddleware!
    private var dispatched: [[StoreActionBox<RTCAudioStore.Namespace.Action>]]!

    override func setUp() {
        super.setUp()
        session = RTCAudioSession.sharedInstance()
        publisher = .init(session)
        subject = .init(publisher)
        dispatched = []
    }

    override func tearDown() {
        subject.dispatcher = nil
        subject = nil
        publisher = nil
        session = nil
        dispatched = nil
        super.tearDown()
    }

    func test_routeChange_dispatchesSetCurrentRouteAndOverrideActions() {
        let dispatcherExpectation = expectation(description: "Dispatcher called")
        dispatcherExpectation.assertForOverFulfill = false

        subject.dispatcher = .init { [weak self] actions, _, _, _ in
            self?.dispatched.append(actions)
            dispatcherExpectation.fulfill()
        }

        let previousRoute = MockAVAudioSessionRouteDescription(
            outputs: [MockAVAudioSessionPortDescription(portType: .builtInReceiver)]
        )

        publisher.audioSessionDidChangeRoute(
            session,
            reason: .oldDeviceUnavailable,
            previousRoute: previousRoute
        )

        wait(for: [dispatcherExpectation], timeout: 1)

        guard let actions = dispatched.first(where: { $0.count == 2 }) else {
            return XCTFail("Expected dispatched actions.")
        }

        XCTAssertEqual(actions.count, 2)

        guard case let .setCurrentRoute(route) = actions[0].wrappedValue else {
            return XCTFail("Expected first action to be setCurrentRoute.")
        }

        guard
            case let .avAudioSession(.setOverrideOutputAudioPort(port)) = actions[1].wrappedValue
        else {
            return XCTFail("Expected second action to setOverrideOutputAudioPort.")
        }

        let expectedRoute = RTCAudioStore.StoreState.AudioRoute(session.currentRoute)
        XCTAssertEqual(route, expectedRoute)

        let expectedPort: AVAudioSession.PortOverride = expectedRoute.isSpeaker ? .speaker : .none
        XCTAssertEqual(port, expectedPort)
    }
}
