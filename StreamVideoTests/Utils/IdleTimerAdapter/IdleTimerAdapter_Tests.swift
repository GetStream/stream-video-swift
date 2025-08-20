//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class IdleTimerAdapter_Tests: XCTestCase, @unchecked Sendable {

    private var mockStreamVideo: MockStreamVideo! = .init()
    private lazy var subject: IdleTimerAdapter! = .init(mockStreamVideo)

    override func setUp() {
        super.setUp()
        _ = subject
    }

    override func tearDown() {
        subject = nil
        mockStreamVideo = nil
        super.tearDown()
    }

    // MARK: - hasActiveCall

    func test_hasActiveCall_isTrue_IdleTimerIsDisabled() async {
        mockStreamVideo.state.activeCall = .dummy()

        await fulfilmentInMainActor { self.subject.isIdleTimerDisabled == true }
    }

    func test_hasActiveCall_isFalse_IdleTimerIsEnabled() async {
        mockStreamVideo.state.activeCall = nil

        await fulfilmentInMainActor { self.subject.isIdleTimerDisabled == false }
    }

    func test_hasActiveCall_changesFromFalseToTrue_firstIsEnabledThenDisabled() async {
        mockStreamVideo.state.activeCall = nil
        await fulfilmentInMainActor { self.subject.isIdleTimerDisabled == false }

        mockStreamVideo.state.activeCall = .dummy()
        await fulfilmentInMainActor { self.subject.isIdleTimerDisabled == true }
    }

    func test_hasActiveCall_changesFromTrueToFalse_firstIsDisabledThenEnabled() async {
        mockStreamVideo.state.activeCall = .dummy()
        await fulfilmentInMainActor { self.subject.isIdleTimerDisabled == true }

        mockStreamVideo.state.activeCall = nil
        await fulfilmentInMainActor { self.subject.isIdleTimerDisabled == false }
    }
}
