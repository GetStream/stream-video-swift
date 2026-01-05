//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class PermissionStore_Tests: XCTestCase, @unchecked Sendable {

    private lazy var mockAudioStore: MockRTCAudioStore! = .init()
    private lazy var mockReducer: MockReducer<PermissionStore.Namespace>! = .init()
    private lazy var mockMiddleware: MockPermissionStoreMiddleware = .init()
    private lazy var store: Store<PermissionStore.Namespace>! = PermissionStore.Namespace.store(
        initialState: .initial,
        reducers: PermissionStore.Namespace.reducers() + [mockReducer],
        middleware: [mockMiddleware] // We are disabling middleware to avoid system triggers
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

    // MARK: - canRequestMicrophonePermission

    func test_canRequestMicrophonePermission_whenIsUnknown_returnsTrue() async {
        await wait(for: 1.0)

        store.dispatch(.setMicrophonePermission(.unknown))

        await fulfillment { self.subject.canRequestMicrophonePermission == true }
    }

    func test_canRequestMicrophonePermission_whenIsNotUnknown_returnsFalse() async {
        await wait(for: 1.0)

        store.dispatch(.setMicrophonePermission(.granted))

        await fulfillment { self.subject.canRequestMicrophonePermission == false }
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

    // MARK: - canRequestCameraPermission

    func test_canRequestCameraPermission_whenIsUnknown_returnsTrue() async {
        await wait(for: 1.0)

        store.dispatch(.setCameraPermission(.unknown))

        await fulfillment { self.subject.canRequestCameraPermission == true }
    }

    func test_canRequestCameraPermission_whenIsNotUnknown_returnsFalse() async {
        await wait(for: 1.0)

        store.dispatch(.setCameraPermission(.granted))

        await fulfillment { self.subject.canRequestCameraPermission == false }
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

        _ = try await subject.requestMicrophonePermission()
        await fulfillment {
            let requestMicrophonePermission = self.mockReducer
                .inputs
                .filter {
                    guard case .requestMicrophonePermission = $0.action else {
                        return false
                    }
                    return true
                }
            return requestMicrophonePermission.count == 1
        }
    }

    // MARK: - requestCameraPermission

    func test_requestCameraPermission_dispatchesExpectedAction() async throws {
        await wait(for: 1.0)

        _ = try await subject.requestCameraPermission()
        await fulfillment(timeout: 2) {
            let requestCameraPermission = self.mockReducer
                .inputs
                .filter {
                    guard case .requestCameraPermission = $0.action else {
                        return false
                    }
                    return true
                }
            return requestCameraPermission.count == 1
        }
    }

    // MARK: - requestPushNotificationPermission

    func test_requestPushNotificationPermission_dispatchesExpectedAction() async throws {
        await wait(for: 1.0)

        _ = try await subject.requestPushNotificationPermission(with: [])
        await fulfillment {
            let requestPushNotificationPermission = self.mockReducer
                .inputs
                .filter {
                    guard case .requestPushNotificationPermission = $0.action else {
                        return false
                    }
                    return true
                }
            return requestPushNotificationPermission.count == 1
        }
    }
}

final class MockPermissionStoreMiddleware: Middleware<PermissionStore.Namespace>, @unchecked Sendable {

    var stubMicrophonePermission: PermissionStore.Permission = .granted
    var stubCameraPermission: PermissionStore.Permission = .granted
    var stubPushNotificationsPermission: PermissionStore.Permission = .granted

    override func apply(
        state: PermissionStore.StoreState,
        action: PermissionStore.StoreAction,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        switch action {
        case .requestMicrophonePermission:
            dispatcher?.dispatch(.setMicrophonePermission(stubMicrophonePermission))
        case .requestCameraPermission:
            dispatcher?.dispatch(.setCameraPermission(stubCameraPermission))
        case .requestPushNotificationPermission:
            dispatcher?.dispatch(.setPushNotificationPermission(stubPushNotificationsPermission))
        default:
            break
        }
    }
}
