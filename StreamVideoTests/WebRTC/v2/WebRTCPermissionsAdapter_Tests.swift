//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

final class WebRTCPermissionsAdapter_Tests: StreamVideoTestCase, @unchecked Sendable {

    private lazy var mockAppStateAdapter: MockAppStateAdapter! = .init()
    private lazy var mockPermissions: MockPermissionsStore! = .init()
    private lazy var delegate: MockWebRTCPermissionsAdapterDelegate! = .init()
    private lazy var stageSubject: CurrentValueSubject<
        WebRTCCoordinator.StateMachine.Stage.ID,
        Never
    >! = .init(.idle)
    private lazy var subject: WebRTCPermissionsAdapter! = .init(
        delegate,
        stagePublisher: stageSubject.eraseToAnyPublisher()
    )

    override func tearDown() {
        mockAppStateAdapter?.dismante()
        mockPermissions?.dismantle()
        mockAppStateAdapter = nil
        mockPermissions = nil
        delegate = nil
        stageSubject = nil
        subject = nil
        super.tearDown()
    }

    func test_willSet_audioOnTrue_withDeniedMic_downgradesAudioOff() async {
        mockAppStateAdapter.makeShared()
        mockPermissions.stubMicrophonePermission(.denied)
        await fulfillment { self.mockPermissions.mockStore.state.microphonePermission == .denied }

        let input = CallSettings(audioOn: true, videoOn: false)
        let output = await subject.willSet(callSettings: input)

        XCTAssertEqual(output.audioOn, false)
        XCTAssertEqual(output.videoOn, false)
    }

    func test_willSet_videoOnTrue_withDeniedCamera_downgradesVideoOff() async {
        mockAppStateAdapter.makeShared()
        mockPermissions.stubCameraPermission(.denied)
        await fulfillment { self.mockPermissions.mockStore.state.cameraPermission == .denied }

        let input = CallSettings(audioOn: false, videoOn: true)
        let output = await subject.willSet(callSettings: input)

        XCTAssertEqual(output.audioOn, false)
        XCTAssertEqual(output.videoOn, false)
    }

    func test_micRevoked_sameAudioSettings_downgradesAudioOff() async {
        mockAppStateAdapter.makeShared()
        mockAppStateAdapter.stubbedState = .foreground
        mockPermissions.stubMicrophonePermission(.granted)
        await fulfillment {
            self.mockPermissions.mockStore.state.microphonePermission == .granted
        }

        let input = CallSettings(audioOn: true, videoOn: false)
        let initialOutput = await subject.willSet(callSettings: input)

        XCTAssertEqual(initialOutput.audioOn, true)
        XCTAssertEqual(initialOutput.videoOn, false)

        mockPermissions.stubMicrophonePermission(.denied)
        await fulfillment {
            self.mockPermissions.mockStore.state.microphonePermission == .denied
        }

        let output = await subject.willSet(callSettings: input)

        XCTAssertEqual(output.audioOn, false)
        XCTAssertEqual(output.videoOn, false)
    }

    func test_cameraRevoked_sameVideoSettings_downgradesVideoOff() async {
        mockAppStateAdapter.makeShared()
        mockAppStateAdapter.stubbedState = .foreground
        mockPermissions.stubCameraPermission(.granted)
        await fulfillment {
            self.mockPermissions.mockStore.state.cameraPermission == .granted
        }

        let input = CallSettings(audioOn: false, videoOn: true)
        let initialOutput = await subject.willSet(callSettings: input)

        XCTAssertEqual(initialOutput.audioOn, false)
        XCTAssertEqual(initialOutput.videoOn, true)

        mockPermissions.stubCameraPermission(.denied)
        await fulfillment {
            self.mockPermissions.mockStore.state.cameraPermission == .denied
        }

        let output = await subject.willSet(callSettings: input)

        XCTAssertEqual(output.audioOn, false)
        XCTAssertEqual(output.videoOn, false)
    }

    func test_willSet_audioOnTrue_unknownMic_inForeground_requestsPermission_andKeepsAudioOnWhenGranted() async {
        mockAppStateAdapter.makeShared()
        defer { mockAppStateAdapter.dismante() }
        mockAppStateAdapter.stubbedState = .foreground
        mockPermissions.stubMicrophonePermission(.unknown)
        await fulfillment { self.mockPermissions.mockStore.state.microphonePermission == .unknown }
        stageSubject.send(.joined)

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                let input = CallSettings(audioOn: true, videoOn: false)
                let output = await self.subject.willSet(callSettings: input)
                XCTAssertEqual(output.audioOn, true)
                // Delegate should reflect granted mic permission once observed.
                await self.fulfillment { self.delegate.audioOnValues.contains(true) }
            }

            group.addTask {
                await self.fulfillment { self.mockPermissions.timesCalled(.requestMicrophonePermission) == 1 }
                self.mockPermissions.stubMicrophonePermission(.granted)
                await self.wait(for: 0.5)
            }

            await group.waitForAll()
        }
    }

    func test_willSet_videoOnTrue_unknownCamera_inForeground_requestsPermission_andKeepsVideoOnWhenGranted() async {
        mockAppStateAdapter.makeShared()
        mockAppStateAdapter.stubbedState = .foreground
        mockPermissions.stubCameraPermission(.unknown)
        await fulfillment { self.mockPermissions.mockStore.state.cameraPermission == .unknown }
        stageSubject.send(.joined)

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fulfillment { self.mockPermissions.timesCalled(.requestCameraPermission) == 1 }
                self.mockPermissions.stubCameraPermission(.granted)
            }

            group.addTask {
                await self.wait(for: 0.5)
                let input = CallSettings(audioOn: false, videoOn: true)
                let output = await self.subject.willSet(callSettings: input)
                XCTAssertEqual(output.videoOn, true)
                // Delegate should reflect granted camera permission once observed.
                await self.fulfillment { self.delegate.videoOnValues.contains(true) }
            }

            await group.waitForAll()
        }

        mockAppStateAdapter?.dismante()
        mockPermissions?.dismantle()
    }

    func test_willSet_audioOnTrue_unknownMic_inForegroundBeforeJoined_doesNotRequestPermission() async {
        mockAppStateAdapter.makeShared()
        mockAppStateAdapter.stubbedState = .foreground
        mockPermissions.stubMicrophonePermission(.unknown)
        await fulfillment {
            self.mockPermissions.mockStore.state.microphonePermission == .unknown
        }

        let input = CallSettings(audioOn: true, videoOn: false)
        let output = await subject.willSet(callSettings: input)

        XCTAssertFalse(output.audioOn)
        XCTAssertFalse(output.videoOn)
        XCTAssertEqual(mockPermissions.timesCalled(.requestMicrophonePermission), 0)
    }

    func test_stageTransitionsToJoined_withPendingMicPermissionInForeground_requestsPermission() async {
        mockAppStateAdapter.makeShared()
        mockAppStateAdapter.stubbedState = .foreground
        mockPermissions.stubMicrophonePermission(.unknown)
        await fulfillment {
            self.mockPermissions.mockStore.state.microphonePermission == .unknown
        }

        let input = CallSettings(audioOn: true, videoOn: false)
        _ = await subject.willSet(callSettings: input)
        XCTAssertEqual(mockPermissions.timesCalled(.requestMicrophonePermission), 0)

        stageSubject.send(.joined)

        await fulfillment {
            self.mockPermissions.timesCalled(.requestMicrophonePermission) == 1
        }
        mockPermissions.stubMicrophonePermission(.granted)
        await fulfillment { self.delegate.audioOnValues.contains(true) }
    }

    func test_appMovesToForeground_withPendingCameraPermissionInJoined_requestsPermission() async {
        mockAppStateAdapter.makeShared()
        mockAppStateAdapter.stubbedState = .background
        stageSubject.send(.joined)
        mockPermissions.stubCameraPermission(.unknown)
        await fulfillment {
            self.mockPermissions.mockStore.state.cameraPermission == .unknown
        }

        let input = CallSettings(audioOn: false, videoOn: true)
        let output = await subject.willSet(callSettings: input)

        XCTAssertFalse(output.audioOn)
        XCTAssertFalse(output.videoOn)
        XCTAssertEqual(mockPermissions.timesCalled(.requestCameraPermission), 0)

        mockAppStateAdapter.stubbedState = .foreground

        await fulfillment {
            self.mockPermissions.timesCalled(.requestCameraPermission) == 1
        }
        mockPermissions.stubCameraPermission(.granted)
        await fulfillment { self.delegate.videoOnValues.contains(true) }
    }
}
