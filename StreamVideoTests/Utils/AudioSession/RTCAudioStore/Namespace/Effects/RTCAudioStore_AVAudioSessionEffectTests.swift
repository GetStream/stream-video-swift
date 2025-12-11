//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCAudioStore_AVAudioSessionEffectTests: XCTestCase, @unchecked Sendable {

    private var effect: RTCAudioStore.AVAudioSessionEffect!
    private var stateSubject: PassthroughSubject<RTCAudioStore.StoreState, Never>!
    private var dispatchedActions: [[StoreActionBox<RTCAudioStore.Namespace.Action>]]!
    private var dispatcher: Store<RTCAudioStore.Namespace>.Dispatcher!
    private var dispatcherExpectation: XCTestExpectation?
    private var originalObserver: AVAudioSessionObserver!
    private var testObserver: AVAudioSessionObserver!

    override func setUp() {
        super.setUp()
        effect = .init()
        stateSubject = .init()
        dispatchedActions = []
        dispatcher = .init { [weak self] actions, _, _, _ in
            self?.dispatchedActions.append(actions)
            self?.dispatcherExpectation?.fulfill()
        }
        effect.dispatcher = dispatcher
        originalObserver = InjectedValues[\.avAudioSessionObserver]
        testObserver = AVAudioSessionObserver()
        InjectedValues[\.avAudioSessionObserver] = testObserver
    }

    override func tearDown() {
        effect.set(statePublisher: nil)
        testObserver.stopObserving()
        InjectedValues[\.avAudioSessionObserver] = originalObserver
        dispatcherExpectation = nil
        dispatchedActions = nil
        stateSubject = nil
        effect = nil
        testObserver = nil
        originalObserver = nil
        super.tearDown()
    }

    func test_whenAudioDeviceModuleAvailable_dispatchesSystemCategoryUpdates() async {
        dispatcherExpectation = expectation(description: "Dispatch category updates")
        effect.set(statePublisher: stateSubject.eraseToAnyPublisher())

        stateSubject.send(makeState(audioDeviceModule: makeAudioDeviceModule()))

        await fulfillment(of: [dispatcherExpectation!], timeout: 2)

        XCTAssertTrue(
            dispatchedActions.contains { actions in
                actions.contains { box in
                    if case let .normal(action) = box,
                       case .avAudioSession(.systemSetCategory) = action {
                        return true
                    }
                    return false
                }
            }
        )
    }

    func test_whenAudioDeviceModuleMissing_doesNotDispatch() async {
        let inverted = expectation(description: "No dispatch")
        inverted.isInverted = true
        dispatcherExpectation = inverted

        effect.set(statePublisher: stateSubject.eraseToAnyPublisher())
        stateSubject.send(makeState(audioDeviceModule: nil))

        await fulfillment(of: [inverted], timeout: 0.5)
        XCTAssertTrue(dispatchedActions.isEmpty)
    }

    // MARK: - Helpers

    private func makeAudioDeviceModule() -> AudioDeviceModule {
        AudioDeviceModule(MockRTCAudioDeviceModule())
    }

    private func makeState(
        audioDeviceModule: AudioDeviceModule?
    ) -> RTCAudioStore.StoreState {
        .init(
            isActive: false,
            isInterrupted: false,
            isRecording: false,
            isMicrophoneMuted: false,
            hasRecordingPermission: true,
            audioDeviceModule: audioDeviceModule,
            currentRoute: .empty,
            audioSessionConfiguration: .init(
                category: .playAndRecord,
                mode: .default,
                options: [],
                overrideOutputAudioPort: .none
            ),
            webRTCAudioSessionConfiguration: .init(
                isAudioEnabled: true,
                useManualAudio: false,
                prefersNoInterruptionsFromSystemAlerts: false
            ),
            stereoConfiguration: .init(playout: .init(preferred: false, enabled: false))
        )
    }
}
