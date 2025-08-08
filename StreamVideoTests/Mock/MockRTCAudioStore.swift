//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockRTCAudioStore {

    let audioStore: RTCAudioStore
    let session: MockAudioSession

    init() {
        let session = MockAudioSession()
        self.session = session
        audioStore = RTCAudioStore(session: session)
    }

    /// We call this just before the object that needs to use the mock is about to be created.
    func makeShared() {
        RTCAudioStore.currentValue = audioStore
        InjectedValues[\.audioStore] = audioStore
    }
}
