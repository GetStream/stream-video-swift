//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

final class WebRTCAudioSessionWatchdog_Tests: XCTestCase, @unchecked Sendable {

    private var mockAudioStore: MockRTCAudioStore!
    private var disposableBag: DisposableBag! = .init()
    private lazy var subject: WebRTCAudioSessionWatchdog! = .init()

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        mockAudioStore = .init()
        mockAudioStore.makeShared()
    }

    override func tearDown() {
        disposableBag.removeAll()
        mockAudioStore.dismantle()
        subject = nil
        mockAudioStore = nil
        super.tearDown()
    }

    // MARK: - tests

    func test_init_isReadyIsFalse() async {
        await fulfillment { self.subject.isReady == false }
    }

    func test_publisher_whenAudioSessionBecomesReady_emitsTrue() async {
        let expectation = expectation(description: "Readiness emits true.")
        var latestValue = false

        subject
            .publisher
            .sink { value in
                latestValue = value
                if value {
                    expectation.fulfill()
                }
            }
            .store(in: disposableBag)

        mockAudioStore.audioStore.dispatch(.setActive(true))
        mockAudioStore.audioStore.dispatch(
            .setCurrentRoute(.dummy(inputs: [.dummy()]))
        )

        await fulfillment(of: [expectation], timeout: defaultTimeout)
        XCTAssertTrue(latestValue)
        XCTAssertTrue(subject.isReady)
    }

    func test_publisher_whenReadyStateRepeated_emitsTrueOnlyOnce() async {
        let expectation = expectation(description: "Readiness emits first true.")
        var trueEventsCount = 0
        let route = RTCAudioStore.StoreState.AudioRoute.dummy(inputs: [.dummy()])

        subject
            .publisher
            .sink { value in
                guard value else { return }
                trueEventsCount += 1
                if trueEventsCount == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: disposableBag)

        mockAudioStore.audioStore.dispatch(.setActive(true))
        mockAudioStore.audioStore.dispatch(.setCurrentRoute(route))

        await fulfillment(of: [expectation], timeout: defaultTimeout)

        mockAudioStore.audioStore.dispatch(.setActive(true))
        mockAudioStore.audioStore.dispatch(.setCurrentRoute(route))
        await wait(for: 0.2)

        XCTAssertEqual(trueEventsCount, 1)
    }
}
