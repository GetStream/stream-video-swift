//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCAudioStore_StereoPlayoutEffectTests: XCTestCase, @unchecked Sendable {

    func test_stereoPlayoutChanges_dispatchesStereoAction() async throws {
        let expectation = self.expectation(description: "Expected action dispatched.")
        let subject = RTCAudioStore.StereoPlayoutEffect()
        let mockAudioDeviceModule = MockRTCAudioDeviceModule()
        let audioDeviceModule = AudioDeviceModule(mockAudioDeviceModule)
        let stateSubject = CurrentValueSubject<RTCAudioStore.Namespace.State, Never>(.dummy(audioDeviceModule: audioDeviceModule))
        subject.set(statePublisher: stateSubject.eraseToAnyPublisher())
        // We wait for the configuration on the effect to be completed.
        await wait(for: 0.5)

        let mockDispatcher = MockStoreDispatcher<RTCAudioStore.Namespace>()
        subject.dispatcher = .init { actions, _, _, _ in mockDispatcher.handle(actions: actions) }

        let cancellable = mockDispatcher
            .publisher
            .filter { !$0.isEmpty }
            .map { $0.map(\.wrappedValue) }
            .filter { actions in
                for action in actions {
                    guard case let .stereo(.setPlayoutEnabled(value)) = action else {
                        continue
                    }
                    return value
                }
                return false
            }
            .sink { _ in expectation.fulfill() }

        audioDeviceModule.audioDeviceModule(
            .init(),
            didUpdateAudioProcessingState: RTCAudioProcessingState(
                voiceProcessingEnabled: true,
                voiceProcessingBypassed: false,
                voiceProcessingAGCEnabled: true,
                stereoPlayoutEnabled: true
            )
        )

        await fulfillment(of: [expectation])

        cancellable.cancel()
    }

    func test_routeChanges_refreshStereoState() async throws {
        let subject = RTCAudioStore.StereoPlayoutEffect()

        let mockAudioDeviceModule = MockRTCAudioDeviceModule()
        let audioDeviceModule = AudioDeviceModule(mockAudioDeviceModule)
        let stateSubject = CurrentValueSubject<RTCAudioStore.Namespace.State, Never>(.dummy(audioDeviceModule: audioDeviceModule))

        subject.set(statePublisher: stateSubject.eraseToAnyPublisher())
        audioDeviceModule.audioDeviceModule(
            .init(),
            didUpdateAudioProcessingState: RTCAudioProcessingState(
                voiceProcessingEnabled: true,
                voiceProcessingBypassed: false,
                voiceProcessingAGCEnabled: true,
                stereoPlayoutEnabled: true
            )
        )
        stateSubject.send(.dummy(audioDeviceModule: audioDeviceModule, currentRoute: .dummy(inputs: [.dummy()])))

        await fulfillment { mockAudioDeviceModule.timesCalled(.refreshStereoPlayoutState) == 1 }
    }
}
