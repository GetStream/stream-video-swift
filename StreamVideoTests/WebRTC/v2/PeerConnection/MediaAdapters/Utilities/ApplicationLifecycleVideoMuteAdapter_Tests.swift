//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class ApplicationLifecycleVideoMuteAdapterTests: XCTestCase, @unchecked Sendable {

    private lazy var notificationCenter: NotificationCenter! = .init()
    private lazy var applicationStateAdapter: StreamAppStateAdapter! = .init(notificationCenter: notificationCenter)
    private lazy var sessionId: String! = .unique
    private lazy var mockSFUStack: MockSFUStack! = .init()
    private lazy var mockCapturer: MockStreamVideoCapturer! = .init()
    private var subject: ApplicationLifecycleVideoMuteAdapter!

    override func setUp() {
        super.setUp()
        InjectedValues[\.applicationStateAdapter] = applicationStateAdapter
        // We set this one to allow us to control the value of ``CallSettings.videoOn``.
        InjectedValues[\.simulatorStreamFile] = URL(string: "getstream.io")!
        subject = .init(
            sessionID: sessionId,
            sfuAdapter: mockSFUStack.adapter
        )
    }

    override func tearDown() {
        notificationCenter = nil
        applicationStateAdapter = nil
        sessionId = nil
        mockSFUStack = nil
        mockCapturer = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - didUpdateCallSettings(_:)

    func test_didUpdateCallSettings_callSettingsVideoOnFalseObserversAlreadyRegistered_removesObservers() async {
        mockCapturer.stub(for: .supportsBackgrounding, with: false)
        await subject.didStartCapturing(with: mockCapturer)
        // Reset after receiving the foreground initial state
        await fulfillment { self.mockSFUStack.service.updateMuteStatesWasCalledWithRequest != nil }
        mockSFUStack.service.updateMuteStatesWasCalledWithRequest = nil

        subject.didUpdateCallSettings(.init(videoOn: false))
        mockMoveToBackground()

        await wait(for: 0.5)
        XCTAssertNil(mockSFUStack.service.updateMuteStatesWasCalledWithRequest)
    }

    func test_didUpdateCallSettings_callSettingsVideoOnTrueObserversAlreadyRegistered_observersRemained() async {
        mockCapturer.stub(for: .supportsBackgrounding, with: false)
        await subject.didStartCapturing(with: mockCapturer)
        // Reset after receiving the foreground initial state
        await fulfillment { self.mockSFUStack.service.updateMuteStatesWasCalledWithRequest != nil }
        mockSFUStack.service.updateMuteStatesWasCalledWithRequest = nil

        subject.didUpdateCallSettings(.init(videoOn: true))
        mockMoveToBackground()

        await fulfillment { self.mockSFUStack.service.updateMuteStatesWasCalledWithRequest != nil }
    }

    // MARK: - didStartCapturing(with:)

    func test_didStartCapturing_supportsBackgroundingIsTrue_noObserversRegistered() async {
        mockCapturer.stub(for: .supportsBackgrounding, with: true)

        await subject.didStartCapturing(with: mockCapturer)

        await wait(for: 0.5)
        XCTAssertNil(mockSFUStack.service.updateMuteStatesWasCalledWithRequest)
    }

    func test_didStartCapturing_supportsBackgroundingIsFalseAndMovesToBackground_sfuWasCalledWithMuteTrue() async throws {
        mockCapturer.stub(for: .supportsBackgrounding, with: false)

        await subject.didStartCapturing(with: mockCapturer)
        // Reset after receiving the foreground initial state
        await fulfillment { self.mockSFUStack.service.updateMuteStatesWasCalledWithRequest != nil }
        mockSFUStack.service.updateMuteStatesWasCalledWithRequest = nil
        // Move to background
        mockMoveToBackground()

        await fulfillment { self.mockSFUStack.service.updateMuteStatesWasCalledWithRequest != nil }
        let request = try XCTUnwrap(mockSFUStack.service.updateMuteStatesWasCalledWithRequest)
        XCTAssertEqual(request.muteStates.count, 1)
        XCTAssertEqual(request.muteStates.first?.muted, true)
        XCTAssertEqual(request.sessionID, sessionId)
    }

    func test_didStartCapturing_supportsBackgroundingIsFalseAndMovesToForeground_sfuWasCalledWithMuteFalse() async throws {
        mockCapturer.stub(for: .supportsBackgrounding, with: false)
        mockSFUStack.service.resetRecords(for: .updateTrackMuteState)
        mockSFUStack.service.updateMuteStatesWasCalledWithRequest = nil

        await subject.didStartCapturing(with: mockCapturer)
        // Reset after receiving the foreground initial state
        await fulfillment { self.mockSFUStack.service.updateMuteStatesWasCalledWithRequest != nil }
        mockSFUStack.service.updateMuteStatesWasCalledWithRequest = nil
        // Move to foreground
        mockMoveToForeground()

        await fulfillment { self.mockSFUStack.service.updateMuteStatesWasCalledWithRequest != nil }
        let request = try XCTUnwrap(mockSFUStack.service.updateMuteStatesWasCalledWithRequest)
        XCTAssertEqual(request.muteStates.count, 1)
        XCTAssertEqual(request.muteStates.first?.muted, false)
        XCTAssertEqual(request.sessionID, sessionId)
    }

    // MARK: - Private Helpers

    private func mockMoveToForeground() {
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func mockMoveToBackground() {
        notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
}
