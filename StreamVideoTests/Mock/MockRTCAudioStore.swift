//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC

final class MockRTCAudioStore: @unchecked Sendable {

    let audioSession: RTCAudioSession
    let audioStore: RTCAudioStore

    private var previousStore: RTCAudioStore?
    private var previousCurrentValue: RTCAudioStore?

    init(audioSession: RTCAudioSession = .sharedInstance()) {
        self.audioSession = audioSession
        self.audioStore = RTCAudioStore(audioSession: audioSession)
    }

    func makeShared() {
        previousStore = InjectedValues[\.audioStore]
        previousCurrentValue = RTCAudioStore.currentValue

        InjectedValues[\.audioStore] = audioStore
        RTCAudioStore.currentValue = audioStore
    }

    func dismantle() async throws {
        defer {
            if let previousStore {
                InjectedValues[\.audioStore] = previousStore
            }

            if let previousCurrentValue {
                RTCAudioStore.currentValue = previousCurrentValue
            }
        }

        let storeResult: Result<Void, Error>
        do {
            try await audioStore.dispatch([
                .setAudioDeviceModule(nil),
                .webRTCAudioSession(.setAudioEnabled(false)),
                .setActive(false)
            ]).result()
            storeResult = .success(())
        } catch {
            storeResult = .failure(error)
        }

        audioSession.lockForConfiguration()
        defer { audioSession.unlockForConfiguration() }
        audioSession.isAudioEnabled = false
        // The cached activity flag can miss native and CallKit activations.
        for _ in 0..<max(0, audioSession.activationCount) {
            try audioSession.setActive(false)
        }
        try storeResult.get()
    }
}
