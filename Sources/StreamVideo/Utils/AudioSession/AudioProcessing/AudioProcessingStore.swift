//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

public protocol AudioProcessingModule: RTCAudioProcessingModule, Sendable {

    /// The currently active audio filter.
    var activeAudioFilter: AudioFilter? { get }

    /// Sets the audio filter to be used for audio processing.
    /// - Parameter filter: The audio filter to set.
    func setAudioFilter(_ filter: AudioFilter?)
}

final class AudioProcessingStore: RTCDefaultAudioProcessingModule, AudioProcessingModule, @unchecked Sendable {

    private let store: Store<Namespace>

    init() {
        let initialState = Namespace.State.initial
        store = Namespace.store(initialState: initialState)

        super.init(
            config: nil,
            capturePostProcessingDelegate: initialState.capturePostProcessingDelegate,
            renderPreProcessingDelegate: nil
        )

        store.dispatch(.load)
    }

    var activeAudioFilter: AudioFilter? { store.state.audioFilter }

    func setAudioFilter(_ filter: AudioFilter?) {
        store.dispatch(.setAudioFilter(filter))
    }
}

extension AudioProcessingStore: InjectionKey {

    nonisolated(unsafe) static var currentValue: AudioProcessingModule = AudioProcessingStore()
}

extension InjectedValues {
    var audioFilterProcessingModule: AudioProcessingModule {
        get { Self[AudioProcessingStore.self] }
        set { Self[AudioProcessingStore.self] = newValue }
    }
}
