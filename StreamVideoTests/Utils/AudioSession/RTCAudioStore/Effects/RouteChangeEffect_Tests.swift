//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RouteChangeEffect_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - Mocks

    final class MockDelegate: StreamAudioSessionAdapterDelegate {
        private(set) var updatedSpeakerOn: Bool?

        func audioSessionAdapterDidUpdateSpeakerOn(_ speakerOn: Bool) {
            updatedSpeakerOn = speakerOn
        }
    }

    // MARK: - Properties

    private lazy var store: MockRTCAudioStore! = .init()
    private lazy var delegate: MockDelegate! = .init()
    private lazy var callSettingsSubject: PassthroughSubject<CallSettings, Never>! = .init()
    private lazy var subject: RTCAudioStore.RouteChangeEffect! = .init(
        store.audioStore,
        callSettingsPublisher: callSettingsSubject.eraseToAnyPublisher(),
        delegate: delegate
    )

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        delegate = nil
        callSettingsSubject = PassthroughSubject<CallSettings, Never>()
        store = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init_delegateWasAdded() {
        _ = subject

        XCTAssertEqual(store.session.timesCalled(.addDelegate), 1)
    }

    // MARK: - audioSessionDidChangeRoute

    func test_routeChange_whenDeviceIsNotPhone_andSpeakerStateDiffers_shouldUpdateDelegate() async {
        await assert(
            currentDevice: .pad,
            activeCallSettings: .init(speakerOn: false),
            updatedRoute: .dummy(output: .builtInSpeaker),
            expectedCallSettings: .init(speakerOn: true)
        )
    }

    func test_routeChange_whenPhone_speakerOnToOff_shouldUpdateDelegate() async {
        await assert(
            currentDevice: .phone,
            activeCallSettings: .init(speakerOn: true),
            updatedRoute: .dummy(output: .builtInReceiver),
            expectedCallSettings: .init(speakerOn: false)
        )
    }

    func test_routeChange_whenPhone_speakerOffToOn_withPlayAndRecord_shouldUpdateDelegate() async {
        await assert(
            currentDevice: .phone,
            activeCallSettings: .init(speakerOn: false),
            updatedRoute: .dummy(output: .builtInSpeaker),
            expectedCallSettings: .init(speakerOn: true)
        )
    }

    func test_routeChange_whenPhone_speakerOffToOn_withPlayback_shouldNotUpdateDelegate() async {
        await assert(
            currentDevice: .phone,
            activeCallSettings: .init(speakerOn: false),
            category: .playback,
            updatedRoute: .dummy(output: .builtInSpeaker),
            expectedCallSettings: nil
        )
    }

    func test_routeChange_whenSpeakerStateMatches_shouldNotUpdateDelegate() async {
        await assert(
            currentDevice: .phone,
            activeCallSettings: .init(speakerOn: true),
            updatedRoute: .dummy(output: .builtInSpeaker),
            expectedCallSettings: nil
        )
    }

    // MARK: - Private Helpers

    private func assert(
        currentDevice: CurrentDevice.DeviceType,
        activeCallSettings: CallSettings,
        category: AVAudioSession.Category = .playAndRecord,
        updatedRoute: AVAudioSessionRouteDescription,
        expectedCallSettings: CallSettings?
    ) async {
        // Given
        CurrentDevice.currentValue = .init { currentDevice }
        await fulfillment { CurrentDevice.currentValue.deviceType == currentDevice }
        _ = subject
        // we send this one to be the one that will be dropped
        callSettingsSubject.send(activeCallSettings.withUpdatedAudioOutputState(false))
        callSettingsSubject.send(activeCallSettings)
        store.session.category = category.rawValue
        store.session.currentRoute = updatedRoute

        // When
        subject.audioSessionDidChangeRoute(
            .sharedInstance(),
            reason: .unknown,
            previousRoute: .dummy()
        )

        // Then
        XCTAssertEqual(delegate.updatedSpeakerOn, expectedCallSettings?.speakerOn)
    }
}
