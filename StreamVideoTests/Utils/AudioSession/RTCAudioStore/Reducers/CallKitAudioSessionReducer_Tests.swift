//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class CallKitAudioSessionReducer_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - Properties

    private lazy var store: MockRTCAudioStore! = .init()
    private lazy var subject: CallKitAudioSessionReducer! = .init(
        store: store.audioStore
    )

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        store = nil
        super.tearDown()
    }

    // MARK: - reduce
    
    // MARK: activate

    func test_reduce_callKitAction_activate_audioSessionDidActivateWasCalled() throws {
        _ = try subject.reduce(
            state: .initial,
            action: .callKit(.activate(.sharedInstance())),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(store.session.timesCalled(.audioSessionDidActivate), 1)
    }

    func test_reduce_callKitAction_activate_isActiveUpdatedToMatchSessionIsActive() throws {
        store.session.isActive = true

        let updatedState = try subject.reduce(
            state: .initial,
            action: .callKit(.deactivate(.sharedInstance())),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(updatedState.isActive)
    }

    // MARK: deactivate

    func test_reduce_callKitAction_deactivate_audioSessionDidDeactivateWasCalled() throws {
        _ = try subject.reduce(
            state: .initial,
            action: .callKit(.deactivate(.sharedInstance())),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(store.session.timesCalled(.audioSessionDidDeactivate), 1)
    }

    func test_reduce_callKitAction_deactivate_isActiveUpdatedToMatchSessionIsActive() throws {
        store.session.isActive = false

        let updatedState = try subject.reduce(
            state: .initial,
            action: .callKit(.deactivate(.sharedInstance())),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertFalse(updatedState.isActive)
    }
}
