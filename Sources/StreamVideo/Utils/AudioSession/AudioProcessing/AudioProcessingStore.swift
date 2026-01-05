//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Coordinates audio processing for capture/render using a small Store.
///
/// This wrapper exposes a lightweight `AudioProcessingModule` API on top of
/// `RTCDefaultAudioProcessingModule` and forwards user intent via actions
/// (e.g., selecting an `AudioFilter`). It is registered for dependency
/// injection so call sites can swap implementations in tests.

/// Public façade for the audio processing pipeline used by the SDK.
public protocol AudioProcessingModule: RTCAudioProcessingModule, Sendable {

    /// The currently active audio filter.
    var activeAudioFilter: AudioFilter? { get }

    /// Sets the audio filter to be used for audio processing.
    /// - Parameter filter: The audio filter to set.
    func setAudioFilter(_ filter: AudioFilter?)
}

/// Default implementation of `AudioProcessingModule` backed by a Redux‑style
/// store that manages configuration, filter selection, and event flow.
final class AudioProcessingStore: RTCDefaultAudioProcessingModule, AudioProcessingModule, @unchecked Sendable {

    private let store: Store<Namespace>

    /// Initializes the store and wires delegates to WebRTC processing hooks.
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

    /// The filter currently applied to capture frames.
    var activeAudioFilter: AudioFilter? { store.state.audioFilter }

    /// Updates the active `AudioFilter`. Passing `nil` clears any effect.
    func setAudioFilter(_ filter: AudioFilter?) {
        store.dispatch(.setAudioFilter(filter))
    }
}

extension AudioProcessingStore: InjectionKey {

    nonisolated(unsafe) static var currentValue: AudioProcessingModule = AudioProcessingStore()
}

extension InjectedValues {
    /// Dependency entry point for the audio processing module used by calls.
    var audioFilterProcessingModule: AudioProcessingModule {
        get { Self[AudioProcessingStore.self] }
        set { Self[AudioProcessingStore.self] = newValue }
    }
}
