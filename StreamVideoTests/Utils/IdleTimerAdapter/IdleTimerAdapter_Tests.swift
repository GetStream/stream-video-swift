//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

final class IdleTimerAdapter_Tests: XCTestCase, @unchecked Sendable {

    private var activeCallSubject: CurrentValueSubject<Call?, Never>! = .init(nil)
    private var mockStreamVideo: MockStreamVideo! = .init()
    private lazy var subject: IdleTimerAdapter! = .init(activeCallSubject.eraseToAnyPublisher())

    override func setUp() {
        super.setUp()
        _ = subject
    }

    override func tearDown() {
        subject = nil
        mockStreamVideo = nil
        activeCallSubject.send(nil)
        activeCallSubject = nil
        super.tearDown()
    }

    // MARK: - hasActiveCall

    func test_hasActiveCall_isTrue_IdleTimerIsDisabled() async {
        activeCallSubject.send(.dummy())

        await fulfilmentInMainActor {
            let result = self.subject.isIdleTimerDisabled == true
            return result
        }
    }

    func test_hasActiveCall_isFalse_IdleTimerIsEnabled() async {
        activeCallSubject.send(nil)

        await fulfilmentInMainActor { self.subject.isIdleTimerDisabled == false }
    }

    func test_hasActiveCall_changesFromFalseToTrue_firstIsEnabledThenDisabled() async {
        activeCallSubject.send(nil)
        await fulfilmentInMainActor { self.subject.isIdleTimerDisabled == false }

        activeCallSubject.send(.dummy())
        await fulfilmentInMainActor { self.subject.isIdleTimerDisabled == true }
    }

    func test_hasActiveCall_changesFromTrueToFalse_firstIsDisabledThenEnabled() async {
        activeCallSubject.send(.dummy())
        activeCallSubject.send(nil)

        await fulfilmentInMainActor { self.subject.isIdleTimerDisabled == false }
    }
}
