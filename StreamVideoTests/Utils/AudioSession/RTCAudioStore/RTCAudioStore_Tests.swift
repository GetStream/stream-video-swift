//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

    func test_stateDescription_usesStableScalarAudioSessionValues() {
        let configuration = subject.state.audioSessionConfiguration

        let description = String(describing: subject.state)

        XCTAssertTrue(
            description.contains("category:\(configuration.category.description)")
        )
        XCTAssertTrue(
            description.contains("mode:\(configuration.mode.description)")
        )
        XCTAssertTrue(
            description.contains("options:\(configuration.options.description)")
        )
        XCTAssertTrue(
            description.contains(
                "overrideOutputAudioPort:\(configuration.overrideOutputAudioPort.description)"
            )
        )
    }

    func test_audioSessionConfigurationDescription_usesStableScalarValues() {
        let subject = AudioSessionConfiguration(
            isActive: true,
            category: .playAndRecord,
            mode: .videoChat,
            options: [.defaultToSpeaker, .allowBluetoothA2DP],
            overrideOutputAudioPort: .speaker
        )

        let description = subject.description

        XCTAssertTrue(description.contains("isActive:true"))
        XCTAssertTrue(
            description.contains("category:\(subject.category.description)")
        )
        XCTAssertTrue(
            description.contains("mode:\(subject.mode.description)")
        )
        XCTAssertTrue(description.contains("options:"))
        XCTAssertTrue(description.contains(".defaultToSpeaker"))
        XCTAssertTrue(description.contains(".allowBluetoothA2DP"))
        XCTAssertTrue(description.contains("overrideOutputAudioPort:.speaker"))
    }
}
