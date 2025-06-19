//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class IdleTimerAdapter_Tests: XCTestCase, @unchecked Sendable {

    private var mockActiveCallProvider: MockActiveCallProvider! = .init()
    private lazy var subject: IdleTimerAdapter! = .init(mockActiveCallProvider)

    override func setUp() {
        super.setUp()
        _ = subject
    }

    override func tearDown() {
        subject = nil
        mockActiveCallProvider = nil
        super.tearDown()
    }

    // MARK: - hasActiveCall

    func test_hasActiveCall_isTrue_IdleTimerIsDisabled() async {
        mockActiveCallProvider.subject.send(true)

        await fulfilmentInMainActor { self.subject.isIdleTimerDisabled == true }
    }

    func test_hasActiveCall_isFalse_IdleTimerIsEnabled() async {
        mockActiveCallProvider.subject.send(false)

        await fulfilmentInMainActor { self.subject.isIdleTimerDisabled == false }
    }

    func test_hasActiveCall_changesFromFalseToTrue_firstIsEnabledThenDisabled() async {
        mockActiveCallProvider.subject.send(false)
        await fulfilmentInMainActor { self.subject.isIdleTimerDisabled == false }

        mockActiveCallProvider.subject.send(true)
        await fulfilmentInMainActor { self.subject.isIdleTimerDisabled == true }
    }

    func test_hasActiveCall_changesFromTrueToFalse_firstIsDisabledThenEnabled() async {
        mockActiveCallProvider.subject.send(true)
        await fulfilmentInMainActor { self.subject.isIdleTimerDisabled == true }

        mockActiveCallProvider.subject.send(false)
        await fulfilmentInMainActor { self.subject.isIdleTimerDisabled == false }
    }
}
