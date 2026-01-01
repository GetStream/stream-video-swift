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

    func dismantle() {
        if let previousStore {
            InjectedValues[\.audioStore] = previousStore
        }

        if let previousCurrentValue {
            RTCAudioStore.currentValue = previousCurrentValue
        }
    }
}
