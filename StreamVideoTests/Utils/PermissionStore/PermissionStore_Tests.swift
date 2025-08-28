//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class PermissionStore_Tests: XCTestCase, @unchecked Sendable {

    private lazy var mockAudioStore: MockRTCAudioStore! = .init()
    private lazy var mockReducer: MockReducer<PermissionStore.Namespace>! = .init()
    private lazy var store: Store<PermissionStore.Namespace>! = PermissionStore.Namespace.store(
        initialState: .initial,
        reducers: PermissionStore.Namespace.reducers() + [mockReducer],
        middleware: [] // We are disabling middleware to avoid system triggers
    )
    private lazy var subject: PermissionStore! = .init(store: store)

    override func setUp() {
        super.setUp()
        mockAudioStore.makeShared()
        _ = subject
    }

    override func tearDown() {
        mockAudioStore.dismantle()

        subject = nil
        store = nil
        mockReducer = nil
        mockAudioStore = nil
        super.tearDown()
    }

    // MARK: - hasMicrophonePermission

    func test_microphonePermissionGranted_hasMicrophonePermissionWasUpdated() async {
        await wait(for: 1.0)
        store.dispatch(.setMicrophonePermission(.granted))

        await fulfillment { self.subject.hasMicrophonePermission == true }
    }

    func test_microphonePermissionDenied_hasMicrophonePermissionWasUpdated() async {
        await wait(for: 1.0)
        store.dispatch(.setMicrophonePermission(.denied))

        await fulfillment { self.subject.hasMicrophonePermission == false }
    }

    // MARK: - hasCameraPermission

    func test_cameraPermissionGranted_hasCameraPermissionWasUpdated() async {
        await wait(for: 1.0)
        store.dispatch(.setCameraPermission(.granted))

        await fulfillment { self.subject.hasCameraPermission == true }
    }

    func test_cameraPermissionDenied_hasCameraPermissionWasUpdated() async {
        await wait(for: 1.0)
        store.dispatch(.setCameraPermission(.denied))

        await fulfillment { self.subject.hasCameraPermission == false }
    }

    // MARK: - audioStore

    func test_microphonePermissionGranted_audioStoreWasUpdated() async {
        await wait(for: 1.0)
        store.dispatch(.setMicrophonePermission(.granted))

        await fulfillment { self.mockAudioStore.audioStore.state.hasRecordingPermission == true }
    }

    func test_microphonePermissionDenied_audioStoreWasUpdated() async {
        await wait(for: 1.0)
        store.dispatch(.setMicrophonePermission(.denied))

        await fulfillment { self.mockAudioStore.audioStore.state.hasRecordingPermission == false }
    }

    // MARK: - requestMicrophonePermission

    func test_requestMicrophonePermission_dispatchesExpectedAction() async throws {
        await wait(for: 1.0)
        store.dispatch(.setMicrophonePermission(.granted))

        _ = try await subject.requestMicrophonePermission()
        await fulfillment(timeout: 2) { self.mockReducer.inputs.count > 1 }
        XCTAssertTrue(mockReducer.inputs.count > 1)

        let requestMicrophonePermission = mockReducer
            .inputs
            .filter {
                guard case .requestMicrophonePermission = $0.action else {
                    return false
                }
                return true
            }
        XCTAssertEqual(requestMicrophonePermission.count, 1)
    }

    // MARK: - requestCameraPermission

    func test_requestCameraPermission_dispatchesExpectedAction() async throws {
        await wait(for: 1.0)
        store.dispatch(.setCameraPermission(.granted))

        _ = try await subject.requestCameraPermission()
        await fulfillment(timeout: 2) { self.mockReducer.inputs.count > 1 }
        XCTAssertTrue(mockReducer.inputs.count > 1)

        let requestCameraPermission = mockReducer
            .inputs
            .filter {
                guard case .requestCameraPermission = $0.action else {
                    return false
                }
                return true
            }
        XCTAssertEqual(requestCameraPermission.count, 1)
    }

    // MARK: - requestPushNotificationPermission

    func test_requestPushNotificationPermission_dispatchesExpectedAction() async throws {
        await wait(for: 1.0)
        store.dispatch(.setPushNotificationPermission(.granted))

        _ = try await subject.requestPushNotificationPermission(with: [])
        await fulfillment { self.mockReducer.inputs.count > 1 }

        let requestPushNotificationPermission = mockReducer
            .inputs
            .filter {
                guard case .requestPushNotificationPermission = $0.action else {
                    return false
                }
                return true
            }
        XCTAssertEqual(requestPushNotificationPermission.count, 1)
    }
}
