//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCAudioStore_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - Properties

    private lazy var subject: RTCAudioStore! = .init()

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init_RTCAudioSessionReducerHasBeenAdded() {
        _ = subject

        XCTAssertNotNil(subject.reducers.first(where: { $0 is RTCAudioSessionReducer }))
    }

    func test_init_stateWasUpdatedCorrectly() async {
        _ = subject

        await fulfillment {
            self.subject.state.prefersNoInterruptionsFromSystemAlerts == true
                && self.subject.state.useManualAudio == true
                && self.subject.state.isAudioEnabled == false
        }
    }
}
