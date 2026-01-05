//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

final class WebRTCUpdateSubscriptionsAdapter_Tests: XCTestCase, @unchecked Sendable {

    private lazy var participantsSubject: CurrentValueSubject<WebRTCStateAdapter.ParticipantsStorage, Never>! = .init([:])
    private lazy var incomingVideoQualitySettingsSubject: CurrentValueSubject<IncomingVideoQualitySettings, Never>! = .init(.none)
    private lazy var mockSFUStack: MockSFUStack! = .init()
    private lazy var sessionID: String! = .unique
    private lazy var subject: WebRTCUpdateSubscriptionsAdapter! = .init(
        participantsPublisher: participantsSubject.eraseToAnyPublisher(),
        incomingVideoQualitySettingsPublisher: incomingVideoQualitySettingsSubject.eraseToAnyPublisher(),
        sfuAdapter: mockSFUStack.adapter,
        sessionID: sessionID,
        clientCapabilities: []
    )

    override func setUp() {
        super.setUp()
        _ = subject
    }

    override func tearDown() {
        subject = nil
        sessionID = nil
        mockSFUStack = nil
        incomingVideoQualitySettingsSubject = nil
        participantsSubject = nil
        super.tearDown()
    }

    // MARK: - didUpdate

    func test_didUpdate_doesNotSubscribeToAudioTracks() async throws {
        participantsSubject.send([
            .unique: .dummy(hasAudio: true),
            .unique: .dummy(hasAudio: true),
            .unique: .dummy(hasAudio: true),
            .unique: .dummy(hasAudio: true)
        ])

        await wait(for: 0.5)
        XCTAssertNil(mockSFUStack.service.updateSubscriptionsWasCalledWithRequest)
    }

    func test_didUpdate_participants_sendsToSFU() async throws {
        participantsSubject.send([
            "1": .dummy(id: "1", hasVideo: true),
            "2": .dummy(id: "2", hasVideo: true),
            "3": .dummy(id: "3", isScreenSharing: true),
            "4": .dummy(id: "4", isScreenSharing: true)
        ])
        await fulfillment { self.mockSFUStack.service.updateSubscriptionsWasCalledWithRequest != nil }

        let request = try XCTUnwrap(mockSFUStack.service.updateSubscriptionsWasCalledWithRequest)
        XCTAssertEqual(request.tracks.filter { $0.trackType == .video }.count, 2)
        XCTAssertEqual(request.tracks.filter { $0.trackType == .screenShare }.count, 2)
    }

    func test_didUpdate_incomingVideoQualitySettings_sendsToSFU() async throws {
        participantsSubject.send([
            "1": .dummy(id: "1", hasVideo: true),
            "2": .dummy(id: "2", hasVideo: true),
            "3": .dummy(id: "3", isScreenSharing: true),
            "4": .dummy(id: "4", isScreenSharing: true)
        ])
        await fulfillment { self.mockSFUStack.service.timesCalled(.updateSubscriptions) == 1 }

        incomingVideoQualitySettingsSubject.send(.disabled(group: .all))

        await fulfillment { self.mockSFUStack.service.timesCalled(.updateSubscriptions) == 2 }
    }

    func test_didUpdate_tracksHaveNoDifferenceWithLastReport_noRequestWasSent() async throws {
        participantsSubject.send([
            "1": .dummy(id: "1", hasVideo: true),
            "2": .dummy(id: "2", hasVideo: true),
            "3": .dummy(id: "3", isScreenSharing: true),
            "4": .dummy(id: "4", isScreenSharing: true)
        ])

        await fulfillment { self.mockSFUStack.service.timesCalled(.updateSubscriptions) == 1 }

        participantsSubject.send([
            "1": .dummy(id: "1", hasVideo: true),
            "2": .dummy(id: "2", hasVideo: true),
            "3": .dummy(id: "3", isScreenSharing: true),
            "4": .dummy(id: "4", isScreenSharing: true)
        ])

        await fulfillment { self.mockSFUStack.service.timesCalled(.updateSubscriptions) == 1 }
    }
}
