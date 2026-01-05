//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamVideo
import XCTest

@MainActor
final class SpeakerProximityPolicy_Tests: XCTestCase, @unchecked Sendable {

    private var mockStreamVideo: MockStreamVideo! = .init()
    private lazy var mockCall: MockCall! = .init(.dummy())
    private lazy var peerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var subject: SpeakerProximityPolicy! = .init()

    override func setUp() async throws {
        try await super.setUp()
        _ = mockCall
        await wait(for: 0.25)
    }

    override func tearDown() async throws {
        subject = nil
        mockStreamVideo = nil
        mockCall = nil
        peerConnectionFactory = nil
        try await super.tearDown()
    }

    // MARK: - didUpdateProximity

    func test_didUpdateProximity_near_currentRouteIsNotExternal_speakerOnTrue_callSettingsUpdatedToSpeakerOnFalse() async {
        mockCall.state.callSettings = .init(speakerOn: true)

        subject.didUpdateProximity(.near, on: mockCall)

        await wait(for: 0.25)
        XCTAssertFalse(mockCall.state.callSettings.speakerOn)
    }

    func test_didUpdateProximity_near_currentRouteIsNotExternal_speakerOnFalse_nothingHappens() async {
        mockCall.state.callSettings = .init(speakerOn: false)

        subject.didUpdateProximity(.near, on: mockCall)

        await wait(for: 0.25)
        XCTAssertFalse(mockCall.state.callSettings.speakerOn)
    }

    func test_didUpdateProximity_far_callSettingsBeforeProximityChangeIsNil_nothingHappens() async {
        mockCall.state.callSettings = .init(speakerOn: false)

        subject.didUpdateProximity(.far, on: mockCall)

        await wait(for: 0.25)
        XCTAssertFalse(mockCall.state.callSettings.speakerOn)
    }

    func test_didUpdateProximity_far_callSettingsBeforeProximityChangeIsNotNil_callSettingsRestored() async {
        mockCall.state.callSettings = .init(speakerOn: true)

        subject.didUpdateProximity(.near, on: mockCall)
        await wait(for: 0.25)
        subject.didUpdateProximity(.far, on: mockCall)

        await wait(for: 0.25)
        XCTAssertTrue(mockCall.state.callSettings.speakerOn)
    }
}
