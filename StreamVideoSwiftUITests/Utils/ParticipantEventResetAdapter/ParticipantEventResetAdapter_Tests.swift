//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class ParticipantEventResetAdapter_Tests: XCTestCase, @unchecked Sendable {

    private var mockStreamVideo: MockStreamVideo! = .init()
    private lazy var viewModel: CallViewModel! = .init()
    private lazy var interval: TimeInterval! = 1
    private lazy var subject: ParticipantEventResetAdapter! = .init(
        viewModel,
        interval: interval
    )

    override func tearDown() async throws {
        subject = nil
        mockStreamVideo = nil
        interval = nil
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - participantEventReceived

    func test_participantEventReceived_afterIntervalParticipantEventOnViewModelBecomesNil() async throws {
        _ = subject
        viewModel.participantEvent = .init(
            id: .unique,
            callCid: .unique,
            action: .join,
            user: .unique,
            imageURL: nil
        )
        XCTAssertNotNil(viewModel.participantEvent)

        await fulfilmentInMainActor { self.viewModel.participantEvent == nil }
    }

    func test_participantEventReceived_thenAnotherOne_participantEventBecomesNilAfterIntervalFromTheSecondEventPassed(
    ) async throws {
        _ = subject
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { @Sendable @MainActor in
                self.viewModel.participantEvent = .init(
                    id: .unique,
                    callCid: .unique,
                    action: .join,
                    user: .unique,
                    imageURL: nil
                )
                XCTAssertNotNil(self.viewModel.participantEvent)

                await self.wait(for: 0.5)

                self.viewModel.participantEvent = .init(
                    id: .unique,
                    callCid: .unique,
                    action: .join,
                    user: .unique,
                    imageURL: nil
                )
                XCTAssertNotNil(self.viewModel.participantEvent)
            }

            group.addTask { @Sendable @MainActor in
                await self.wait(for: self.interval)
                XCTAssertNotNil(self.viewModel.participantEvent)

                await self.fulfilmentInMainActor { self.viewModel.participantEvent == nil }
            }

            try await group.waitForAll()
        }
    }
}
