//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// Redux-style store that keeps WebRTC, CallKit, and app audio state aligned
/// while exposing Combine publishers to observers.
final class RTCAudioStore: @unchecked Sendable {

    private let store: Store<Namespace>

    /// Shared instance used by the dependency injection container.
    static let shared = RTCAudioStore()

    var state: Namespace.State { store.state }
    private let audioSession: RTCAudioSession

    /// Creates a store backed by the provided WebRTC audio session instance.
    /// - Parameter audioSession: The underlying WebRTC audio session.
    init(
        audioSession: RTCAudioSession = .sharedInstance()
    ) {
        self.audioSession = audioSession
        self.store = Namespace.store(
            initialState: .init(
                isActive: false,
                isInterrupted: false,
                isRecording: false,
                isMicrophoneMuted: true,
                hasRecordingPermission: false,
                audioDeviceModule: nil,
                currentRoute: .init(audioSession.currentRoute),
                audioSessionConfiguration: .init(
                    category: .soloAmbient,
                    mode: .default,
                    options: [],
                    overrideOutputAudioPort: .none
                ),
                webRTCAudioSessionConfiguration: .init(
                    isAudioEnabled: false,
                    useManualAudio: false,
                    prefersNoInterruptionsFromSystemAlerts: false
                ),
                stereoConfiguration: .init(
                    playout: .init(
                        preferred: false,
                        enabled: false
                    )
                )
            ),
            reducers: Namespace.reducers(audioSession: audioSession),
            middleware: Namespace.middleware(audioSession: audioSession),
            effects: Namespace.effects(audioSession: audioSession)
        )

        store.dispatch([
            .normal(.webRTCAudioSession(.setPrefersNoInterruptionsFromSystemAlerts(true))),
            .normal(.webRTCAudioSession(.setUseManualAudio(true))),
            .normal(.webRTCAudioSession(.setAudioEnabled(false)))
        ])
    }

    // MARK: - Observation

    func add(_ middleware: Middleware<Namespace>) {
        store.add(middleware)
    }

    /// Emits values when the provided key path changes within the store state.
    /// - Parameter keyPath: The state value to observe.
    /// - Returns: A publisher of distinct values for the key path.
    func publisher<V: Equatable>(
        _ keyPath: KeyPath<Namespace.State, V>
    ) -> AnyPublisher<V, Never> {
        store.publisher(keyPath)
    }

    // MARK: - Dispatch

    @discardableResult
    /// Dispatches boxed actions, preserving call site metadata for tracing.
    func dispatch(
        _ actions: [StoreActionBox<Namespace.Action>],
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> StoreTask<Namespace> {
        store.dispatch(
            actions,
            file: file,
            function: function,
            line: line
        )
    }

    @discardableResult
    /// Dispatches a sequence of namespace actions to the underlying store.
    func dispatch(
        _ actions: [Namespace.Action],
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> StoreTask<Namespace> {
        store.dispatch(
            actions,
            file: file,
            function: function,
            line: line
        )
    }

    @discardableResult
    /// Dispatches a single action by boxing it before forwarding to the
    /// underlying store implementation.
    func dispatch(
        _ action: Namespace.Action,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> StoreTask<Namespace> {
        store.dispatch(
            [action],
            file: file,
            function: function,
            line: line
        )
    }
}

extension RTCAudioStore: InjectionKey {
    nonisolated(unsafe) static var currentValue: RTCAudioStore = .shared
}

extension InjectedValues {
    var audioStore: RTCAudioStore {
        get { Self[RTCAudioStore.self] }
        set { Self[RTCAudioStore.self] = newValue }
    }
}
