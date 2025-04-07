//
//  VideoProximityPolicy_Tests.swift
//  StreamVideoTests
//
//  Created by Ilias Pavlidakis on 25/4/25.
//

import Foundation
@testable import StreamVideo
import XCTest
import AVFoundation

@MainActor
final class SpeakerProximityPolicy_Tests: XCTestCase, @unchecked Sendable {

    private lazy var mockAudioSession: MockAudioSession! = .init()
    private lazy var mockCall: MockCall! = .init(.dummy())
    private lazy var subject: SpeakerProximityPolicy! = .init()

    override func setUp() async throws {
        try await super.setUp()
        _ = mockCall
        await wait(for: 0.25)
        StreamAudioSession.currentValue = .init(audioSession: mockAudioSession)
    }

    override func tearDown() async throws {
        subject = nil
        mockCall = nil
        mockAudioSession = nil
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
