//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class CameraManager_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - toggle

    func test_initialStatusEnabled_whenToggle_thenStatusDoesNotChangeUntilCallSettingsUpdate() async throws {
        let callController = MockCallController()
        let subject = CameraManager(
            callController: callController,
            initialStatus: .enabled,
            initialDirection: .front
        )

        try await subject.toggle()

        XCTAssertEqual(subject.status, .enabled)
        XCTAssertEqual(callController.timesCalled(.changeVideoState), 1)
        XCTAssertEqual(
            callController
                .recordedInputPayload(Bool.self, for: .changeVideoState)?
                .first,
            false
        )
    }

    // MARK: - enable

    func test_initialStatusDisabled_whenEnable_thenStatusDoesNotChangeUntilCallSettingsUpdate() async throws {
        let callController = MockCallController()
        let subject = CameraManager(
            callController: callController,
            initialStatus: .disabled,
            initialDirection: .front
        )

        try await subject.enable()

        XCTAssertEqual(subject.status, .disabled)
        XCTAssertEqual(callController.timesCalled(.changeVideoState), 1)
        XCTAssertEqual(
            callController
                .recordedInputPayload(Bool.self, for: .changeVideoState)?
                .first,
            true
        )
    }

    // MARK: - disable

    func test_initialStatusEnabled_whenDisable_thenStatusDoesNotChangeUntilCallSettingsUpdate() async throws {
        let callController = MockCallController()
        let subject = CameraManager(
            callController: callController,
            initialStatus: .enabled,
            initialDirection: .front
        )

        try await subject.disable()

        XCTAssertEqual(subject.status, .enabled)
        XCTAssertEqual(callController.timesCalled(.changeVideoState), 1)
        XCTAssertEqual(
            callController
                .recordedInputPayload(Bool.self, for: .changeVideoState)?
                .first,
            false
        )
    }

    // MARK: - flip

    func test_initialDirectionFront_whenFlip_thenDirectionChangesAndControllerReceivesBack() async throws {
        let callController = MockCallController()
        let subject = CameraManager(
            callController: callController,
            initialStatus: .enabled,
            initialDirection: .front
        )

        try await subject.flip()

        XCTAssertEqual(subject.direction, .back)
        XCTAssertEqual(callController.timesCalled(.changeCameraMode), 1)
        XCTAssertEqual(
            callController
                .recordedInputPayload(CameraPosition.self, for: .changeCameraMode)?
                .first,
            .back
        )
    }

    func test_initialDirectionBack_whenFlip_thenDirectionChangesAndControllerReceivesFront() async throws {
        let callController = MockCallController()
        let subject = CameraManager(
            callController: callController,
            initialStatus: .enabled,
            initialDirection: .back
        )

        try await subject.flip()

        XCTAssertEqual(subject.direction, .front)
        XCTAssertEqual(callController.timesCalled(.changeCameraMode), 1)
        XCTAssertEqual(
            callController
                .recordedInputPayload(CameraPosition.self, for: .changeCameraMode)?
                .first,
            .front
        )
    }
}
