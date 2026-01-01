//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class WebRTCMigrationStatusObserver_Tests: XCTestCase, @unchecked Sendable {
    private lazy var sfuStack: MockSFUStack! = .init()
    private lazy var subject: WebRTCMigrationStatusObserver! = .init(
        migratingFrom: sfuStack.adapter
    )

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        sfuStack = nil
        super.tearDown()
    }

    // MARK: - observeMigrationStatus

    func test_observeMigrationStatus_eventNeverReceived_throwsAnError() async throws {
        _ = await XCTAssertThrowsErrorAsync {
            try await subject.observeMigrationStatus()
        }
    }

    func test_observeMigrationStatus_eventReceived_returnsSuccessfully() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.subject.observeMigrationStatus()
            }
            group.addTask {
                await self.wait(for: 0.5)
                self
                    .sfuStack
                    .receiveEvent(.sfuEvent(.participantMigrationComplete(Stream_Video_Sfu_Event_ParticipantMigrationComplete())))
            }

            try await group.waitForAll()
        }
    }
}
