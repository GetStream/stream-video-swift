//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import Combine
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import StreamWebRTC
import XCTest

final class PictureInPictureEnforcedStopAdapterTests: XCTestCase, @unchecked Sendable {

    private lazy var mockPictureInPictureController: MockAVPictureInPictureController! = .init()
    private lazy var mockAppStateAdapter: MockAppStateAdapter! = .init()
    private lazy var subject: PictureInPictureEnforcedStopAdapter! = .init(mockPictureInPictureController)
    private var originalStateAdapter: AppStateProviding! = AppStateProviderKey.currentValue

    override func setUp() async throws {
        try await super.setUp()
        _ = AppStateProviderKey.currentValue
        await wait(for: 0.1)
        AppStateProviderKey.currentValue = mockAppStateAdapter
    }

    override func tearDown() {
        AppStateProviderKey.currentValue = originalStateAdapter
        mockPictureInPictureController = nil
        mockAppStateAdapter = nil
        subject = nil
        originalStateAdapter = nil
        super.tearDown()
    }

    // MARK: - didUpdate

    func test_didUpdate_appStateForeground_isPictureInPictureActiveTrue_stopWasCalledonPictureInPictureController() async {
        await assertStopPictureInPicture(
            applicationState: .foreground,
            isPictureInPictureActive: true,
            expectedCall: false
        )
    }

    func test_didUpdate_appStateForeground_isPictureInPictureActiveFalse_stopWasNotCalledonPictureInPictureController() async {
        await assertStopPictureInPicture(
            applicationState: .foreground,
            isPictureInPictureActive: false,
            expectedCall: false
        )
    }

    func test_didUpdate_appStateBackground_isPictureInPictureActiveTrue_stopWasNotCalledonPictureInPictureController() async {
        await assertStopPictureInPicture(
            applicationState: .background,
            isPictureInPictureActive: true,
            expectedCall: false
        )
    }

    func test_didUpdate_appStateBackground_isPictureInPictureActiveFalse_stopWasNotCalledonPictureInPictureController() async {
        await assertStopPictureInPicture(
            applicationState: .background,
            isPictureInPictureActive: false,
            expectedCall: false
        )
    }

    private func assertStopPictureInPicture(
        applicationState: ApplicationState,
        isPictureInPictureActive: Bool,
        expectedCall: Bool,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async {
        mockAppStateAdapter.stubbedState = applicationState
        let subject: CurrentValueSubject<Bool, Never> = .init(isPictureInPictureActive)
        mockPictureInPictureController.stub(
            for: \.isPictureInPictureActivePublisher,
            with: subject.eraseToAnyPublisher()
        )

        _ = subject

        await wait(for: 0.2)
        XCTAssertEqual(mockPictureInPictureController.timesCalled(.stopPictureInPicture) > 0, expectedCall)
    }
}
