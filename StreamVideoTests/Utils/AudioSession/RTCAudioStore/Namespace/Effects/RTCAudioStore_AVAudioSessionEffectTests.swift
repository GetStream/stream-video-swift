//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

    func test_whenAudioDeviceModuleRemoved_stopsObserving() async {
        // `testObserver.publisher` would resolve to `Optional.publisher`
        // on the implicitly unwrapped property, so bind a non-optional.
        let observer: AVAudioSessionObserver = testObserver
        effect.set(statePublisher: stateSubject.eraseToAnyPublisher())
        stateSubject.send(makeState(audioDeviceModule: makeAudioDeviceModule()))

        // Prove the observer polls before asserting that it stops.
        let didPoll = expectation(description: "Observer polls")
        didPoll.assertForOverFulfill = false
        let pollCancellable = observer
            .publisher
            .dropFirst()
            .sink { _ in didPoll.fulfill() }
        await fulfillment(of: [didPoll], timeout: 2)
        pollCancellable.cancel()

        stateSubject.send(makeState(audioDeviceModule: nil))

        // Skip the replayed value and one tick that can still be in flight.
        let didPollAfterRemoval = expectation(description: "Observer polls after removal")
        didPollAfterRemoval.isInverted = true
        didPollAfterRemoval.assertForOverFulfill = false
        let silenceCancellable = observer
            .publisher
            .dropFirst(2)
            .sink { _ in didPollAfterRemoval.fulfill() }
        await fulfillment(of: [didPollAfterRemoval], timeout: 0.5)
        silenceCancellable.cancel()
    }

    func test_whenAudioDeviceModuleReplacedAfterRemoval_restartsObserving() async {
        let observer: AVAudioSessionObserver = testObserver
        effect.set(statePublisher: stateSubject.eraseToAnyPublisher())
        stateSubject.send(makeState(audioDeviceModule: makeAudioDeviceModule()))
        stateSubject.send(makeState(audioDeviceModule: nil))

        // Skip the replayed value and the immediate one sent on restart.
        // Only a timer tick of the restarted observer can fulfill this.
        let didPollAfterRestart = expectation(description: "Observer polls again")
        didPollAfterRestart.assertForOverFulfill = false
        let cancellable = observer
            .publisher
            .dropFirst(2)
            .sink { _ in didPollAfterRestart.fulfill() }

        stateSubject.send(makeState(audioDeviceModule: makeAudioDeviceModule()))

        await fulfillment(of: [didPollAfterRestart], timeout: 2)
        cancellable.cancel()
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
            isMutedSpeechDetectionEnabled: false,
            hasRecordingPermission: true,
            activeSessionIdentifier: "",
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
