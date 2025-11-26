//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCAudioStore_Tests: XCTestCase, @unchecked Sendable {

    private var session: RTCAudioSession!
    private var subject: RTCAudioStore!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        session = .sharedInstance()
        subject = .init(audioSession: session)
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        subject = nil
        session = nil
        super.tearDown()
    }

    func test_init_appliesInitialWebRTCConfiguration() async {
        await fulfillment {
            let configuration = self.subject.state.webRTCAudioSessionConfiguration
            return configuration.prefersNoInterruptionsFromSystemAlerts
                && configuration.useManualAudio
                && configuration.isAudioEnabled == false
        }
    }

    func test_dispatch_singleAction_updatesState() async {
        subject.dispatch(.setInterrupted(true))

        await fulfillment {
            self.subject.state.isInterrupted
        }

        subject.dispatch(.setInterrupted(false))

        await fulfillment {
            self.subject.state.isInterrupted == false
        }
    }

    func test_dispatch_multipleActions_updatesState() async {
        subject.dispatch([
            .setInterrupted(true)
        ])

        await fulfillment {
            self.subject.state.isInterrupted
        }
    }

    func test_publisher_emitsDistinctValues() async {
        let expectation = expectation(description: "Publisher emitted value")

        subject
            .publisher(\.isInterrupted)
            .dropFirst()
            .sink { value in
                if value {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        subject.dispatch(.setInterrupted(true))

        await safeFulfillment(of: [expectation])
    }
}
