//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

@MainActor
final class VideoProximityPolicy_Tests: XCTestCase, @unchecked Sendable {

    private var mockStreamVideo: MockStreamVideo! = .init()
    private lazy var mockCallController: MockCallController! = .init()
    private lazy var mockCall: MockCall! = .init(.dummy(callController: mockCallController))
    private lazy var subject: VideoProximityPolicy! = .init()

    override func setUp() async throws {
        try await super.setUp()
        _ = mockCall
        /// We need to wait for all observations in CallController/WebRTCCoordinator and Call have been
        /// completed, in order to avoid unwanted changes to CallSettings.
        await wait(for: 1)
    }

    override func tearDown() async throws {
        subject = nil
        mockCall = nil
        mockStreamVideo = nil
        mockCallController = nil
        try await super.tearDown()
    }

    // MARK: - didUpdateProximity

    func test_didUpdateProximity_near_videoFalse_incomingVideoQualitySettingsNone_nothingHappens() async {
        mockCall.state.callSettings = .init(videoOn: false)
        mockCall.state.incomingVideoQualitySettings = .none

        subject.didUpdateProximity(.near, on: mockCall)

        await wait(for: 0.25)
        XCTAssertEqual(mockCallController.timesCalled(.changeVideoState), 0)
        XCTAssertEqual(mockCall.state.incomingVideoQualitySettings, .disabled(group: .all))
    }

    func test_didUpdateProximity_near_videoTrue_incomingVideoQualitySettingsNone_incomingVideoQualitySettingsAndCameraDisabled(
    ) async {
        mockCall.state.callSettings = .init(videoOn: true)
        mockCall.state.incomingVideoQualitySettings = .none

        subject.didUpdateProximity(.near, on: mockCall)

        await wait(for: 0.25)
        XCTAssertEqual(mockCallController.timesCalled(.changeVideoState), 1)
        XCTAssertEqual(mockCall.state.incomingVideoQualitySettings, .disabled(group: .all))
    }

    func test_didUpdateProximity_near_videoFalse_incomingVideoQualitySettingsOtherThanNone_incomingVideoQualitySettingsAndCameraDisabled(
    ) async {
        mockCall.state.callSettings = .init(videoOn: false)
        mockCall.state.incomingVideoQualitySettings = .manual(group: .all, targetSize: .quarter)

        subject.didUpdateProximity(.near, on: mockCall)

        await wait(for: 0.25)
        XCTAssertEqual(mockCallController.timesCalled(.changeVideoState), 0)
        XCTAssertEqual(mockCall.state.incomingVideoQualitySettings, .disabled(group: .all))
    }

    func test_didUpdateProximity_far_noCachedValue_nothingHappens() async {
        mockCall.state.callSettings = .init(videoOn: false)
        mockCall.state.incomingVideoQualitySettings = .manual(group: .all, targetSize: .quarter)

        subject.didUpdateProximity(.far, on: mockCall)

        await wait(for: 0.25)
        XCTAssertEqual(mockCallController.timesCalled(.changeVideoState), 0)
        XCTAssertEqual(mockCall.state.incomingVideoQualitySettings, .manual(group: .all, targetSize: .quarter))
    }

    func test_didUpdateProximity_far_cachedValueWithIncomingQualitySettingsAndVideoOff_incomingVideoQualitySettingsUpdated() async {
        mockCall.state.callSettings = .init(videoOn: false)
        mockCall.state.incomingVideoQualitySettings = .manual(group: .all, targetSize: .quarter)

        subject.didUpdateProximity(.near, on: mockCall)
        await wait(for: 0.25)
        subject.didUpdateProximity(.far, on: mockCall)

        await wait(for: 0.25)
        XCTAssertEqual(mockCallController.timesCalled(.changeVideoState), 0)
        XCTAssertEqual(mockCall.state.incomingVideoQualitySettings, .manual(group: .all, targetSize: .quarter))
    }

    func test_didUpdateProximity_far_cachedValueWithoutIncomingQualitySettingsAndVideoOn_videoWasUpdated() async {
        mockCall.state.callSettings = .init(videoOn: true)
        mockCall.state.incomingVideoQualitySettings = .none

        subject.didUpdateProximity(.near, on: mockCall)
        await wait(for: 0.25)
        subject.didUpdateProximity(.far, on: mockCall)

        await wait(for: 0.25)
        XCTAssertEqual(mockCallController.timesCalled(.changeVideoState), 2)
        XCTAssertEqual(mockCallController.recordedInputPayload(Bool.self, for: .changeVideoState)?.last, true)
        XCTAssertEqual(mockCall.state.incomingVideoQualitySettings, .none)
    }

    func test_didUpdateProximity_far_cachedValueWithIncomingQualitySettingsAndVideoOn_incomingVideoQualitySettingsAndVideoWereUpdated(
    ) async {
        mockCall.state.callSettings = .init(videoOn: true)
        mockCall.state.incomingVideoQualitySettings = .manual(group: .all, targetSize: .quarter)

        subject.didUpdateProximity(.near, on: mockCall)
        await wait(for: 0.25)
        subject.didUpdateProximity(.far, on: mockCall)

        await wait(for: 0.25)
        XCTAssertEqual(mockCallController.timesCalled(.changeVideoState), 2)
        XCTAssertEqual(mockCallController.recordedInputPayload(Bool.self, for: .changeVideoState)?.last, true)
        XCTAssertEqual(mockCall.state.incomingVideoQualitySettings, .manual(group: .all, targetSize: .quarter))
    }
}
