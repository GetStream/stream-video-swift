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

        await assertState(
            incomingVideoQualitySettings: .disabled(group: .all),
            timesCalledChangeVideoState: 0
        )
    }

    func test_didUpdateProximity_near_videoTrue_incomingVideoQualitySettingsNone_incomingVideoQualitySettingsAndCameraDisabled(
    ) async {
        mockCall.state.callSettings = .init(videoOn: true)
        mockCall.state.incomingVideoQualitySettings = .none

        subject.didUpdateProximity(.near, on: mockCall)

        await assertState(
            incomingVideoQualitySettings: .disabled(group: .all),
            timesCalledChangeVideoState: 1
        )
    }

    func test_didUpdateProximity_near_videoFalse_incomingVideoQualitySettingsOtherThanNone_incomingVideoQualitySettingsAndCameraDisabled(
    ) async {
        mockCall.state.callSettings = .init(videoOn: false)
        mockCall.state.incomingVideoQualitySettings = .manual(group: .all, targetSize: .quarter)

        subject.didUpdateProximity(.near, on: mockCall)

        await assertState(
            incomingVideoQualitySettings: .disabled(group: .all),
            timesCalledChangeVideoState: 0
        )
    }

    func test_didUpdateProximity_far_noCachedValue_nothingHappens() async {
        mockCall.state.callSettings = .init(videoOn: false)
        mockCall.state.incomingVideoQualitySettings = .manual(group: .all, targetSize: .quarter)

        subject.didUpdateProximity(.far, on: mockCall)

        await assertState(
            incomingVideoQualitySettings: .manual(group: .all, targetSize: .quarter),
            timesCalledChangeVideoState: 0
        )
    }

    func test_didUpdateProximity_far_cachedValueWithIncomingQualitySettingsAndVideoOff_incomingVideoQualitySettingsUpdated() async {
        mockCall.state.callSettings = .init(videoOn: false)
        mockCall.state.incomingVideoQualitySettings = .manual(group: .all, targetSize: .quarter)

        subject.didUpdateProximity(.near, on: mockCall)
        await assertState(
            incomingVideoQualitySettings: .disabled(group: .all),
            timesCalledChangeVideoState: 0
        )
        subject.didUpdateProximity(.far, on: mockCall)

        await assertState(
            incomingVideoQualitySettings: .manual(group: .all, targetSize: .quarter),
            timesCalledChangeVideoState: 0
        )
    }

    func test_didUpdateProximity_far_cachedValueWithoutIncomingQualitySettingsAndVideoOn_videoWasUpdated() async {
        mockCall.state.callSettings = .init(videoOn: true)
        mockCall.state.incomingVideoQualitySettings = .none

        subject.didUpdateProximity(.near, on: mockCall)
        await assertState(
            incomingVideoQualitySettings: .disabled(group: .all),
            timesCalledChangeVideoState: 1
        )
        subject.didUpdateProximity(.far, on: mockCall)

        await assertState(
            incomingVideoQualitySettings: .none,
            timesCalledChangeVideoState: 2,
            lastChangeVideoStateValue: true
        )
    }

    func test_didUpdateProximity_far_cachedValueWithIncomingQualitySettingsAndVideoOn_incomingVideoQualitySettingsAndVideoWereUpdated(
    ) async {
        mockCall.state.callSettings = .init(videoOn: true)
        mockCall.state.incomingVideoQualitySettings = .manual(group: .all, targetSize: .quarter)

        subject.didUpdateProximity(.near, on: mockCall)
        await assertState(
            incomingVideoQualitySettings: .disabled(group: .all),
            timesCalledChangeVideoState: 1
        )
        subject.didUpdateProximity(.far, on: mockCall)

        await assertState(
            incomingVideoQualitySettings: .manual(group: .all, targetSize: .quarter),
            timesCalledChangeVideoState: 2,
            lastChangeVideoStateValue: true
        )
    }

    // MARK: - Private helpers

    private func assertState(
        incomingVideoQualitySettings expectedIncomingVideoQualitySettings: IncomingVideoQualitySettings,
        timesCalledChangeVideoState expectedTimesCalledChangeVideoState: Int,
        lastChangeVideoStateValue expectedLastChangeVideoStateValue: Bool? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await fulfilmentInMainActor(timeout: 2, filePath: file, line: line) {
            self.mockCall.state.incomingVideoQualitySettings == expectedIncomingVideoQualitySettings
                && self.mockCallController.timesCalled(.changeVideoState) == expectedTimesCalledChangeVideoState
        }

        XCTAssertEqual(
            mockCallController.timesCalled(.changeVideoState),
            expectedTimesCalledChangeVideoState,
            file: file,
            line: line
        )
        XCTAssertEqual(
            mockCall.state.incomingVideoQualitySettings,
            expectedIncomingVideoQualitySettings,
            file: file,
            line: line
        )

        if let expectedLastChangeVideoStateValue {
            XCTAssertEqual(
                mockCallController.recordedInputPayload(Bool.self, for: .changeVideoState)?.last,
                expectedLastChangeVideoStateValue,
                file: file,
                line: line
            )
        }
    }
}
