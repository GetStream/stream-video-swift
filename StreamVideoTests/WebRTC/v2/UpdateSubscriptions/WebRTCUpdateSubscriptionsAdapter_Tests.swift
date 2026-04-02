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
        subject.startObservation()
    }

    override func tearDown() {
        subject = nil
        sessionID = nil
        mockSFUStack = nil
        incomingVideoQualitySettingsSubject = nil
        participantsSubject = nil
        super.tearDown()
    }

    // MARK: - Observation

    func test_startObservation_doesNotSubscribeToAudioTracks() async throws {
        participantsSubject.send([
            .unique: .dummy(hasAudio: true),
            .unique: .dummy(hasAudio: true),
            .unique: .dummy(hasAudio: true),
            .unique: .dummy(hasAudio: true)
        ])

        await wait(for: 0.5)
        XCTAssertNil(mockSFUStack.service.updateSubscriptionsWasCalledWithRequest)
    }

    func test_startObservation_whenParticipantsUpdated_sendsToSFU() async throws {
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

    func test_startObservation_whenIncomingVideoQualityUpdates_sendsToSFU() async throws {
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

    func test_startObservation_whenTracksDoNotChange_doesNotSendRequest() async throws {
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

    func test_stopObservation_whenParticipantsUpdated_doesNotSendRequest() async throws {
        participantsSubject.send(["1": .dummy(id: "1", hasVideo: true)])
        await fulfillment { self.mockSFUStack.service.timesCalled(.updateSubscriptions) == 1 }

        subject.stopObservation()
        await wait(for: 0.5)

        participantsSubject.send([
            "1": .dummy(id: "1", hasVideo: true),
            "2": .dummy(id: "2", hasVideo: true)
        ])
        await wait(for: 0.5)

        XCTAssertEqual(mockSFUStack.service.timesCalled(.updateSubscriptions), 1)
    }

    // MARK: - Specific participants update

    func test_updateSubscriptions_forSpecificParticipantAndTrackType_sendsFilteredTracks() async throws {
        subject.updateSubscriptions(
            for: [.dummy(id: "1", hasVideo: true, hasAudio: true)],
            incomingVideoQualitySettings: .none,
            trackTypes: [.video]
        )

        await fulfillment {
            self
                .mockSFUStack
                .service
                .stubbedFunctionInput[.updateSubscriptions]?
                .contains { input in
                    guard case let .updateSubscriptions(request) = input else {
                        return false
                    }
                    return request.tracks.count == 1
                        && request.tracks.first?.trackType == .video
                } == true
        }
        let request = try XCTUnwrap(
            mockSFUStack
                .service
                .stubbedFunctionInput[.updateSubscriptions]?
                .compactMap { input -> Stream_Video_Sfu_Signal_UpdateSubscriptionsRequest? in
                    guard case let .updateSubscriptions(request) = input else {
                        return nil
                    }
                    return request.tracks.count == 1
                        && request.tracks.first?.trackType == .video
                        ? request
                        : nil
                }
                .first
        )
        XCTAssertEqual(request.tracks.count, 1)
        XCTAssertEqual(request.tracks.first?.trackType, .video)
    }
}
